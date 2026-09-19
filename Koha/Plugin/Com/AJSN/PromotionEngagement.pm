package Koha::Plugin::Com::AJSN::PromotionEngagement;

use Modern::Perl;
use base qw(Koha::Plugins::Base);

use C4::Context;
use Koha::Items;
use Koha::Libraries;
use Mojo::JSON qw(decode_json encode_json);

our $VERSION = '0.2.0';

our $metadata = {
    name            => 'Promotion & Engagement',
    author          => 'Aljamea-tus-Saifiyah Nairobi',
    date_authored   => '2026-08-15',
    date_updated    => '2026-08-18',
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
        if ( ( $cgi->request_method || q{} ) eq 'POST'
            && ( $cgi->param('op') || q{} ) eq 'cud-create_promotion' )
        {
            return $self->_create_promotion;
        }
        return $self->_new_promotion_screen;
    }

    if ( $action eq 'promotions' ) {
        return $self->_promotions_screen;
    }

    if ( $action eq 'promotion_detail' ) {
        return $self->_promotion_detail_screen;
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
    my ( $self, $args ) = @_;
    $args ||= {};
    $self->_ensure_schema;

    my $dbh = C4::Context->dbh;

    my ($campaign_count) = $dbh->selectrow_array(
        'SELECT COUNT(*) FROM plugin_ajsn_promo_campaigns WHERE deleted_at IS NULL'
    );
    my ($item_count) = $dbh->selectrow_array(
        'SELECT COUNT(*) FROM plugin_ajsn_promo_items WHERE deleted_at IS NULL'
    );

    my $recent_campaigns = $dbh->selectall_arrayref(
        q{
            SELECT campaign_id, campaign_type, channel, name, start_date, end_date,
                   target_audience, status, created_at
              FROM plugin_ajsn_promo_campaigns
             WHERE deleted_at IS NULL
             ORDER BY campaign_id DESC
             LIMIT 10
        },
        { Slice => {} }
    );

    my $template = $self->get_template( { file => 'dashboard.tt' } );
    $template->param(
        plugin_version   => $VERSION,
        campaign_count   => $campaign_count || 0,
        item_count       => $item_count || 0,
        recent_campaigns => $recent_campaigns || [],
        success_message  => $args->{success_message},
        warning_message  => $args->{warning_message},
    );
    return $self->output_html( $template->output() );
}

sub _promotions_screen {
    my ( $self, $args ) = @_;
    $args ||= {};
    $self->_ensure_schema;

    my $dbh = C4::Context->dbh;
    my $campaigns = $dbh->selectall_arrayref(
        q{
            SELECT c.campaign_id, c.campaign_uuid, c.campaign_type, c.channel,
                   c.name, c.start_date, c.end_date, c.branchcode,
                   c.target_audience, c.language_code, c.display_location,
                   c.status, c.created_at, c.updated_at,
                   COUNT(pi.campaign_item_id) AS linked_item_count
              FROM plugin_ajsn_promo_campaigns c
              LEFT JOIN plugin_ajsn_promo_items pi
                ON pi.campaign_id = c.campaign_id
               AND pi.deleted_at IS NULL
             WHERE c.deleted_at IS NULL
             GROUP BY c.campaign_id, c.campaign_uuid, c.campaign_type, c.channel,
                      c.name, c.start_date, c.end_date, c.branchcode,
                      c.target_audience, c.language_code, c.display_location,
                      c.status, c.created_at, c.updated_at
             ORDER BY c.campaign_id DESC
             LIMIT 200
        },
        { Slice => {} }
    );

    my $template = $self->get_template( { file => 'promotions.tt' } );
    $template->param(
        plugin_version => $VERSION,
        campaigns      => $campaigns || [],
        error_message  => $args->{error_message},
    );
    return $self->output_html( $template->output() );
}

