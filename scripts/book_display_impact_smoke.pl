use Modern::Perl;
use lib '/kohadevbox/plugins/koha-plugin-promotion-engagement';
use C4::Context;
use Koha::Plugin::Com::AJSN::PromotionEngagement;
use Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact;

my $plugin = Koha::Plugin::Com::AJSN::PromotionEngagement->new(
    { enable_plugins => 1 }
);
$plugin->_ensure_schema;
my $dbh = C4::Context->dbh;
my ($table_count) = $dbh->selectrow_array(
    q{SELECT COUNT(*) FROM information_schema.tables
      WHERE table_schema=DATABASE()
        AND table_name='plugin_ajsn_promo_recommendations'}
);
die "recommendations table missing\n" unless $table_count == 1;
my $result =
  Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact->new(
    { dbh => $dbh }
  )->campaign_rows(40);
die "campaign 40 missing impact rows\n" unless @{ $result->{rows} };
print "book-display-impact-ok titles=$result->{summary}->{title_count}\n";
