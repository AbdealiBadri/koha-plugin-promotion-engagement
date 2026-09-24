use Modern::Perl;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/..";

use C4::Context;
use Koha::Plugin::Com::AJSN::PromotionEngagement;
use Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics;
use Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact;

{
    package CountingAnalytics;
    use parent 'Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics';

    sub _checkout_events {
        my ( $self, @args ) = @_;
        $self->{checkout_call_count}++;
        return $self->SUPER::_checkout_events(@args);
    }
}

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    return <$fh>;
}

my $dbh = C4::Context->dbh;
local $dbh->{RaiseError} = 1;
$dbh->begin_work;

my $items = $dbh->selectall_arrayref(
    q{
        SELECT MIN(i.itemnumber) AS itemnumber,
               MAX(i.barcode) AS barcode,
               i.biblionumber
          FROM items i
         WHERE i.barcode IS NOT NULL
           AND i.barcode <> ''
         GROUP BY i.biblionumber
         ORDER BY i.biblionumber
         LIMIT 2
    },
    { Slice => {} },
);
is( scalar @{$items}, 2, 'BF-01 fixture finds two distinct Koha titles' );

my ($borrowernumber) = $dbh->selectrow_array(
    q{SELECT borrowernumber FROM borrowers ORDER BY borrowernumber LIMIT 1}
);
ok( $borrowernumber, 'BF-02 fixture finds a Koha borrower for synthetic issue evidence' );

$dbh->do(
    q{
        INSERT INTO plugin_ajsn_promo_campaigns
            (campaign_id,campaign_uuid,campaign_type,channel,name,
             start_date,end_date,status)
        VALUES
            (990061,'00000000-0000-0000-0000-000000990061',
             'recommendation','email','V061-MEASURED',
             '2026-09-01',NULL,'active'),
            (990062,'00000000-0000-0000-0000-000000990062',
             'recommendation','email','V061-FUTURE',
             '2099-01-01','2099-01-07','active'),
            (990063,'00000000-0000-0000-0000-000000990063',
             'recommendation','email','V061-OVERLAP',
             '2026-09-01','2026-09-10','completed')
    }
);
$dbh->do(
    q{INSERT INTO plugin_ajsn_promo_items
      (campaign_id,itemnumber,barcode,added_at)
      VALUES (990061,?,?, '2026-08-31 09:00:00')},
    undef,
    $items->[0]->{itemnumber},
    $items->[0]->{barcode},
);
$dbh->do(
    q{INSERT INTO plugin_ajsn_promo_items
      (campaign_id,itemnumber,barcode,added_at)
      VALUES (990062,?,?, '2098-12-31 09:00:00')},
    undef,
    $items->[1]->{itemnumber},
    $items->[1]->{barcode},
);
$dbh->do(
    q{INSERT INTO plugin_ajsn_promo_items
      (campaign_id,itemnumber,barcode,added_at)
      VALUES (990063,?,?, '2026-08-31 09:00:00')},
    undef,
    $items->[0]->{itemnumber},
    $items->[0]->{barcode},
);
$dbh->do(
    q{INSERT INTO old_issues
      (issue_id,borrowernumber,itemnumber,issuedate,renewals_count)
      VALUES (995061,?,?, '2026-09-05 10:00:00',0)},
    undef,
    $borrowernumber,
    $items->[0]->{itemnumber},
);

my $service =
  Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
    { dbh => $dbh }
  );

my $measured = $service->campaign_metrics(
    990061, { as_of_date => '2026-09-10' }
);
ok(
    $measured->{analysis_period}->{live_to_date},
    'BF-03 measured fixture is live-to-date'
);
ok(
    $measured->{impact_evidence}->{provisional},
    'BF-04 live-to-date campaign impact is explicitly provisional'
);

my $mixed = $service->portfolio_metrics(
    [ 990061, 990062, 990063 ], { as_of_date => '2026-09-10' }
);
is( $mixed->{campaign_count}, 2,
    'BF-05 portfolio measured-campaign count excludes the future scheduled campaign' );
is( $mixed->{campaign_scope_count}, 3,
    'BF-05a portfolio separately retains all selected campaigns in scope metadata' );
is( $mixed->{promoted_title_count}, 1,
    'BF-06 future scheduled campaign is excluded from measured title denominator' );
is( $mixed->{titles_used_count}, 1,
    'BF-07 measured title usage is not diluted by future campaign' );
