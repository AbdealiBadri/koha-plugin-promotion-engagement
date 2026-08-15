package Koha::Plugin::Com::AJSN::PromotionEngagement::API::Health;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';

sub get {
    my ($c) = @_;
    return $c->render(
        status  => 200,
        openapi => {
            status  => 'ok',
            plugin  => 'Promotion & Engagement',
            version => '0.1.0',
        }
    );
}

1;
