package Koha::Plugin::Com::AJSN::PromotionEngagement::API::Analytics;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';

use C4::Context;
use Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics;

sub get {
    my ($c) = @_;
    my $campaign_id = $c->param('campaign_id');

    my $payload;
    my $ok = eval {
        my $service =
          Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
            { dbh => C4::Context->dbh }
          );
        $payload = $service->campaign_metrics($campaign_id);
        1;
    };

    unless ($ok) {
        my $error = $@ || 'Unknown analytics error';
        my $status = $error =~ /Campaign not found/ ? 404 : 400;
        return $c->render(
            status  => $status,
            openapi => { error => 'Campaign analytics are unavailable.' },
        );
    }

    return $c->render( status => 200, openapi => $payload );
}

1;