sub _promotion_detail_screen {
    my ($self) = @_;
    $self->_ensure_schema;

    my $cgi = $self->{cgi};
    my $campaign_id = _trim( scalar $cgi->param('campaign_id') );

    unless ( $campaign_id =~ /^\d+$/ && $campaign_id > 0 ) {
        return $self->_promotions_screen(
            { error_message => 'Select a valid campaign to view.' }
        );
    }

    my $dbh = C4::Context->dbh;
    my $campaign = $dbh->selectrow_hashref(
        q{
            SELECT campaign_id, campaign_uuid, campaign_type, channel, name,
                   start_date, end_date, branchcode, target_audience,
                   language_code, display_location, notes, status, created_by,
                   created_at, updated_at
              FROM plugin_ajsn_promo_campaigns
             WHERE campaign_id = ?
               AND deleted_at IS NULL
        },
        undef,
        $campaign_id,
    );

    unless ($campaign) {
        return $self->_promotions_screen(
            { error_message => 'The requested campaign does not exist or is no longer available.' }
        );
    }

    if ( $campaign->{branchcode} ) {
        my $library = Koha::Libraries->find( $campaign->{branchcode} );
        $campaign->{branchname} = $library ? $library->branchname : undef;
    }

    my $linked_items = $dbh->selectall_arrayref(
        q{
            SELECT pi.campaign_item_id, pi.itemnumber, pi.barcode, pi.added_at,
                   i.biblionumber, b.title, b.author
              FROM plugin_ajsn_promo_items pi
              LEFT JOIN items i
                ON i.itemnumber = pi.itemnumber
              LEFT JOIN biblio b
                ON b.biblionumber = i.biblionumber
             WHERE pi.campaign_id = ?
               AND pi.deleted_at IS NULL
             ORDER BY pi.campaign_item_id
        },
        { Slice => {} },
        $campaign_id,
    );

    my $audit_rows = $dbh->selectall_arrayref(
        q{
            SELECT audit_id, actor_borrowernumber, action_type, entity_type,
                   entity_id, created_at
              FROM plugin_ajsn_promo_audit
             WHERE campaign_id = ?
             ORDER BY audit_id DESC
             LIMIT 100
        },
        { Slice => {} },
        $campaign_id,
    );

    my $template = $self->get_template( { file => 'promotion_detail.tt' } );
    $template->param(
        plugin_version => $VERSION,
        campaign       => $campaign,
        linked_items   => $linked_items || [],
        audit_rows     => $audit_rows || [],
    );
    return $self->output_html( $template->output() );
}

sub _new_promotion_screen {
    my ( $self, $args ) = @_;
    $args ||= {};
    $self->_ensure_schema;

    my @libraries;
    my $libraries_rs = Koha::Libraries->search( {}, { order_by => 'branchname' } );
    while ( my $library = $libraries_rs->next ) {
        push @libraries,
          {
            branchcode => $library->branchcode,
            branchname => $library->branchname,
          };
    }

    my $template = $self->get_template( { file => 'new_promotion.tt' } );
    $template->param(
        plugin_version     => $VERSION,
        libraries          => \@libraries,
        form               => $args->{form} || {},
        errors             => $args->{errors} || [],
        warnings           => $args->{warnings} || [],
        invalid_barcodes   => $args->{invalid_barcodes} || [],
        duplicate_barcodes => $args->{duplicate_barcodes} || [],
        valid_item_count   => $args->{valid_item_count} || 0,
    );
    return $self->output_html( $template->output() );
}

