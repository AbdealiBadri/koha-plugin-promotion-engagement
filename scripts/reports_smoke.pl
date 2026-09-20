#!/usr/bin/env perl
use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/..";

use C4::Context;
use Mojo::JSON qw(encode_json);
use Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics;

my $dbh = C4::Context->dbh;
my $campaign_ids = $dbh->selectcol_arrayref(
    q{SELECT campaign_id FROM plugin_ajsn_promo_campaigns
       WHERE deleted_at IS NULL AND start_date IS NOT NULL
       ORDER BY campaign_id}
) || [];

my $service =
  Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
    { dbh => $dbh }
  );
my $result = {
    portfolio => @{$campaign_ids}
      ? $service->portfolio_metrics($campaign_ids) : undef,
    channel => @{$campaign_ids}
      ? $service->comparison_metrics( 'channel', $campaign_ids ) : undef,
    location => @{$campaign_ids}
      ? $service->comparison_metrics( 'location', $campaign_ids ) : undef,
};
say encode_json($result);
