use Modern::Perl;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/..";

use C4::Context;
use Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics;
use Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact;

my $dbh = C4::Context->dbh;
$dbh->{RaiseError} = 1;
$dbh->begin_work;

my ($biblionumber) = $dbh->selectrow_array(q{
    SELECT biblionumber
      FROM items
     WHERE barcode IS NOT NULL AND barcode <> ''
     GROUP BY biblionumber
    HAVING COUNT(*) >= 2
     ORDER BY biblionumber
     LIMIT 1
});
ok( $biblionumber, 'V05-01 fixture finds a title with at least two copies' );

my $items = $dbh->selectall_arrayref(
    q{SELECT itemnumber, barcode FROM items
       WHERE biblionumber=? AND barcode IS NOT NULL AND barcode <> ''
       ORDER BY itemnumber LIMIT 2},
    { Slice => {} },
    $biblionumber,
);
is( scalar @{$items}, 2, 'V05-02 two copy/item records selected' );

$dbh->do(q{
    INSERT INTO plugin_ajsn_promo_campaigns
        (campaign_id, campaign_uuid, campaign_type, channel, name,
         start_date, end_date, status)
    VALUES
        (990050, '00000000-0000-0000-0000-000000990050',
         'recommendation', 'physical_display', 'V05-ACTIVE-OPEN',
         '2026-09-01', NULL, 'active'),
        (990051, '00000000-0000-0000-0000-000000990051',
         'recommendation', 'physical_display', 'V05-ACTIVE-FUTURE-END',
         '2026-09-01', '2026-09-30', 'active'),
        (990052, '00000000-0000-0000-0000-000000990052',
         'recommendation', 'physical_display', 'V05-SCHEDULED',
         '2026-09-20', '2026-09-30', 'active')
});

for my $item ( @{$items} ) {
    $dbh->do(
        q{INSERT INTO plugin_ajsn_promo_items
          (campaign_id,itemnumber,barcode,added_at)
          VALUES (990050,?,?, '2026-08-31 10:00:00')},
        undef,
        $item->{itemnumber},
        $item->{barcode},
    );
}
for my $campaign_id ( 990051, 990052 ) {
    $dbh->do(
        q{INSERT INTO plugin_ajsn_promo_items
          (campaign_id,itemnumber,barcode,added_at)
          VALUES (?,?,?, '2026-08-31 10:00:00')},
        undef,
        $campaign_id,
        $items->[0]->{itemnumber},
        $items->[0]->{barcode},
    );
}

$dbh->do(
    q{INSERT INTO old_issues
      (issue_id,borrowernumber,itemnumber,issuedate,renewals_count)
      VALUES (995050,51,?,'2026-09-05 10:00:00',0)},
    undef,
    $items->[0]->{itemnumber},
);

my $service =
  Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
    { dbh => $dbh }
  );

my $active = $service->campaign_metrics(
    990050, { as_of_date => '2026-09-10' }
);
is(
    $active->{analysis_period}->{effective_end_date},
    '2026-09-10',
    'V05-03 active campaign without end date measures through as-of date'
);
ok(
    $active->{analysis_period}->{live_to_date},
    'V05-04 active open-ended campaign is explicitly live-to-date'
);
is( $active->{windows}->{during}->{days}, 10,
    'V05-05 active campaign period grows through as-of date' );
is( $active->{windows}->{baseline}->{days}, 10,
    'V05-06 baseline remains exactly comparable to active campaign duration' );
is( $active->{windows}->{after_7}->{state}, 'pending',
    'V05-07 future follow-up window is pending' );
ok( !defined $active->{metrics}->{after_7}->{checkout_count},
    'V05-08 pending follow-up is not misreported as zero checkouts' );

is( $active->{eligible_item_count}, 2,
    'V05-09 promoted copies/items remain item-level' );
is( $active->{promoted_title_count}, 1,
    'V05-10 promoted titles are de-duplicated by biblionumber' );
is( $active->{titles_used_count}, 1,
    'V05-11 title usage is counted at distinct-title level' );
is( $active->{title_utilization_rate}, 100,
    'V05-12 title utilization uses titles, not copy/item count' );
is( $active->{zero_response_title_count}, 0,
    'V05-13 used promoted title is not a zero-response title' );
cmp_ok( $active->{metrics}->{during}->{checkout_count}, '>=', 1,
    'V05-14 active campaign captures current-to-date checkout evidence' );

my $future_end = $service->campaign_metrics(
    990051, { as_of_date => '2026-09-10' }
);
is(
    $future_end->{analysis_period}->{effective_end_date},
    '2026-09-10',
    'V05-15 future planned end is clamped to current as-of date while active'
);
ok( $future_end->{analysis_period}->{live_to_date},
    'V05-16 active future-ended campaign remains provisional/live-to-date' );

my $scheduled = $service->campaign_metrics(
    990052, { as_of_date => '2026-09-10' }
);
is( $scheduled->{windows}->{during}->{state}, 'pending',
    'V05-17 campaign that has not started is marked pending' );
ok( !defined $scheduled->{titles_used_count},
    'V05-18 scheduled campaign does not falsely report zero used titles' );
ok( !defined $scheduled->{zero_response_title_count},
    'V05-19 scheduled campaign does not falsely create zero-response titles' );
is( $scheduled->{impact_evidence}->{code}, 'scheduled',
    'V05-20 scheduled campaign is not classified as failed impact' );

my $portfolio = $service->portfolio_metrics(
    [990050], { as_of_date => '2026-09-10' }
);
is( $portfolio->{promoted_item_count}, 2,
    'V05-21 portfolio distinguishes promoted item records' );
is( $portfolio->{promoted_title_count}, 1,
    'V05-22 portfolio de-duplicates promoted titles' );
is( $portfolio->{titles_used_count}, 1,
    'V05-23 portfolio exposes used promoted titles' );
is( $portfolio->{title_utilization_rate}, 100,
    'V05-24 portfolio exposes title utilization' );
cmp_ok( $portfolio->{portfolio_campaign_checkout_count}, '>=', 1,
    'V05-25 portfolio exposes de-duplicated campaign-period checkouts' );

my $impact_service =
  Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact->new(
    { dbh => $dbh }
  );
my $impact = $impact_service->campaign_rows(
    990050, { as_of_date => '2026-09-10' }
);
is( $impact->{summary}->{title_count}, 1,
    'V05-26 Resource Impact reports distinct promoted titles' );
is( $impact->{summary}->{titles_used_count}, 1,
    'V05-27 Resource Impact surfaces title usage' );
is( $impact->{summary}->{title_utilization_rate}, 100,
    'V05-28 Resource Impact surfaces title utilization' );
ok( !$impact->{rows}->[0]->{followup_complete},
    'V05-29 incomplete 60-day follow-up is not treated as sustained evidence' );

$dbh->rollback;
pass('V05-30 analytics intelligence fixtures rolled back');

done_testing;
