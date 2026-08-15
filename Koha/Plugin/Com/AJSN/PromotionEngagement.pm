package Koha::Plugin::Com::AJSN::PromotionEngagement;

use Modern::Perl;
use base qw(Koha::Plugins::Base);

use C4::Context;
use Koha::Items;
use Mojo::JSON qw(decode_json);

our $VERSION = '0.1.0';

our $metadata = {
    name            => 'Promotion & Engagement',
    author          => 'Aljamea-tus-Saifiyah Nairobi',
    date_authored   => '2026-08-15',
    date_updated    => '2026-08-15',
    minimum_version => '25.11.00.000',
    maximum_version => undef,
    version         => $VERSION,
    description     => 'Track library promotions and measure their circulation impact using Koha as the source of truth.',
};

sub new {
    my ( $class, $args ) = @_;
    $args->{metadata} = $metadata;
    $args->{metadata}->{class} = $class;
    return $class->SUPER::new($args);
}

sub tool {
    my ( $self, $args ) = @_;
    my $cgi    = $self->{cgi};
    my $action = $cgi->param('action') || 'dashboard';

    if ( $action eq 'new_promotion' ) {
        return $self->_new_promotion_screen;
    }

    return $self->_dashboard;
}

sub configure {
    my ( $self, $args ) = @_;
    my $template = $self->get_template( { file => 'configure.tt' } );
    $template->param(
        plugin_version => $VERSION,
        api_namespace  => $self->api_namespace,
    );
    return $self->output_html( $template->output() );
}

sub install {
    my ( $self, $args ) = @_;
    $self->_ensure_schema;
    return 1;
}

sub upgrade {
    my ( $self, $args ) = @_;
    $self->_ensure_schema;
    return 1;
}

# Safety policy: uninstalling the plugin does NOT destroy historical campaign data.
# A future explicit data-purge action will require separate administrator confirmation.
sub uninstall {
    my ( $self, $args ) = @_;
    return 1;
}

sub api_namespace {
    return 'ajsn_promotion';
}

sub api_routes {
    my ($self) = @_;
    my $spec = $self->mbf_read('openapi.json');
    return decode_json($spec);
}

sub _dashboard {
    my ($self) = @_;
    my $dbh = C4::Context->dbh;

    my ($campaign_count) = $dbh->selectrow_array(
        'SELECT COUNT(*) FROM plugin_ajsn_promo_campaigns WHERE deleted_at IS NULL'
    );
    my ($item_count) = $dbh->selectrow_array(
        'SELECT COUNT(*) FROM plugin_ajsn_promo_items WHERE deleted_at IS NULL'
    );

    my $template = $self->get_template( { file => 'dashboard.tt' } );
    $template->param(
        plugin_version => $VERSION,
        campaign_count => $campaign_count || 0,
        item_count     => $item_count || 0,
    );
    return $self->output_html( $template->output() );
}

sub _new_promotion_screen {
    my ($self) = @_;
    my $template = $self->get_template( { file => 'new_promotion.tt' } );
    $template->param( plugin_version => $VERSION );
    return $self->output_html( $template->output() );
}

sub _ensure_schema {
    my ($self) = @_;
    my $dbh = C4::Context->dbh;

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS plugin_ajsn_promo_campaigns (
            campaign_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            campaign_uuid CHAR(36) NOT NULL,
            campaign_type VARCHAR(80) NOT NULL,
            name VARCHAR(255) NOT NULL,
            start_date DATE NOT NULL,
            end_date DATE NULL,
            branchcode VARCHAR(10) NULL,
            target_audience VARCHAR(255) NULL,
            language_code VARCHAR(30) NULL,
            display_location VARCHAR(255) NULL,
            notes TEXT NULL,
            status VARCHAR(30) NOT NULL DEFAULT 'draft',
            created_by INT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            deleted_at DATETIME NULL,
            PRIMARY KEY (campaign_id),
            UNIQUE KEY uq_campaign_uuid (campaign_uuid),
            KEY idx_campaign_dates (start_date, end_date),
            KEY idx_campaign_branch (branchcode),
            KEY idx_campaign_status (status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    });

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS plugin_ajsn_promo_items (
            campaign_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            campaign_id BIGINT UNSIGNED NOT NULL,
            itemnumber INT NOT NULL,
            barcode VARCHAR(100) NULL,
            added_by INT NULL,
            added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            deleted_at DATETIME NULL,
            PRIMARY KEY (campaign_item_id),
            UNIQUE KEY uq_campaign_item (campaign_id, itemnumber),
            KEY idx_promo_itemnumber (itemnumber),
            KEY idx_promo_barcode (barcode),
            CONSTRAINT fk_ajsn_promo_item_campaign
                FOREIGN KEY (campaign_id)
                REFERENCES plugin_ajsn_promo_campaigns (campaign_id)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    });

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS plugin_ajsn_promo_audit (
            audit_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            campaign_id BIGINT UNSIGNED NULL,
            actor_borrowernumber INT NULL,
            action_type VARCHAR(80) NOT NULL,
            entity_type VARCHAR(80) NOT NULL,
            entity_id VARCHAR(100) NULL,
            details_json LONGTEXT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (audit_id),
            KEY idx_audit_campaign (campaign_id),
            KEY idx_audit_actor (actor_borrowernumber),
            KEY idx_audit_created (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    });

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS plugin_ajsn_promo_settings (
            setting_key VARCHAR(100) NOT NULL,
            setting_value LONGTEXT NULL,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (setting_key)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    });

    return 1;
}

1;