sub _create_promotion {
    my ($self) = @_;
    my $cgi = $self->{cgi};

    my %form = (
        campaign_type    => _trim( scalar $cgi->param('campaign_type') ),
        channel          => _trim( scalar $cgi->param('channel') ),
        name             => _trim( scalar $cgi->param('name') ),
        start_date       => _trim( scalar $cgi->param('start_date') ),
        end_date         => _trim( scalar $cgi->param('end_date') ),
        branchcode       => _trim( scalar $cgi->param('branchcode') ),
        target_audience  => _trim( scalar $cgi->param('target_audience') ),
        language_code    => _trim( scalar $cgi->param('language_code') ),
        display_location => _trim( scalar $cgi->param('display_location') ),
        notes            => _trim( scalar $cgi->param('notes') ),
        status           => _trim( scalar $cgi->param('status') ) || 'draft',
        barcodes_text    => scalar( $cgi->param('barcodes') // q{} ),
    );

    my @errors;
    my @warnings;

    my %allowed_types = map { $_ => 1 } qw(
      subject_display new_arrivals recommendation email_campaign digital_signage
      physical_signage resource_feature author_feature publication_feature event
      outreach other
    );
    my %allowed_channels = map { $_ => 1 } qw(
      physical_display email digital_signage print_signage web social event other
    );
    my %allowed_statuses = map { $_ => 1 } qw(draft active completed);

    push @errors, 'Select a valid promotion type.'
      unless $allowed_types{ $form{campaign_type} };
    push @errors, 'Select a valid channel.'
      unless $allowed_channels{ $form{channel} };
    push @errors, 'Campaign name is required.' unless length $form{name};
    push @errors, 'Campaign name must be 255 characters or fewer.'
      if length( $form{name} ) > 255;
    push @errors, 'Start date is required.' unless length $form{start_date};
    push @errors, 'Start date must use YYYY-MM-DD format.'
      if length( $form{start_date} ) && $form{start_date} !~ /^\d{4}-\d{2}-\d{2}$/;
    push @errors, 'End date must use YYYY-MM-DD format.'
      if length( $form{end_date} ) && $form{end_date} !~ /^\d{4}-\d{2}-\d{2}$/;
    push @errors, 'End date cannot be before the start date.'
      if $form{start_date} =~ /^\d{4}-\d{2}-\d{2}$/
      && $form{end_date} =~ /^\d{4}-\d{2}-\d{2}$/
      && $form{end_date} lt $form{start_date};
    push @errors, 'Target audience must be 255 characters or fewer.'
      if length( $form{target_audience} ) > 255;
    push @errors, 'Language must be 30 characters or fewer.'
      if length( $form{language_code} ) > 30;
    push @errors, 'Location must be 255 characters or fewer.'
      if length( $form{display_location} ) > 255;
    push @errors, 'Select a valid status.' unless $allowed_statuses{ $form{status} };

    if ( length $form{branchcode} && !Koha::Libraries->find( $form{branchcode} ) ) {
        push @errors, 'The selected Koha library does not exist.';
    }

    my %seen;
    my @barcodes;
    my @duplicate_barcodes;
    for my $raw ( split /[\r\n,;]+/, $form{barcodes_text} ) {
        my $barcode = _trim($raw);
        next unless length $barcode;
        if ( $seen{$barcode}++ ) {
            push @duplicate_barcodes, $barcode;
            next;
        }
        push @barcodes, $barcode;
    }

    my @items;
    my @invalid_barcodes;
    for my $barcode (@barcodes) {
        my $item = Koha::Items->search( { barcode => $barcode } )->next;
        if ($item) {
            push @items,
              {
                itemnumber => $item->itemnumber,
                barcode    => $item->barcode,
              };
        } else {
            push @invalid_barcodes, $barcode;
        }
    }

    if (@invalid_barcodes) {
        push @errors,
          'No campaign was saved because one or more barcodes do not exist in Koha. Correct or remove the invalid barcodes and submit again.';
    }
    if (@duplicate_barcodes) {
        push @warnings,
          'Duplicate barcode entries were detected. Each duplicate is ignored and each Koha item can be linked only once per campaign.';
    }

    if (@errors) {
        return $self->_new_promotion_screen(
            {
                form               => \%form,
                errors             => \@errors,
                warnings           => \@warnings,
                invalid_barcodes   => \@invalid_barcodes,
                duplicate_barcodes => \@duplicate_barcodes,
                valid_item_count   => scalar @items,
            }
        );
    }

    my $dbh = C4::Context->dbh;
    my ($campaign_uuid) = $dbh->selectrow_array('SELECT UUID()');
    my $actor = C4::Context->userenv ? C4::Context->userenv->{number} : undef;
    my $campaign_id;

    my $ok = eval {
        local $dbh->{RaiseError} = 1;
        $dbh->begin_work;

        $dbh->do(
            q{
                INSERT INTO plugin_ajsn_promo_campaigns
                    (campaign_uuid, campaign_type, channel, name, start_date, end_date,
                     branchcode, target_audience, language_code, display_location,
                     notes, status, created_by)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            },
            undef,
            $campaign_uuid,
            $form{campaign_type},
            $form{channel},
            $form{name},
            $form{start_date},
            length( $form{end_date} ) ? $form{end_date} : undef,
            length( $form{branchcode} ) ? $form{branchcode} : undef,
            length( $form{target_audience} ) ? $form{target_audience} : undef,
            length( $form{language_code} ) ? $form{language_code} : undef,
            length( $form{display_location} ) ? $form{display_location} : undef,
            length( $form{notes} ) ? $form{notes} : undef,
            $form{status},
            $actor,
        );

        $campaign_id = $dbh->last_insert_id(
            undef, undef, 'plugin_ajsn_promo_campaigns', 'campaign_id'
        );

        my $item_sth = $dbh->prepare(q{
            INSERT INTO plugin_ajsn_promo_items
                (campaign_id, itemnumber, barcode, added_by)
            VALUES (?, ?, ?, ?)
        });
        for my $item (@items) {
            $item_sth->execute(
                $campaign_id,
                $item->{itemnumber},
                $item->{barcode},
                $actor,
            );
        }

        my $details = encode_json(
            {
                campaign_uuid => $campaign_uuid,
                campaign_type => $form{campaign_type},
                channel       => $form{channel},
                status        => $form{status},
                item_count    => scalar @items,
            }
        );

        $dbh->do(
            q{
                INSERT INTO plugin_ajsn_promo_audit
                    (campaign_id, actor_borrowernumber, action_type, entity_type,
                     entity_id, details_json)
                VALUES (?, ?, 'campaign_created', 'campaign', ?, ?)
            },
            undef,
            $campaign_id,
            $actor,
            $campaign_uuid,
            $details,
        );

        $dbh->commit;
        1;
    };

    if ( !$ok ) {
        my $error = $@ || 'Unknown database error';
        eval { $dbh->rollback };
        warn "Promotion & Engagement campaign save failed: $error";
        push @errors, 'The campaign could not be saved because of a database error. No partial campaign data was kept.';
        return $self->_new_promotion_screen(
            {
                form               => \%form,
                errors             => \@errors,
                warnings           => \@warnings,
                duplicate_barcodes => \@duplicate_barcodes,
                valid_item_count   => scalar @items,
            }
        );
    }

    my $message = sprintf(
        'Campaign "%s" was created successfully with %d linked Koha item%s.',
        $form{name}, scalar @items, scalar(@items) == 1 ? q{} : 's'
    );
    my $warning_message = @duplicate_barcodes
      ? sprintf( '%d duplicate barcode entr%s ignored.', scalar @duplicate_barcodes, scalar(@duplicate_barcodes) == 1 ? 'y was' : 'ies were' )
      : undef;

    return $self->_dashboard(
        {
            success_message => $message,
            warning_message => $warning_message,
        }
    );
}

sub _ensure_schema {
    my ($self) = @_;
    my $dbh = C4::Context->dbh;

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS plugin_ajsn_promo_campaigns (
            campaign_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            campaign_uuid CHAR(36) NOT NULL,
            campaign_type VARCHAR(80) NOT NULL,
            channel VARCHAR(80) NULL,
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

    unless ( _column_exists( $dbh, 'plugin_ajsn_promo_campaigns', 'channel' ) ) {
        $dbh->do(q{
            ALTER TABLE plugin_ajsn_promo_campaigns
            ADD COLUMN channel VARCHAR(80) NULL AFTER campaign_type
        });
    }

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

sub _column_exists {
    my ( $dbh, $table, $column ) = @_;
    my ($count) = $dbh->selectrow_array(
        q{
            SELECT COUNT(*)
              FROM information_schema.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = ?
               AND COLUMN_NAME = ?
        },
        undef,
        $table,
        $column,
    );
    return $count ? 1 : 0;
}

sub _trim {
    my ($value) = @_;
    return q{} unless defined $value;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return $value;
}

1;