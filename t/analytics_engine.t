use Modern::Perl;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/..";

use C4::Context;
use Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics;

my $dbh = C4::Context->dbh;
$dbh->{RaiseError} = 1;
$dbh->begin_work;

my @fixtures = (
    [ 990001, '2026-09-07 00:00:00', 0 ],
    [ 990002, '2026-09-18 23:59:59', 0 ],
    [ 990003, '2026-09-19 00:00:00', 3 ],
    [ 990004, '2026-09-30 23:59:59', 0 ],
    [ 990005, '2026-10-01 00:00:00', 0 ],
    [ 990006, '2026-10-08 00:00:00', 0 ],
);

for my $fixture (@fixtures) {
    my ( $issue_id, $issuedate, $renewals_count ) = @{$fixture};
    $dbh->do(
        q{
            INSERT INTO old_issues
                (issue_id, borrowernumber, itemnumber, issuedate, renewals_count)
            VALUES (?, 51, 1, ?, ?)
        },
        undef,
        $issue_id,
        $issuedate,
        $renewals_count,
    );
}
# Duplicate one issue across current and historical tables to prove issue-id de-duplication.
$dbh->do(
    q{
        INSERT INTO issues
            (issue_id, borrowernumber, itemnumber, issuedate, renewals_count)
        VALUES (990003, 51, 1, '2026-09-19 00:00:00', 3)
    }
);

my $service = Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
    { dbh => $dbh }
);
my $result = $service->campaign_metrics(40);

is( $result->{spec_version}, '1.0.0', 'AN-00 spec version returned' );
is( $result->{eligible_item_count}, 1, 'AN-06 fixed eligible cohort resolved' );
is( $result->{windows}->{baseline}->{days}, 12, 'AN-03 baseline matches During duration' );
is( $result->{windows}->{during}->{days}, 12, 'AN-02 inclusive campaign dates resolve to 12 days' );
is( $result->{windows}->{after_7}->{days}, 7, 'AN-04 7-day After window resolved' );
is( $result->{windows}->{after_60}->{days}, 60, 'AN-04 60-day After window resolved' );

is( $result->{metrics}->{baseline}->{checkout_count}, 2, 'AN-02 baseline boundaries counted once' );
is( $result->{metrics}->{during}->{checkout_count}, 2, 'AN-01 duplicate issue ID removed across issue tables' );
is( $result->{metrics}->{after_7}->{checkout_count}, 1, 'AN-02 After-7 end boundary excluded' );
is( $result->{metrics}->{after_14}->{checkout_count}, 2, 'AN-04 later After window includes boundary event' );
is( $result->{metrics}->{during}->{unique_items_checked_out}, 1, 'AN-07 conversion uses distinct items' );
is( $result->{metrics}->{during}->{conversion_rate}, 100, 'AN-07 distinct-item conversion calculated' );
is( $result->{metrics}->{during}->{checkout_count}, 2, 'AN-05 renewals do not create extra checkout events' );
is( $result->{absolute_rate_delta}, 0, 'AN-08 equal rates produce zero absolute delta' );
is( $result->{uplift_percent}, 0, 'AN-08 non-zero equal baseline produces zero uplift' );
is( $result->{days_to_first_checkout}, 0, 'AN-10 first checkout at campaign start is day zero' );

$dbh->do(
    q{DELETE FROM old_issues WHERE issue_id IN (990001, 990002)}
);
my $zero_baseline = $service->campaign_metrics(40);
is( $zero_baseline->{metrics}->{baseline}->{checkout_count}, 0, 'AN-08 zero baseline fixture established' );
ok( !defined $zero_baseline->{uplift_percent}, 'AN-08 zero baseline returns null uplift' );
cmp_ok( $zero_baseline->{absolute_rate_delta}, '>', 0, 'AN-08 zero baseline retains absolute delta' );

$dbh->do(
    q{
        INSERT INTO plugin_ajsn_promo_campaigns
            (campaign_id, campaign_uuid, campaign_type, name, start_date, end_date, status)
        VALUES
            (990040, '00000000-0000-0000-0000-000000990040',
             'recommendation', 'AN-ZERO-ITEMS', '2026-09-19', '2026-09-19', 'active')
    }
);
my $zero_items = $service->campaign_metrics(990040);
is( $zero_items->{eligible_item_count}, 0, 'AN-09 zero eligible-item campaign supported' );
ok( !defined $zero_items->{metrics}->{during}->{conversion_rate}, 'AN-09 zero eligible items returns null conversion' );
ok( !defined $zero_items->{days_to_first_checkout}, 'AN-10 no checkout returns null days-to-first' );

$dbh->rollback;
pass('Synthetic circulation fixtures rolled back');

done_testing;

