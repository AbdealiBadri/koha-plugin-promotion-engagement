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

done_testing;
