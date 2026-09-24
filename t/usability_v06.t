use Modern::Perl;
use Test::More;
use CGI;
use FindBin;
use lib "$FindBin::Bin/..";

use Koha::Plugin::Com::AJSN::PromotionEngagement;

sub slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "Cannot read $path: $!";
    local $/;
    return <$fh>;
}

my $plugin_pm = slurp("$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement.pm");
like( $plugin_pm, qr/our \$VERSION = '0\.6\.1'/, 'V06-01 plugin version is 0.6.1' );

my $cgi = CGI->new(
    'campaign_ids=40&campaign_ids=39&campaign_ids=40&status=active&date_from=2026-01-01&date_to=2026-12-31'
);
my $filters = Koha::Plugin::Com::AJSN::PromotionEngagement::_report_filters($cgi);
is_deeply( $filters->{campaign_ids}, [ 40, 39 ],
    'V06-02 multi-campaign report selection is de-duplicated and preserved' );
is( $filters->{campaign_id}, q{},
    'V06-03 legacy singular campaign_id is blank for multi-selection' );
is( $filters->{status}, 'active', 'V06-04 report status filter preserved' );

my $campaigns = [
    { campaign_id => 40, status => 'active', start_date => '2026-09-01', end_date => '2026-09-30' },
    { campaign_id => 39, status => 'active', start_date => '2026-08-01', end_date => '2026-08-31' },
    { campaign_id => 38, status => 'active', start_date => '2026-07-01', end_date => '2026-07-31' },
];
is_deeply(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_filtered_campaign_ids(
        $campaigns,
        {
            campaign_ids => [ 40, 39 ],
            status => 'active',
            date_from => q{},
            date_to => q{},
        }
    ),
    [ 40, 39 ],
    'V06-05 selected campaign list constrains report scope'
);

is(
    Koha::Plugin::Com::AJSN::PromotionEngagement::_report_filter_query(
        {
            campaign_ids => [ 40, 39 ],
            status => 'active',
            date_from => q{},
            date_to => q{},
        }
    ),
    'campaign_ids=40&campaign_ids=39&status=active',
    'V06-06 export/filter query preserves repeated campaign IDs'
);

my %files = (
    dashboard => slurp("$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement/dashboard.tt"),
    promotions => slurp("$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement/promotions.tt"),
    analytics => slurp("$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement/analytics.tt"),
    impact => slurp("$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement/book_display_impact.tt"),
    reports => slurp("$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement/reports.tt"),
    config => slurp("$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement/configure.tt"),
    help => slurp("$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement/how_to_use.tt"),
    js => slurp("$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement/promoeng_ui_js.inc"),
    css => slurp("$FindBin::Bin/../Koha/Plugin/Com/AJSN/PromotionEngagement/promoeng_ui_css.inc"),
);

like( $files{dashboard}, qr/These are the books\/resources we promoted, and this is how and when we promoted them\./,
    'V06-07 dashboard Step 1 uses approved simple explanation' );
like( $files{dashboard}, qr/How were these books\/resources performing before we promoted them\?/,
    'V06-08 dashboard Step 2 uses approved simple explanation' );
like( $files{dashboard}, qr/After we promoted them, did students\/users actually start borrowing them more\?/,
    'V06-09 dashboard Step 3 uses approved simple explanation' );
like( $files{dashboard}, qr/Did the promotion work, by how much, and what can the librarian learn from it\?/,
    'V06-10 dashboard Step 4 uses approved simple explanation' );

for my $page (qw(dashboard promotions analytics impact reports config)) {
    like( $files{$page}, qr/how_to_use\.tt/,
        "V06 how-to control is included on $page" );
}

like( $files{promotions}, qr/name="campaign_ids" multiple.*promo-searchable-select/s,
    'V06-17 Promotions campaign selector is searchable multi-select' );
like( $files{reports}, qr/name="campaign_ids" multiple.*promo-searchable-select/s,
    'V06-18 Reports campaign selector is searchable multi-select' );

like( $files{js}, qr/\.select2\(/, 'V06-19 shared searchable dropdown component uses Select2' );
like( $files{js}, qr/localeCompare\([^;]+numeric:true/s,
    'V06-20 searchable dropdown natural sorting is enabled' );
like( $files{js}, qr/\.kohaTable\(/, 'V06-21 shared table component uses Koha DataTables' );

for my $page (qw(dashboard promotions analytics impact reports config)) {
    like( $files{$page}, qr/promo-data-table/,
        "V06 DataTable behavior is present on $page" );
}

like( $files{impact}, qr/Green:.*highest campaign-period issue count/s,
    'V06-28 Resource Impact explains green highest-issue cue' );
like( $files{impact}, qr/Red:.*zero issue/s,
    'V06-29 Resource Impact explains red zero-response cue' );
like( $files{impact}, qr/data-promo-table-filter="#resource-impact-table"/,
    'V06-30 Resource Impact KPI cards drill into the title table' );
like( $files{analytics}, qr/data-promo-table-filter="#analytics-title-response-table"/,
    'V06-31 Analytics KPI signals drill into the title table' );

like( $files{analytics}, qr/Chart View.*Table View/s,
    'V06-32 Analytics exposes chart and table views' );
like( $files{reports}, qr/Chart View.*Table View/s,
    'V06-33 Reports exposes chart and table views' );
like( $files{js}, qr/labels:\s*true/,
    'V06-34 charts display data labels' );
like( $files{js}, qr/toDataURL\("image\/jpeg"/,
    'V06-35 charts provide JPEG download' );

like( $files{help}, qr/How to Use the Dashboard/,
    'V06-36 Dashboard help exists' );
like( $files{help}, qr/How to Use New Promotion/,
    'V06-37 New Promotion help exists' );
like( $files{help}, qr/How to Use Promotions/,
    'V06-38 Promotions help exists' );
like( $files{help}, qr/How to Use Campaign Analytics/,
    'V06-39 Analytics help exists' );
like( $files{help}, qr/How to Use Resource Impact/,
    'V06-40 Resource Impact help exists' );
like( $files{help}, qr/How to Use Comparative Reports/,
    'V06-41 Reports help exists' );
like( $files{help}, qr/How to Use Configuration/,
    'V06-42 Configuration help exists' );

for my $dimension (qw(Campaign types Channels Locations Languages Audiences Cadence)) {
    like( $files{help}, qr/\Q$dimension\E/i,
        "V06 configuration help explains $dimension" );
}

unlike(
    join( "\n", @files{qw(dashboard promotions analytics impact reports config)} ),
    qr/Titles used|Increased-use Titles/i,
    'V06-49 deprecated user-facing KPI terminology is absent from main v0.6 screens'
);

done_testing;