is( $mixed->{zero_response_title_count}, 0,
    'BF-08 future scheduled title is not falsely classified as zero response' );
is( $mixed->{title_utilization_rate}, 100,
    'BF-09 future campaign does not depress portfolio utilization' );

my $future_only = $service->portfolio_metrics(
    [990062], { as_of_date => '2026-09-10' }
);
is( $future_only->{promoted_title_count}, 0,
    'BF-10 future-only portfolio has no measured promoted-title denominator' );
is( $future_only->{titles_used_count}, 0,
    'BF-11 future-only portfolio has no measured issued titles' );
is( $future_only->{zero_response_title_count}, 0,
    'BF-12 future-only portfolio does not manufacture zero-response titles' );
ok( !defined $future_only->{title_utilization_rate},
    'BF-13 future-only portfolio utilization remains unavailable' );
is( $future_only->{campaign_count}, 0,
    'BF-13a future-only portfolio reports zero measured campaigns' );
is( $future_only->{campaign_scope_count}, 1,
    'BF-13b future-only portfolio retains one selected campaign in scope metadata' );
is(
    $mixed->{campaign_results}->[1]->{multi_attributed_issue_count},
    0,
    'BF-13c pending campaign remains safe when measured campaigns have overlapping multi-attributed issues'
);

my $future_comparison =
  $service->comparison_metrics( 'channel', [990062] );
is( scalar @{ $future_comparison->{rows} }, 0,
    'BF-14 scheduled campaign is excluded from comparative performance rows' );

my $counting = CountingAnalytics->new( { dbh => $dbh } );
$counting->comparison_metrics(
    'channel', [990061], { cache_events => 1, as_of_date => '2026-09-10' }
);
$counting->comparison_metrics(
    'campaign_type', [990061], { cache_events => 1, as_of_date => '2026-09-10' }
);
is( $counting->{checkout_call_count}, 1,
    'BF-15 repeated comparison dimensions reuse request-scoped campaign checkout evidence' );

$dbh->do(
    q{INSERT INTO plugin_ajsn_promo_vocab_values
      (dimension,value_code,label,sort_order,is_active)
      VALUES
      ('language','v061_lang','V061 Language',991,1),
      ('audience','v061_audience','V061 Audience',992,1)}
);

ok(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_optional_vocab_value_allowed(
        $dbh, 'language', 'v061_lang', undef
    ),
    'BF-16 configured active language code is accepted'
);
ok(
    !Koha::Plugin::Com::AJSN::PromotionEngagement::_optional_vocab_value_allowed(
        $dbh, 'language', 'forged_language', undef
    ),
    'BF-17 forged language value is rejected when configured vocabulary exists'
);
ok(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_optional_vocab_value_allowed(
        $dbh, 'audience', 'Historical Faculty Label', 'Historical Faculty Label'
    ),
    'BF-18 exact historical audience value remains valid during edit'
);

my $legacy_rows = [
    { value_code => 'faculty', label => 'Faculty', is_active => 1 },
];
is(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_preserve_legacy_vocab_selection(
        $legacy_rows, 'Faculty'
    ),
    'Faculty',
    'BF-19 stored historical label is preserved instead of silently rewritten to stable code'
);
ok( !$legacy_rows->[0]->{selected},
    'BF-20 label collision is not falsely treated as exact stable-code selection' );

my $code_rows = [
    { value_code => 'faculty', label => 'Faculty', is_active => 1 },
];
is(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_preserve_legacy_vocab_selection(
        $code_rows, 'faculty'
    ),
    q{},
    'BF-21 exact stable code does not require a legacy option'
);
ok( $code_rows->[0]->{selected},
    'BF-22 exact stable code remains selected' );

is(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_csv_value('normal value'),
    q{"normal value"},
    'BF-23 normal report CSV value remains unchanged'
);
is(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_csv_value('=2+2'),
    q{"'=2+2"},
    'BF-24 spreadsheet-formula report value is neutralized'
);
is(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_csv_value('@SUM(A1:A2)'),
    q{"'@SUM(A1:A2)"},
    'BF-25 at-sign spreadsheet formula is neutralized'
);

my $plugin_pm = slurp(
    "$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement.pm"
);
unlike( $plugin_pm, qr/PE_DEBUG/,
    'BF-26 accidental production debug logging is absent' );

