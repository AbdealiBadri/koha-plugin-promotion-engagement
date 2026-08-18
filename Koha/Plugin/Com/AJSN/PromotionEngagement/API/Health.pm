package Koha::Plugin::Com::AJSN::PromotionEngagement::API::Health;

use Modern::Perl;
use Mojo::Base 'Mojolicious::Controller';

sub get {
    my ($c) = @_;

    # Keep the health endpoint version aligned with the plugin's single
    # authoritative VERSION value instead of duplicating a hard-coded value.
    require Koha::Plugin::Com::AJSN::PromotionEngagement;
    my $version = $Koha::Plugin::Com::AJSN::PromotionEngagement::VERSION // 'unknown';

    return $c->render(
        status  => 200,
        openapi => {
            status  => 'ok',
            plugin  => 'Promotion & Engagement',
            version => $version,
        }
    );
}

1;
