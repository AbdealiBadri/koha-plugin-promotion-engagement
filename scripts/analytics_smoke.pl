#!/usr/bin/env perl
use Modern::Perl;
use FindBin;
use lib "$FindBin::Bin/..";
use C4::Context;
use Mojo::JSON qw(encode_json);
use Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics;

my $campaign_id = shift @ARGV;
die "Usage: $0 CAMPAIGN_ID\n"
  unless defined $campaign_id && $campaign_id =~ /^\d+$/;

my $service = Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
    { dbh => C4::Context->dbh }
);
say encode_json( $service->campaign_metrics($campaign_id) );