my ($analytics_screen) =
  $plugin_pm =~ /(sub _analytics_screen \{.*?)(?=\nsub _book_display_impact_screen \{)/s;
my ($impact_screen) =
  $plugin_pm =~ /(sub _book_display_impact_screen \{.*?)(?=\nsub _save_impact_decision \{)/s;
ok( defined $analytics_screen && defined $impact_screen,
    'BF-27 selector screen source blocks located' );
unlike( $analytics_screen, qr/LIMIT\s+200/i,
    'BF-28 Analytics selector is not silently capped at 200 campaigns' );
unlike( $impact_screen, qr/LIMIT\s+200/i,
    'BF-29 Resource Impact selector is not silently capped at 200 campaigns' );

my ($decision_save) =
  $plugin_pm =~ /(sub _save_impact_decision \{.*?)(?=\nsub _submit_impact_suggestion \{)/s;
like( $decision_save, qr/begin_work.*FOR UPDATE.*impact_decision_recorded.*commit/s,
    'BF-30 recommendation decision and audit are atomic under a row lock' );

my ($suggestion_submit) =
  $plugin_pm =~ /(sub _submit_impact_suggestion \{.*?)(?=\nsub _reports_screen \{)/s;
like( $suggestion_submit, qr/begin_work.*FOR UPDATE.*koha_suggestion_id IS NULL.*commit/s,
    'BF-31 native Suggestion submission uses row locking and guarded single submission' );

my $ui_js = slurp(
    "$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement/promoeng_ui_js.inc"
);
like( $ui_js, qr/dt\.rows\(\)\.nodes\(\).*removeClass/s,
    'BF-32 KPI drill-down clears stale highlighting across all DataTable pages' );
like( $ui_js, qr/dt\.rows\(\{search:"applied"\}\)\.nodes\(\)/,
    'BF-33 KPI drill-down highlights all filtered rows, not only the current page' );
unlike( $ui_js, qr/search:"applied",\s*page:"current"/,
    'BF-34 current-page-only highlight bug is absent' );

ok(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_valid_iso_date('2024-02-29'),
    'BF-35 valid leap-day date is accepted'
);
ok(
    !Koha::Plugin::Com::AJSN::PromotionEngagement::_valid_iso_date('2026-02-29'),
    'BF-36 invalid non-leap-day date is rejected'
);
ok(
    !Koha::Plugin::Com::AJSN::PromotionEngagement::_valid_iso_date('2026-01-00'),
    'BF-37 zero day is rejected instead of being normalized'
);
is(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_campaign_filter_end_date(
        { start_date => '2026-03-01', end_date => undef, status => 'active' },
        '2026-09-24'
    ),
    '2026-09-24',
    'BF-38 active open-ended campaign overlaps report filters through today'
);
is(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_campaign_filter_end_date(
        { start_date => '2026-03-01', end_date => '2026-12-31', status => 'active' },
        '2026-09-24'
    ),
    '2026-09-24',
    'BF-39 active future-ended campaign report overlap is clamped to today'
);
is(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_campaign_filter_end_date(
        { start_date => '2026-03-01', end_date => '2026-04-01', status => 'completed' },
        '2026-09-24'
    ),
    '2026-04-01',
    'BF-40 completed campaign keeps configured report end date'
);
is(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_csv_value(' =2+2'),
    q{"' =2+2"},
    'BF-41 spreadsheet formula with leading whitespace is neutralized'
);

my $date_cgi = CGI->new(
    'date_from=2026-02-29&date_to=2026-01-00'
);
my $bad_date_filters =
  Koha::Plugin::Com::AJSN::PromotionEngagement::_report_filters($date_cgi);
is( $bad_date_filters->{date_from}, q{},
    'BF-42 invalid report start calendar date is discarded' );
is( $bad_date_filters->{date_to}, q{},
    'BF-43 invalid report end calendar date is discarded' );

my $ratio_row = {
    total_copies => 1,
    serviceable_copies => 1,
    available_copies => 1,
    active_holds => 4,
    hold_ratio_target => 3.5,
    baseline_count => 0,
    during_count => 1,
    after_60_count => 0,
};
Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact::_classify_row(
    $ratio_row, 0
);
is( $ratio_row->{priority}, 'High',
    'BF-44 decimal HoldRatioDefault uses mathematical ceiling for required copies' );
is( $ratio_row->{suggested_quantity}, 1,
    'BF-45 decimal hold-ratio target recommends the correct additional quantity' );

$dbh->rollback;
pass('BF-46 all synthetic bug-audit fixtures rolled back');

done_testing;
