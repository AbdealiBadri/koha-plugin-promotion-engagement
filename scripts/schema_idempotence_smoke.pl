use strict;
use warnings;
use C4::Context;
use Koha::Plugin::Com::AJSN::PromotionEngagement;
my $plugin = Koha::Plugin::Com::AJSN::PromotionEngagement->new({ enable_plugins => 1 });
my $dbh = C4::Context->dbh;
my @tables = qw(
  plugin_ajsn_promo_campaigns
  plugin_ajsn_promo_items
  plugin_ajsn_promo_audit
  plugin_ajsn_promo_settings
  plugin_ajsn_promo_vocab_values
  plugin_ajsn_promo_campaign_locations
  plugin_ajsn_promo_recommendations
);
sub counts {
    return join ',', map {
        my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $_");
        "$_=$count";
    } @tables;
}
my $before = counts();
$plugin->_ensure_schema;
$plugin->_ensure_schema;
my $after = counts();
die "row counts changed\nBEFORE $before\nAFTER $after\n" if $before ne $after;
print "schema-idempotence PASS\n$after\n";
