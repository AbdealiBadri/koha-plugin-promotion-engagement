use Modern::Perl;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/..";

use C4::Context;
use Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics;

my $dbh = C4::Context->dbh;
$dbh->{RaiseError} = 1;
$dbh->begin_work;

$dbh->do(q{
    INSERT INTO plugin_ajsn_promo_campaigns
        (campaign_id, campaign_uuid, campaign_type, channel, name,
         start_date, end_date, status)
    SELECT 990041, '00000000-0000-0000-0000-000000990041',
           campaign_type, channel, 'AN-OVERLAP',
           start_date, end_date, 'active'
      FROM plugin_ajsn_promo_campaigns
     WHERE campaign_id = 40
});
$dbh->do(q{
    INSERT INTO plugin_ajsn_promo_items
        (campaign_id, itemnumber, barcode, added_at)
    VALUES (990041, 1, '3999900000001', '2026-09-19 00:00:00')
});
$dbh->do(q{
    INSERT INTO old_issues
        (issue_id, borrowernumber, itemnumber, issuedate, renewals_count)
    VALUES (991100, 51, 1, '2026-09-20 10:00:00', 0)
});

my $service =
  Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
    { dbh => $dbh }
  );

my $portfolio = $service->portfolio_metrics( [ 40, 990041 ] );
is( $portfolio->{campaign_count}, 2, 'AN-11 two overlapping campaigns measured' );
is( $portfolio->{portfolio_checkout_count}, 1, 'AN-11 portfolio de-duplicates issue ID' );
is( $portfolio->{multi_attributed_issue_count}, 1, 'AN-11 multi-attribution exposed' );
is(
    $portfolio->{campaign_results}->[0]->{multi_attributed_issue_count},
    1,
    'AN-11 original campaign marks multi-attributed issue'
);

my $locations = $service->comparison_metrics( 'location', [40] );
my ($main_entrance) =
  grep { $_->{label} eq 'Main Entrance' } @{ $locations->{rows} };
ok( $main_entrance, 'AN-12 friendly configured location label returned' );
ok( $main_entrance->{code}, 'AN-12 stable location code returned' );
is(
    $main_entrance->{multi_location_campaign_count},
    1,
    'AN-12 multi-location contribution is explicit'
);
is(
    $main_entrance->{exclusive_campaign_count},
    0,
    'AN-12 multi-location campaign is excluded from best-location evidence'
);
is(
    $main_entrance->{exclusive_checkout_count},
    0,
    'AN-12 ambiguous checkouts are not presented as a physical pickup location'
);
my $mixed_locations = $service->comparison_metrics( 'location', [ 40, 990041 ] );
my ($unassigned) = grep { $_->{code} eq 'unassigned' } @{ $mixed_locations->{rows} };
is(
    $unassigned->{exclusive_campaign_count},
    1,
    'AN-12 single-location or unassigned campaign remains separately measurable'
);
cmp_ok(
    $unassigned->{exclusive_checkout_count},
    '>=',
    1,
    'AN-12 unambiguous campaign contributes to exclusive location evidence'
);

my $channels = $service->comparison_metrics( 'channel', [40] );
is( scalar @{ $channels->{rows} }, 1, 'AN-12 channel comparison grouped' );
ok( $channels->{rows}->[0]->{code}, 'AN-12 channel stable code returned' );
ok( $channels->{rows}->[0]->{label}, 'AN-12 channel friendly label returned' );

my $privacy =
  Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics::_apply_privacy_threshold(
    [
        { category_code => 'SMALL', unique_borrower_count => 4, checkout_count => 8 },
        { category_code => 'SAFE',  unique_borrower_count => 5, checkout_count => 9 },
    ],
    5,
  );
ok( $privacy->[0]->{suppressed}, 'AN-13 cohort below five is suppressed' );
ok( !defined $privacy->[0]->{checkout_count}, 'AN-13 suppressed count is not exposed as zero' );
ok( !$privacy->[1]->{suppressed}, 'AN-13 cohort of five is visible' );
is( $privacy->[1]->{checkout_count}, 9, 'AN-13 permitted aggregate count retained' );

$dbh->do(q{
    INSERT INTO plugin_ajsn_promo_campaigns
        (campaign_id, campaign_uuid, campaign_type, channel, name,
         start_date, end_date, status, deleted_at)
    SELECT 990042, '00000000-0000-0000-0000-000000990042',
           campaign_type, channel, 'AN-ARCHIVED',
           start_date, end_date, 'completed', NOW()
      FROM plugin_ajsn_promo_campaigns
     WHERE campaign_id = 40
});
my $archived_default = eval { $service->campaign_metrics(990042); 1 };
ok( !$archived_default, 'AN-14 archived campaign denied by default' );
like( $@, qr/historical authorization/, 'AN-14 denial explains authorization requirement' );
my $archived_authorized =
  $service->campaign_metrics( 990042, { include_archived => 1 } );
is( $archived_authorized->{campaign}->{campaign_id}, 990042, 'AN-14 authorized historical view works' );

my $ui_fixture  = $service->campaign_metrics(40);
my $api_fixture = $service->campaign_metrics(40);
is_deeply( $api_fixture->{metrics}, $ui_fixture->{metrics}, 'AN-15 UI/API shared service KPI parity' );
is( $api_fixture->{spec_version}, $ui_fixture->{spec_version}, 'AN-15 specification version parity' );

ok( $ui_fixture->{impact_evidence}->{label}, 'AN-16 display impact finding is exposed' );
ok( defined $ui_fixture->{impact_evidence}->{provisional}, 'AN-16 provisional state is explicit' );
my ($displayed_item) = grep { $_->{itemnumber} == 1 } @{ $ui_fixture->{item_response_rows} };
ok( $displayed_item, 'AN-16 displayed-title response includes linked item' );
is( $displayed_item->{barcode}, '3999900000001', 'AN-16 displayed-title response retains Koha barcode' );
cmp_ok( $displayed_item->{during_count}, '>=', 1, 'AN-16 during-display checkout is attributed to title' );
ok( $displayed_item->{response_label}, 'AN-16 title-level response classification is exposed' );

my $scheduled = Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics::_impact_evidence(
    { checkout_count => 0, daily_checkout_rate => 0 },
    { checkout_count => 0, daily_checkout_rate => 0 },
    1,
    { state => 'pending', start_epoch => time + 86_400, end_epoch => time + 172_800 },
);
is( $scheduled->{code}, 'scheduled', 'AN-16 future display is not presented as failed impact' );

$dbh->rollback;
pass('Advanced synthetic fixtures rolled back');

done_testing;
