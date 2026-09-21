use Modern::Perl;
use Test::More;

use lib '.';
use Koha::Plugin::Com::AJSN::PromotionEngagement;

my $resolver = \&Koha::Plugin::Com::AJSN::PromotionEngagement::_analytics_campaign_id;
my $campaigns = [
    { campaign_id => 40 },
    { campaign_id => 39 },
];

is( $resolver->( 39, $campaigns ), 39, 'explicit campaign selection is preserved' );
is( $resolver->( q{}, $campaigns ), 40, 'blank selection defaults to newest campaign' );
is( $resolver->( undef, $campaigns ), 40, 'missing selection defaults to newest campaign' );
is( $resolver->( q{}, [] ), q{}, 'no campaigns leaves selection blank' );
is( $resolver->( q{}, undef ), q{}, 'missing campaign list leaves selection blank' );

my $filter = \&Koha::Plugin::Com::AJSN::PromotionEngagement::_filtered_campaign_ids;
my $report_campaigns = [
    { campaign_id => 40, status => 'active', start_date => '2026-09-19', end_date => '2026-09-30' },
    { campaign_id => 39, status => 'completed', start_date => '2026-08-01', end_date => '2026-08-10' },
];
is_deeply(
    $filter->( $report_campaigns, { campaign_id => q{}, status => q{}, date_from => q{}, date_to => q{} } ),
    [ 40, 39 ],
    'report filters default to all campaigns'
);
is_deeply(
    $filter->( $report_campaigns, { campaign_id => 40, status => 'active', date_from => '2026-09-01', date_to => '2026-09-30' } ),
    [40],
    'report filters combine campaign, status and overlapping dates'
);
is_deeply(
    $filter->( $report_campaigns, { campaign_id => q{}, status => 'draft', date_from => q{}, date_to => q{} } ),
    [],
    'report filters return an honest empty result'
);

my $leading = Koha::Plugin::Com::AJSN::PromotionEngagement::_leading_location(
    [
        { label => 'Main Entrance', exclusive_campaign_count => 2, exclusive_checkout_count => 5 },
        { label => 'First Floor', exclusive_campaign_count => 1, exclusive_checkout_count => 8 },
        { label => 'Digital Screen', exclusive_campaign_count => 0, exclusive_checkout_count => 20 },
    ]
);
is( $leading->{label}, 'First Floor', 'leading location uses unambiguous single-location evidence' );

my $unassigned_only = Koha::Plugin::Com::AJSN::PromotionEngagement::_leading_location(
    [
        { code => 'unassigned', label => 'Unassigned', exclusive_campaign_count => 3, exclusive_checkout_count => 12 },
    ]
);
ok( !defined $unassigned_only, 'unassigned is never presented as a leading physical display location' );

done_testing;
