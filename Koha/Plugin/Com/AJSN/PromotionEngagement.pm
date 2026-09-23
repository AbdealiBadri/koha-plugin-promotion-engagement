package Koha::Plugin::Com::AJSN::PromotionEngagement;

use Modern::Perl;
use base qw(Koha::Plugins::Base);

use C4::Context;
use Koha::Items;
use Koha::Libraries;
use Koha::Patrons;
use Koha::Suggestion;
use Mojo::JSON qw(decode_json encode_json);
use Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics;
use Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact;

our $VERSION = '0.6.0';

our $metadata = {
    name            => 'Promotion & Engagement',
    author          => 'Aljamea-tus-Saifiyah Nairobi',
    date_authored   => '2026-08-15',
    date_updated    => '2026-09-23',
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

    if ( $action eq 'analytics' ) {
        return $self->_analytics_screen;
    }

    if ( $action eq 'book_display_impact' ) {
        my $op = $cgi->param('op') || q{};
        return $self->_save_impact_decision
          if ( $cgi->request_method || q{} ) eq 'POST'
          && $op eq 'cud-save_impact_decision';
        return $self->_submit_impact_suggestion
          if ( $cgi->request_method || q{} ) eq 'POST'
          && $op eq 'cud-submit_impact_suggestion';
        return $self->_book_display_impact_screen;
    }

    if ( $action eq 'reports' ) {
        return $self->_reports_screen;
    }

    if ( $action eq 'report_export' ) {
        return $self->_report_export;
    }

    if ( $action eq 'promotion_detail' ) {
        return $self->_promotion_detail_screen;
    }

    if ( $action eq 'edit_promotion' ) {
        if ( ( $cgi->request_method || q{} ) eq 'POST'
            && ( $cgi->param('op') || q{} ) eq 'cud-update_promotion' )
        {
            return $self->_update_promotion;
        }
        return $self->_edit_promotion_screen;
    }

    if ( $action eq 'archive_promotion' ) {
        if ( ( $cgi->request_method || q{} ) eq 'POST'
            && ( $cgi->param('op') || q{} ) eq 'cud-archive_promotion' )
        {
            return $self->_archive_promotion;
        }
        return $self->_promotions_screen(
            { error_message => 'Archive requests must be submitted from a campaign detail page.' }
        );
    }

    return $self->_dashboard;
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{cgi};
    $self->_ensure_schema;

    my $success_message;
    my @errors;

    if ( ( $cgi->request_method || q{} ) eq 'POST' ) {
        my $op = $cgi->param('op') || q{};

        if ( $op eq 'cud-save_vocab_value' ) {
            my $dimension  = _trim( scalar $cgi->param('dimension') );
            my $value_code = lc _trim( scalar $cgi->param('value_code') );
            my $label      = _trim( scalar $cgi->param('label') );
            my $sort_order = _trim( scalar $cgi->param('sort_order') );
            my $is_active  = $cgi->param('is_active') ? 1 : 0;

            my %allowed_dimensions = map { $_ => 1 } qw(
              campaign_type channel location language audience cadence
            );

            push @errors, 'Select a valid configuration dimension.'
              unless $allowed_dimensions{$dimension};
            push @errors, 'Code is required.'
              unless length $value_code;
            push @errors, 'Code may contain only lowercase letters, numbers, underscore and hyphen.'
              if length($value_code)
              && $value_code !~ /^[a-z0-9][a-z0-9_-]{0,79}$/;
            push @errors, 'Language stable codes must be 30 characters or fewer because the campaign record stores language_code in a 30-character field.'
              if $dimension eq 'language' && length($value_code) > 30;
            push @errors, 'Label is required.'
              unless length $label;
            push @errors, 'Label must be 255 characters or fewer.'
              if length($label) > 255;
            push @errors, 'Sort order must be a whole number from 0 to 9999.'
              unless $sort_order =~ /^\d{1,4}$/ && $sort_order <= 9999;

            unless (@errors) {
                my $dbh   = C4::Context->dbh;
                my $actor = C4::Context->userenv ? C4::Context->userenv->{number} : undef;

                my $ok = eval {
                    local $dbh->{RaiseError} = 1;
                    $dbh->begin_work;
                    $dbh->do(
                        q{
                            INSERT INTO plugin_ajsn_promo_vocab_values
                                (dimension, value_code, label, sort_order, is_active,
                                 created_by, updated_by, deleted_at)
                            VALUES (?, ?, ?, ?, ?, ?, ?, NULL)
                            ON DUPLICATE KEY UPDATE
                                label = VALUES(label),
                                sort_order = VALUES(sort_order),
                                is_active = VALUES(is_active),
                                updated_by = VALUES(updated_by),
                                deleted_at = NULL
                        },
                        undef,
                        $dimension,
                        $value_code,
                        $label,
                        $sort_order,
                        $is_active,
                        $actor,
                        $actor,
                    );
                    $dbh->commit;
                    1;
                };

                if ($ok) {
                    $success_message = sprintf(
                        'Saved %s value "%s".',
                        $dimension,
                        $label,
                    );
                } else {
                    my $error = $@ || 'Unknown database error';
                    eval { $dbh->rollback };
                    warn "Promotion & Engagement vocabulary save failed: $error";
                    push @errors, 'The configuration value could not be saved. No partial change was kept.';
                }
            }
        }
        elsif ( $op eq 'cud-toggle_vocab_value' ) {
            my $vocab_value_id = _trim( scalar $cgi->param('vocab_value_id') );
            my $set_active     = _trim( scalar $cgi->param('set_active') );

            push @errors, 'Select a valid configuration value.'
              unless $vocab_value_id =~ /^\d+$/ && $vocab_value_id > 0;
            push @errors, 'Invalid active-state request.'
              unless $set_active eq '0' || $set_active eq '1';

            unless (@errors) {
                my $dbh   = C4::Context->dbh;
                my $actor = C4::Context->userenv ? C4::Context->userenv->{number} : undef;
                my $rows  = $dbh->do(
                    q{
                        UPDATE plugin_ajsn_promo_vocab_values
                           SET is_active = ?, updated_by = ?
                         WHERE vocab_value_id = ?
                           AND deleted_at IS NULL
                    },
                    undef,
                    $set_active,
                    $actor,
                    $vocab_value_id,
                );

                if ( $rows && $rows > 0 ) {
                    $success_message = $set_active
                      ? 'Configuration value enabled.'
                      : 'Configuration value disabled.';
                } else {
                    push @errors, 'The requested configuration value was not found.';
                }
            }
        }
        elsif ( length $op ) {
            push @errors, 'Unsupported configuration action.';
        }
    }

    my $dbh = C4::Context->dbh;
    my $rows = $dbh->selectall_arrayref(
        q{
            SELECT vocab_value_id, dimension, value_code, label,
                   sort_order, is_active, created_at, updated_at
              FROM plugin_ajsn_promo_vocab_values
             WHERE deleted_at IS NULL
             ORDER BY dimension, sort_order, label, value_code
        },
        { Slice => {} },
    );

    my @dimension_order = qw(
      campaign_type channel location language audience cadence
    );
    my %dimension_labels = (
        campaign_type => 'Campaign types',
        channel       => 'Channels',
        location      => 'Locations',
        language      => 'Languages',
        audience      => 'Audiences',
        cadence       => 'Cadence / frequency',
    );
    my %values_by_dimension;
    for my $row ( @{ $rows || [] } ) {
        push @{ $values_by_dimension{ $row->{dimension} } }, $row;
    }

    my @vocabulary_groups = map {
        {
            dimension => $_,
            label     => $dimension_labels{$_},
            values    => $values_by_dimension{$_} || [],
        }
    } @dimension_order;

    my $template = $self->get_template( { file => 'configure.tt' } );
    $template->param(
        plugin_version    => $VERSION,
        api_namespace     => $self->api_namespace,
        vocabulary_groups => \@vocabulary_groups,
        success_message   => $success_message,
        errors            => \@errors,
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
        q{
            SELECT COUNT(*)
              FROM plugin_ajsn_promo_items pi
              JOIN plugin_ajsn_promo_campaigns c
                ON c.campaign_id = pi.campaign_id
             WHERE pi.deleted_at IS NULL
               AND c.deleted_at IS NULL
        }
    );

    my ($active_count) = $dbh->selectrow_array(
        q{SELECT COUNT(*) FROM plugin_ajsn_promo_campaigns
           WHERE deleted_at IS NULL AND status = 'active'}
    );
    my ($completed_count) = $dbh->selectrow_array(
        q{SELECT COUNT(*) FROM plugin_ajsn_promo_campaigns
           WHERE deleted_at IS NULL AND status = 'completed'}
    );
    my ($location_count) = $dbh->selectrow_array(
        q{SELECT COUNT(*) FROM plugin_ajsn_promo_vocab_values
           WHERE dimension = 'location' AND is_active = 1 AND deleted_at IS NULL}
    );
    my $campaign_ids = $dbh->selectcol_arrayref(
        q{SELECT campaign_id FROM plugin_ajsn_promo_campaigns
           WHERE deleted_at IS NULL AND start_date IS NOT NULL
           ORDER BY campaign_id DESC LIMIT 50}
    ) || [];
    my ( $portfolio, $channel_comparison, $location_comparison );
    if ( @{$campaign_ids} ) {
        my $service =
          Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
            { dbh => $dbh }
          );
        eval {
            $portfolio = $service->portfolio_metrics($campaign_ids);
            $channel_comparison =
              $service->comparison_metrics( 'channel', $campaign_ids );
            $location_comparison =
              $service->comparison_metrics( 'location', $campaign_ids );
            1;
        } or warn "Promotion & Engagement dashboard analytics failed: $@";
    }

    my $recent_campaigns = $dbh->selectall_arrayref(
        q{
            SELECT c.campaign_id, c.campaign_type, c.channel, c.name,
                   c.start_date, c.end_date, c.target_audience, c.status,
                   c.created_at,
                   COALESCE(vt.label, c.campaign_type) AS campaign_type_label,
                   COALESCE(vc.label, c.channel) AS channel_label
              FROM plugin_ajsn_promo_campaigns c
              LEFT JOIN plugin_ajsn_promo_vocab_values vt
                ON vt.dimension = 'campaign_type'
               AND vt.value_code = c.campaign_type
               AND vt.deleted_at IS NULL
              LEFT JOIN plugin_ajsn_promo_vocab_values vc
                ON vc.dimension = 'channel'
               AND vc.value_code = c.channel
               AND vc.deleted_at IS NULL
             WHERE c.deleted_at IS NULL
             ORDER BY c.campaign_id DESC
             LIMIT 10
        },
        { Slice => {} }
    );

    my %analytics_by_campaign;
    if ( $portfolio && $portfolio->{campaign_results} ) {
        for my $result ( @{ $portfolio->{campaign_results} } ) {
            _prepare_analytics_for_display($result);
            $analytics_by_campaign{ $result->{campaign}->{campaign_id} } = $result;
        }
    }
    for my $campaign ( @{ $recent_campaigns || [] } ) {
        my $analytics = $analytics_by_campaign{ $campaign->{campaign_id} };
        next unless $analytics;
        $campaign->{promoted_title_count} = $analytics->{promoted_title_count};
        $campaign->{titles_used_count} = $analytics->{titles_used_count};
        $campaign->{titles_used_display} = $analytics->{titles_used_display};
        $campaign->{campaign_checkout_count} =
          $analytics->{during_checkout_count};
        $campaign->{campaign_checkout_display} =
          $analytics->{campaign_checkout_display};
        $campaign->{title_utilization_display} =
          $analytics->{title_utilization_display};
        $campaign->{uplift_display} = $analytics->{uplift_display};
        $campaign->{new_response} = $analytics->{new_response};
        $campaign->{impact_provisional} =
          $analytics->{impact_evidence}->{provisional} ? 1 : 0;
        $campaign->{analytics_available} = 1;
    }

    my $portfolio_utilization_display =
      $portfolio && defined $portfolio->{title_utilization_rate}
      ? sprintf( '%.1f', $portfolio->{title_utilization_rate} )
      : undef;

    my $template = $self->get_template( { file => 'dashboard.tt' } );
    $template->param(
        plugin_version   => $VERSION,
        campaign_count   => $campaign_count || 0,
        item_count       => $item_count || 0,
        active_count     => $active_count || 0,
        completed_count  => $completed_count || 0,
        location_count   => $location_count || 0,
        portfolio        => $portfolio,
        portfolio_utilization_display => $portfolio_utilization_display,
        channel_rows     => $channel_comparison ? $channel_comparison->{rows} : [],
        location_rows    => $location_comparison ? $location_comparison->{rows} : [],
        leading_location => _leading_location(
            $location_comparison ? $location_comparison->{rows} : []
        ),
        recent_campaigns => $recent_campaigns || [],
        success_message  => $args->{success_message},
        warning_message  => $args->{warning_message},
    );
    return $self->output_html( $template->output() );
}

sub _analytics_campaign_id {
    my ( $requested_id, $campaigns ) = @_;

    $requested_id = _trim($requested_id);
    return $requested_id if length $requested_id;
    return q{} unless $campaigns && @{$campaigns};

    return $campaigns->[0]->{campaign_id} || q{};
}

sub _prepare_analytics_for_display {
    my ($analytics) = @_;
    return $analytics unless $analytics;

    my $utilization = $analytics->{title_utilization_rate};
    my $uplift = $analytics->{uplift_percent};
    my $baseline_rate = $analytics->{metrics}->{baseline}->{daily_checkout_rate};
    my $during_rate = $analytics->{metrics}->{during}->{daily_checkout_rate};
    my $baseline_checkouts =
      $analytics->{metrics}->{baseline}->{checkout_count};
    my $during_checkouts =
      $analytics->{metrics}->{during}->{checkout_count};

    $analytics->{title_utilization_display} =
      defined $utilization ? sprintf( '%.1f', $utilization ) : undef;
    $analytics->{uplift_display} =
      defined $uplift ? sprintf( '%+.1f', $uplift ) : undef;
    $analytics->{baseline_rate_display} =
      defined $baseline_rate ? sprintf( '%.2f', $baseline_rate ) : undef;
    $analytics->{during_rate_display} =
      defined $during_rate ? sprintf( '%.2f', $during_rate ) : undef;
    $analytics->{baseline_checkout_count} = $baseline_checkouts;
    $analytics->{during_checkout_count} = $during_checkouts;
    $analytics->{promoted_title_display} =
      defined $analytics->{promoted_title_count}
      ? q{} . $analytics->{promoted_title_count} : '—';
    $analytics->{titles_used_display} =
      defined $analytics->{titles_used_count}
      ? q{} . $analytics->{titles_used_count} : '—';
    $analytics->{campaign_checkout_display} =
      defined $during_checkouts ? q{} . $during_checkouts : '—';
    $analytics->{zero_response_display} =
      defined $analytics->{zero_response_title_count}
      ? q{} . $analytics->{zero_response_title_count} : '—';
    $analytics->{titles_increased_display} =
      defined $analytics->{titles_increased_count}
      ? q{} . $analytics->{titles_increased_count} : '—';
    $analytics->{repeat_demand_display} =
      defined $analytics->{repeat_demand_title_count}
      ? q{} . $analytics->{repeat_demand_title_count} : '—';

    my $title_rows = $analytics->{title_response_rows} || [];
    my $titles_lower_count = scalar grep {
        ( $_->{response_label} || q{} ) eq 'Lower'
    } @{$title_rows};
    my $titles_unchanged_count = scalar grep {
        ( $_->{response_label} || q{} ) eq 'Unchanged'
    } @{$title_rows};
    $analytics->{titles_lower_count} = $titles_lower_count;
    $analytics->{titles_unchanged_count} = $titles_unchanged_count;
    $analytics->{titles_lower_display} = q{} . $titles_lower_count;
    $analytics->{titles_unchanged_display} = q{} . $titles_unchanged_count;

    $analytics->{new_response} =
      defined $baseline_checkouts
      && defined $during_checkouts
      && !$baseline_checkouts
      && $during_checkouts > 0 ? 1 : 0;

    return $analytics;
}

sub _analytics_screen {
    my ($self) = @_;
    $self->_ensure_schema;

    my $cgi = $self->{cgi};
    my $dbh = C4::Context->dbh;
    my $campaigns = $dbh->selectall_arrayref(
        q{
            SELECT campaign_id, name, start_date, end_date, status
              FROM plugin_ajsn_promo_campaigns
             WHERE deleted_at IS NULL
             ORDER BY campaign_id DESC
             LIMIT 200
        },
        { Slice => {} },
    ) || [];

    my $campaign_id = _analytics_campaign_id(
        scalar $cgi->param('campaign_id'),
        $campaigns,
    );

    my ( $analytics, $error_message, @window_rows );
    if ( length $campaign_id ) {
        if ( $campaign_id =~ /^\d+$/ && $campaign_id > 0 ) {
            my $ok = eval {
                my $service =
                  Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
                    { dbh => $dbh }
                  );
                $analytics = _prepare_analytics_for_display(
                    $service->campaign_metrics($campaign_id)
                );
                1;
            };
            unless ($ok) {
                my $error = $@ || 'Unknown analytics error';
                warn "Promotion & Engagement analytics failed: $error";
                $error_message = 'Analytics could not be calculated for the selected campaign.';
            }
        } else {
            $error_message = 'Select a valid campaign.';
        }
    }

    if ($analytics) {
        $analytics->{uplift_available} =
          defined $analytics->{uplift_percent} ? 1 : 0;
        $analytics->{days_to_first_available} =
          defined $analytics->{days_to_first_checkout} ? 1 : 0;
        my %labels = (
            baseline => 'Baseline',
            during   => 'During campaign',
            after_7  => 'After 7 days',
            after_14 => 'After 14 days',
            after_30 => 'After 30 days',
            after_60 => 'After 60 days',
        );
        @window_rows = map {
            {
                key     => $_,
                label   => $labels{$_},
                window  => $analytics->{windows}->{$_},
                metrics => $analytics->{metrics}->{$_},
            }
        } qw(baseline during after_7 after_14 after_30 after_60);
    }

    my $template = $self->get_template( { file => 'analytics.tt' } );
    $template->param(
        plugin_version => $VERSION,
        campaigns      => $campaigns,
        selected_id    => $campaign_id,
        analytics      => $analytics,
        window_rows    => \@window_rows,
        error_message  => $error_message,
    );
    return $self->output_html( $template->output() );
}

sub _book_display_impact_screen {
    my ( $self, $args ) = @_;
    $args ||= {};
    $self->_ensure_schema;
    my $cgi = $self->{cgi};
    my $dbh = C4::Context->dbh;
    my $campaigns = $dbh->selectall_arrayref(
        q{
            SELECT campaign_id, name, start_date, end_date, status
              FROM plugin_ajsn_promo_campaigns
             WHERE deleted_at IS NULL
             ORDER BY campaign_id DESC LIMIT 200
        }, { Slice => {} },
    ) || [];
    my $campaign_id = _analytics_campaign_id(
        scalar $cgi->param('campaign_id'), $campaigns
    );
    my ( $impact, $error_message );
    if ( length $campaign_id && $campaign_id =~ /^\d+$/ ) {
        eval {
            $impact =
              Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact
              ->new( { dbh => $dbh } )->campaign_rows($campaign_id);
            1;
        } or do {
            warn "Book Display Impact calculation failed: $@";
            $error_message = 'Book Display Impact could not be calculated.';
        };
    }
    my $template = $self->get_template( { file => 'book_display_impact.tt' } );
    $template->param(
        plugin_version => $VERSION,
        campaigns => $campaigns,
        selected_id => $campaign_id,
        impact => $impact,
        error_message => $error_message || $args->{error_message},
        success_message => $args->{success_message},
    );
    return $self->output_html( $template->output() );
}

sub _save_impact_decision {
    my ($self) = @_;
    $self->_ensure_schema;
    my $cgi = $self->{cgi};
    my $campaign_id = _trim( scalar $cgi->param('campaign_id') );
    my $biblionumber = _trim( scalar $cgi->param('biblionumber') );
    my $decision = _trim( scalar $cgi->param('decision_status') );
    my $quantity = _trim( scalar $cgi->param('recommended_quantity') );
    my $note = _trim( scalar $cgi->param('reviewer_note') );
    my @errors;
    push @errors, 'Invalid campaign.' unless $campaign_id =~ /^\d+$/;
    push @errors, 'Invalid title.' unless $biblionumber =~ /^\d+$/;
    push @errors, 'Select Approve or Reject.'
      unless $decision eq 'approved' || $decision eq 'rejected';
    push @errors, 'Quantity must be from 1 to 99.'
      unless $quantity =~ /^\d+$/ && $quantity >= 1 && $quantity <= 99;
    return $self->_book_display_impact_screen(
        { error_message => join q{ }, @errors }
    ) if @errors;

    my $dbh = C4::Context->dbh;
    my $actor = C4::Context->userenv ? C4::Context->userenv->{number} : undef;
    my ($valid) = $dbh->selectrow_array(
        q{SELECT COUNT(*) FROM plugin_ajsn_promo_campaigns c
          JOIN plugin_ajsn_promo_items pi ON pi.campaign_id=c.campaign_id
          JOIN items i ON i.itemnumber=pi.itemnumber
          WHERE c.campaign_id=? AND i.biblionumber=? AND c.deleted_at IS NULL
            AND pi.deleted_at IS NULL},
        undef, $campaign_id, $biblionumber,
    );
    return $self->_book_display_impact_screen(
        { error_message => 'The selected title is not linked to this campaign.' }
    ) unless $valid;
    my ($already_submitted) = $dbh->selectrow_array(
        q{SELECT koha_suggestion_id FROM plugin_ajsn_promo_recommendations
          WHERE campaign_id=? AND biblionumber=?},
        undef, $campaign_id, $biblionumber,
    );
    return $self->_book_display_impact_screen( {
        error_message => 'A submitted Koha suggestion cannot be overwritten.'
    } ) if $already_submitted;

    my $impact =
      Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact
      ->new( { dbh => $dbh } )->campaign_rows($campaign_id);
    my ($evidence_row) =
      grep { $_->{biblionumber} == $biblionumber } @{ $impact->{rows} };
    my $evidence_json = encode_json( {
        baseline_count => 0 + ( $evidence_row->{baseline_count} || 0 ),
        during_count => 0 + ( $evidence_row->{during_count} || 0 ),
        after_60_count => 0 + ( $evidence_row->{after_60_count} || 0 ),
        serviceable_copies => 0 + ( $evidence_row->{serviceable_copies} || 0 ),
        active_holds => 0 + ( $evidence_row->{active_holds} || 0 ),
        hold_ratio => 0 + ( $evidence_row->{hold_ratio} || 0 ),
        priority => $evidence_row->{priority},
        evidence_grade => $evidence_row->{evidence_grade},
    } );

    $dbh->do(
        q{
            INSERT INTO plugin_ajsn_promo_recommendations
              (campaign_id,biblionumber,decision_status,recommended_quantity,
               reviewer_note,evidence_json,decided_by,decided_at)
            VALUES (?,?,?,?,?,?,?,NOW())
            ON DUPLICATE KEY UPDATE decision_status=VALUES(decision_status),
              recommended_quantity=VALUES(recommended_quantity),
              reviewer_note=VALUES(reviewer_note),
              evidence_json=VALUES(evidence_json),decided_by=VALUES(decided_by),
              decided_at=NOW()
        }, undef, $campaign_id, $biblionumber, $decision, $quantity,
        $note, $evidence_json, $actor,
    );
    $dbh->do(
        q{INSERT INTO plugin_ajsn_promo_audit
          (campaign_id,actor_borrowernumber,action_type,entity_type,entity_id,details_json)
          VALUES (?,?,'impact_decision_recorded','biblio',?,?)},
        undef, $campaign_id, $actor, $biblionumber,
        encode_json( { decision => $decision, quantity => 0 + $quantity } ),
    );
    return $self->_book_display_impact_screen( {
        success_message => ucfirst($decision) . ' decision saved with audit history.'
    } );
}

sub _submit_impact_suggestion {
    my ($self) = @_;
    $self->_ensure_schema;
    my $cgi = $self->{cgi};
    my $campaign_id = _trim( scalar $cgi->param('campaign_id') );
    my $biblionumber = _trim( scalar $cgi->param('biblionumber') );
    return $self->_book_display_impact_screen(
        { error_message => 'Invalid campaign or title.' }
    ) unless $campaign_id =~ /^\d+$/ && $biblionumber =~ /^\d+$/;

    my $actor = C4::Context->userenv ? C4::Context->userenv->{number} : undef;
    my $patron = $actor ? Koha::Patrons->find($actor) : undef;
    my $allowed = $patron && (
        $patron->has_permission( { suggestions => 'suggestions_create' } )
        || $patron->has_permission( { suggestions => 'suggestions_manage' } )
    );
    return $self->_book_display_impact_screen( {
        error_message => 'Your Koha account needs purchase-suggestion permission.'
    } ) unless $allowed;

    my $dbh = C4::Context->dbh;
    my $row = $dbh->selectrow_hashref(
        q{SELECT r.*,c.name AS campaign_name,c.branchcode,b.title,b.author
          FROM plugin_ajsn_promo_recommendations r
          JOIN plugin_ajsn_promo_campaigns c ON c.campaign_id=r.campaign_id
          JOIN biblio b ON b.biblionumber=r.biblionumber
          WHERE r.campaign_id=? AND r.biblionumber=?},
        undef, $campaign_id, $biblionumber,
    );
    return $self->_book_display_impact_screen( {
        error_message => 'Approve this recommendation before submitting it.'
    } ) unless $row && $row->{decision_status} eq 'approved';
    return $self->_book_display_impact_screen( {
        error_message => 'This recommendation has already been submitted to Koha.'
    } ) if $row->{koha_suggestion_id};

    my $suggestion;
    my $ok = eval {
        local $dbh->{RaiseError} = 1;
        $dbh->begin_work;
        $suggestion = Koha::Suggestion->new( {
            suggestedby => $actor, title => $row->{title},
            author => $row->{author}, biblionumber => $biblionumber,
            branchcode => $row->{branchcode}, quantity => $row->{recommended_quantity},
            STATUS => 'ASKED',
            reason => 'Book Display Impact',
            patronreason => undef,
            staff_note => sprintf(
                'Evidence-based additional-copy recommendation. Campaign: %s (ID %d). %s',
                $row->{campaign_name}, $campaign_id, $row->{reviewer_note} || q{}
            ),
        } )->store;
        $dbh->do(
            q{UPDATE plugin_ajsn_promo_recommendations
              SET decision_status='submitted',koha_suggestion_id=?,submitted_at=NOW()
              WHERE recommendation_id=?},
            undef, $suggestion->suggestionid, $row->{recommendation_id},
        );
        $dbh->do(
            q{INSERT INTO plugin_ajsn_promo_audit
              (campaign_id,actor_borrowernumber,action_type,entity_type,entity_id,details_json)
              VALUES (?,?,'impact_suggestion_submitted','suggestion',?,?)},
            undef, $campaign_id, $actor, $suggestion->suggestionid,
            encode_json( { biblionumber => 0 + $biblionumber,
                quantity => 0 + $row->{recommended_quantity} } ),
        );
        $dbh->commit;
        1;
    };
    unless ($ok) {
        eval { $dbh->rollback };
        warn "Book Display Impact suggestion submission failed: $@";
        return $self->_book_display_impact_screen( {
            error_message => 'Koha could not create the purchase suggestion. No duplicate submission was recorded.'
        } );
    }
    return $self->_book_display_impact_screen( {
        success_message => sprintf(
            'Koha purchase suggestion %d was created successfully.',
            $suggestion->suggestionid
        )
    } );
}

sub _reports_screen {
    my ($self) = @_;
    $self->_ensure_schema;
    my $cgi = $self->{cgi};
    my $dbh = C4::Context->dbh;
    my $campaigns = $dbh->selectall_arrayref(
        q{SELECT campaign_id,name,start_date,end_date,status
            FROM plugin_ajsn_promo_campaigns
           WHERE deleted_at IS NULL AND start_date IS NOT NULL
           ORDER BY campaign_id DESC},
        { Slice => {} },
    ) || [];
    my $filters = _report_filters($cgi);
    my %selected_report_campaigns =
      map { 0 + $_ => 1 } @{ $filters->{campaign_ids} || [] };
    for my $campaign ( @{$campaigns} ) {
        $campaign->{selected} =
          $selected_report_campaigns{ 0 + $campaign->{campaign_id} } ? 1 : 0;
    }
    my $campaign_ids = _filtered_campaign_ids( $campaigns, $filters );

    my ( $portfolio, %comparisons, $error_message );
    if ( @{$campaign_ids} ) {
        my $service =
          Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
            { dbh => $dbh }
          );
        my $ok = eval {
            $portfolio = $service->portfolio_metrics($campaign_ids);
            for my $result ( @{ $portfolio->{campaign_results} || [] } ) {
                _prepare_analytics_for_display($result);
            }
            for my $dimension (qw(campaign_type channel location language_code target_audience)) {
                $comparisons{$dimension} =
                  $service->comparison_metrics( $dimension, $campaign_ids );
            }
            1;
        };
        unless ($ok) {
            warn "Promotion & Engagement reports failed: $@";
            $error_message = 'Reports could not be calculated.';
        }
    }

    my $location_rows = $comparisons{location}
      ? $comparisons{location}->{rows} : [];
    my $portfolio_utilization_display =
      $portfolio && defined $portfolio->{title_utilization_rate}
      ? sprintf( '%.1f', $portfolio->{title_utilization_rate} )
      : undef;
    my $template = $self->get_template( { file => 'reports.tt' } );
    $template->param(
        campaign_count => scalar @{$campaign_ids},
        portfolio      => $portfolio,
        portfolio_utilization_display => $portfolio_utilization_display,
        type_rows      => $comparisons{campaign_type}
          ? $comparisons{campaign_type}->{rows} : [],
        channel_rows   => $comparisons{channel}
          ? $comparisons{channel}->{rows} : [],
        location_rows  => $location_rows,
        language_rows  => $comparisons{language_code}
          ? $comparisons{language_code}->{rows} : [],
        audience_rows  => $comparisons{target_audience}
          ? $comparisons{target_audience}->{rows} : [],
        campaigns      => $campaigns,
        selected_campaign_id => $filters->{campaign_id},
        selected_campaign_ids => $filters->{campaign_ids} || [],
        selected_status => $filters->{status},
        date_from      => $filters->{date_from},
        date_to        => $filters->{date_to},
        filter_query   => _report_filter_query($filters),
        leading_location => _leading_location($location_rows),
        error_message  => $error_message,
    );
    return $self->output_html( $template->output() );
}

sub _report_export {
    my ($self) = @_;
    $self->_ensure_schema;
    my $cgi = $self->{cgi};
    my $format = lc _trim( scalar $cgi->param('format') || 'csv' );
    my $dimension = _trim( scalar $cgi->param('dimension') || 'channel' );
    my %allowed = map { $_ => 1 }
      qw(campaign_type channel location language_code target_audience);
    $dimension = 'channel' unless $allowed{$dimension};
    $format = 'csv' unless $format eq 'json';

    my $dbh = C4::Context->dbh;
    my $campaigns = $dbh->selectall_arrayref(
        q{SELECT campaign_id,name,start_date,end_date,status
            FROM plugin_ajsn_promo_campaigns
           WHERE deleted_at IS NULL AND start_date IS NOT NULL
           ORDER BY campaign_id DESC},
        { Slice => {} },
    ) || [];
    my $campaign_ids = _filtered_campaign_ids(
        $campaigns, _report_filters($cgi)
    );
    my $rows = [];
    if ( @{$campaign_ids} ) {
        my $service =
          Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
            { dbh => $dbh }
          );
        $rows = $service->comparison_metrics( $dimension, $campaign_ids )->{rows};
    }

    if ( $format eq 'json' ) {
        print $cgi->header(
            -type       => 'application/json',
            -attachment => "promotion-$dimension-report.json",
            -charset    => 'UTF-8',
        );
        print encode_json(
            {
                spec_version => $Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics::SPEC_VERSION,
                dimension    => $dimension,
                rows         => $rows,
            }
        );
        return;
    }

    print $cgi->header(
        -type       => 'text/csv',
        -attachment => "promotion-$dimension-report.csv",
        -charset    => 'UTF-8',
    );
    my @csv_columns = qw(
      code label campaign_count eligible_item_count promoted_title_count
      titles_used_count title_utilization_rate baseline_checkout_count
      checkout_count checkout_change_percent zero_response_title_count
      titles_increased_count
    );
    push @csv_columns, qw(exclusive_checkout_count exclusive_campaign_count)
      if $dimension eq 'location';
    push @csv_columns, 'multi_location_campaign_count';

    print join( q{,}, @csv_columns ), "\n";
    for my $row ( @{$rows} ) {
        print join(
            q{,},
            map { _csv_value( $row->{$_} ) } @csv_columns
        ), "\n";
    }
    return;
}

sub _report_filters {
    my ($cgi) = @_;
    my @raw_campaign_ids = (
        $cgi->multi_param('campaign_ids'),
        $cgi->multi_param('campaign_id'),
    );
    my %seen_campaign_id;
    my @campaign_ids = grep {
        /^\d+$/ && $_ > 0 && !$seen_campaign_id{$_}++
    } map { _trim($_) } @raw_campaign_ids;

    my $status = _trim( scalar $cgi->param('status') );
    my $date_from = _trim( scalar $cgi->param('date_from') );
    my $date_to = _trim( scalar $cgi->param('date_to') );
    $status = q{} unless $status =~ /^(?:draft|active|completed)$/;
    $date_from = q{} unless $date_from =~ /^\d{4}-\d{2}-\d{2}$/;
    $date_to = q{} unless $date_to =~ /^\d{4}-\d{2}-\d{2}$/;
    return {
        campaign_ids => \@campaign_ids,
        campaign_id  => @campaign_ids == 1 ? $campaign_ids[0] : q{},
        status       => $status,
        date_from    => $date_from,
        date_to      => $date_to,
    };
}

sub _filtered_campaign_ids {
    my ( $campaigns, $filters ) = @_;
    my %selected_campaigns =
      map { 0 + $_ => 1 } @{ $filters->{campaign_ids} || [] };

    return [
        map { 0 + $_->{campaign_id} }
        grep {
            ( !%selected_campaigns
                || $selected_campaigns{ 0 + $_->{campaign_id} } )
              && ( !$filters->{status}
                || ( $_->{status} || q{} ) eq $filters->{status} )
              && ( !$filters->{date_from}
                || ( $_->{end_date} || $_->{start_date} ) ge $filters->{date_from} )
              && ( !$filters->{date_to}
                || $_->{start_date} le $filters->{date_to} )
        } @{ $campaigns || [] }
    ];
}

sub _report_filter_query {
    my ($filters) = @_;
    my @pairs;
    push @pairs, map { 'campaign_ids=' . $_ }
      @{ $filters->{campaign_ids} || [] };
    for my $key (qw(status date_from date_to)) {
        my $value = $filters->{$key} || q{};
        push @pairs, $key . q{=} . $value if length $value;
    }
    return join q{&}, @pairs;
}

sub _leading_location {
    my ($rows) = @_;
    my @eligible = grep {
        lc( $_->{code} || q{} ) ne 'unassigned'
          && ( $_->{exclusive_campaign_count} || 0 ) > 0
          && ( $_->{exclusive_checkout_count} || 0 ) > 0
    } @{ $rows || [] };
    @eligible = sort {
        $b->{exclusive_checkout_count} <=> $a->{exclusive_checkout_count}
          || lc( $a->{label} ) cmp lc( $b->{label} )
    } @eligible;
    return $eligible[0];
}

sub _csv_value {
    my ($value) = @_;
    $value = q{} unless defined $value;
    $value =~ s/"/""/g;
    return qq{"$value"};
}

sub _promotions_screen {
    my ( $self, $args ) = @_;
    $args ||= {};
    $self->_ensure_schema;

    my $dbh = C4::Context->dbh;
    my $query = _trim( scalar $self->{cgi}->param('q') );
    my $status_filter = _trim( scalar $self->{cgi}->param('status') );
    my %filter_statuses = map { $_ => 1 } qw(draft active completed);
    $status_filter = q{} unless $filter_statuses{$status_filter};

    my %seen_selected;
    my @selected_campaign_ids = grep {
        /^\d+$/ && $_ > 0 && !$seen_selected{$_}++
    } map { _trim($_) } $self->{cgi}->multi_param('campaign_ids');
    my %selected_campaigns = map { 0 + $_ => 1 } @selected_campaign_ids;

    my $campaign_choices = $dbh->selectall_arrayref(
        q{
            SELECT campaign_id, name, start_date, status
              FROM plugin_ajsn_promo_campaigns
             WHERE deleted_at IS NULL
             ORDER BY start_date DESC, campaign_id DESC
             LIMIT 2000
        },
        { Slice => {} },
    ) || [];
    for my $choice ( @{$campaign_choices} ) {
        $choice->{selected} =
          $selected_campaigns{ 0 + $choice->{campaign_id} } ? 1 : 0;
    }

    my $selected_clause = @selected_campaign_ids
      ? ' AND c.campaign_id IN (' .
        join( q{,}, (q{?}) x @selected_campaign_ids ) . ')'
      : q{};

    my $campaigns = $dbh->selectall_arrayref(
        qq{
            SELECT c.campaign_id, c.campaign_uuid, c.campaign_type, c.channel,
                   c.name, c.start_date, c.end_date, c.branchcode,
                   c.target_audience, c.language_code, c.display_location,
                   c.status, c.created_at, c.updated_at,
                   COALESCE(vt.label, c.campaign_type) AS campaign_type_label,
                   COALESCE(vc.label, c.channel) AS channel_label,
                   (
                       SELECT GROUP_CONCAT(vl.label ORDER BY vl.sort_order, vl.label SEPARATOR ' · ')
                         FROM plugin_ajsn_promo_campaign_locations cl
                         JOIN plugin_ajsn_promo_vocab_values vl
                           ON vl.vocab_value_id = cl.location_value_id
                        WHERE cl.campaign_id = c.campaign_id
                          AND cl.deleted_at IS NULL
                          AND vl.deleted_at IS NULL
                   ) AS location_labels,
                   COUNT(pi.campaign_item_id) AS linked_item_count
              FROM plugin_ajsn_promo_campaigns c
              LEFT JOIN plugin_ajsn_promo_items pi
                ON pi.campaign_id = c.campaign_id
               AND pi.deleted_at IS NULL
              LEFT JOIN plugin_ajsn_promo_vocab_values vt
                ON vt.dimension = 'campaign_type'
               AND vt.value_code = c.campaign_type
               AND vt.deleted_at IS NULL
              LEFT JOIN plugin_ajsn_promo_vocab_values vc
                ON vc.dimension = 'channel'
               AND vc.value_code = c.channel
               AND vc.deleted_at IS NULL
             WHERE c.deleted_at IS NULL
               AND (? = '' OR c.name LIKE ? OR c.notes LIKE ?)
               AND (? = '' OR c.status = ?)
               $selected_clause
             GROUP BY c.campaign_id, c.campaign_uuid, c.campaign_type, c.channel,
                      c.name, c.start_date, c.end_date, c.branchcode,
                      c.target_audience, c.language_code, c.display_location,
                      c.status, c.created_at, c.updated_at, vt.label, vc.label
             ORDER BY c.campaign_id DESC
             LIMIT 200
        },
        { Slice => {} },
        $query,
        '%' . $query . '%',
        '%' . $query . '%',
        $status_filter,
        $status_filter,
        @selected_campaign_ids,
    );

    my $analytics_service =
      Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
        { dbh => $dbh }
      );
    for my $campaign ( @{ $campaigns || [] } ) {
        next unless $campaign->{start_date};
        if ( !( $campaign->{linked_item_count} || 0 ) ) {
            $campaign->{promoted_title_count} = 0;
            $campaign->{titles_used_count} = 0;
            $campaign->{campaign_checkout_count} = 0;
            $campaign->{analytics_available} = 1;
            next;
        }
        my $analytics;
        my $ok = eval {
            $analytics = _prepare_analytics_for_display(
                $analytics_service->campaign_metrics( $campaign->{campaign_id} )
            );
            1;
        };
        next unless $ok && $analytics;
        $campaign->{promoted_title_count} = $analytics->{promoted_title_count};
        $campaign->{titles_used_count} = $analytics->{titles_used_count};
        $campaign->{titles_used_display} = $analytics->{titles_used_display};
        $campaign->{campaign_checkout_count} =
          $analytics->{during_checkout_count};
        $campaign->{campaign_checkout_display} =
          $analytics->{campaign_checkout_display};
        $campaign->{title_utilization_display} =
          $analytics->{title_utilization_display};
        $campaign->{uplift_display} = $analytics->{uplift_display};
        $campaign->{new_response} = $analytics->{new_response};
        $campaign->{impact_provisional} =
          $analytics->{impact_evidence}->{provisional} ? 1 : 0;
        $campaign->{analytics_available} = 1;
    }

    my @visible_measurable_ids = map { 0 + $_->{campaign_id} }
      grep { $_->{start_date} } @{ $campaigns || [] };
    my $promotions_portfolio;
    if (@visible_measurable_ids) {
        eval {
            $promotions_portfolio =
              $analytics_service->portfolio_metrics(\@visible_measurable_ids);
            1;
        } or warn "Promotion portfolio summary failed: $@";
    }
    my $promotions_utilization_display =
      $promotions_portfolio
      && defined $promotions_portfolio->{title_utilization_rate}
      ? sprintf( '%.1f', $promotions_portfolio->{title_utilization_rate} )
      : undef;
    my $filtered_active_count =
      scalar grep { ( $_->{status} || q{} ) eq 'active' } @{ $campaigns || [] };

    my $template = $self->get_template( { file => 'promotions.tt' } );
    $template->param(
        plugin_version  => $VERSION,
        campaigns       => $campaigns || [],
        campaign_choices => $campaign_choices || [],
        selected_campaign_ids => \@selected_campaign_ids,
        selected_campaign_count => scalar @selected_campaign_ids,
        promotions_portfolio => $promotions_portfolio,
        promotions_utilization_display => $promotions_utilization_display,
        filtered_active_count => $filtered_active_count,
        search_query    => $query,
        status_filter   => $status_filter,
        error_message   => $args->{error_message},
        success_message => $args->{success_message},
    );
    return $self->output_html( $template->output() );
}

sub _promotion_detail_screen {
    my ( $self, $args ) = @_;
    $args ||= {};
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

    my ($type_label) = $dbh->selectrow_array(
        q{SELECT label FROM plugin_ajsn_promo_vocab_values
           WHERE dimension = 'campaign_type' AND value_code = ? AND deleted_at IS NULL},
        undef, $campaign->{campaign_type},
    );
    my ($channel_label) = $dbh->selectrow_array(
        q{SELECT label FROM plugin_ajsn_promo_vocab_values
           WHERE dimension = 'channel' AND value_code = ? AND deleted_at IS NULL},
        undef, $campaign->{channel},
    );
    $campaign->{campaign_type_label} = $type_label || $campaign->{campaign_type};
    $campaign->{channel_label} = $channel_label || $campaign->{channel};

    my $campaign_locations = $dbh->selectall_arrayref(
        q{
            SELECT vl.vocab_value_id, vl.value_code, vl.label
              FROM plugin_ajsn_promo_campaign_locations cl
              JOIN plugin_ajsn_promo_vocab_values vl
                ON vl.vocab_value_id = cl.location_value_id
             WHERE cl.campaign_id = ?
               AND cl.deleted_at IS NULL
               AND vl.deleted_at IS NULL
             ORDER BY vl.sort_order, vl.label
        },
        { Slice => {} },
        $campaign_id,
    );

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

    my $analytics;
    if ( $campaign->{start_date} ) {
        eval {
            $analytics = _prepare_analytics_for_display(
                Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
                    { dbh => $dbh }
                )->campaign_metrics($campaign_id)
            );
            1;
        } or do {
            warn "Promotion detail analytics failed for campaign $campaign_id: $@";
            $analytics = undef;
        };
    }

    my $template = $self->get_template( { file => 'promotion_detail.tt' } );
    $template->param(
        plugin_version  => $VERSION,
        campaign        => $campaign,
        analytics       => $analytics,
        linked_items       => $linked_items || [],
        campaign_locations => $campaign_locations || [],
        audit_rows         => $audit_rows || [],
        success_message => $args->{success_message},
    );
    return $self->output_html( $template->output() );
}

sub _new_promotion_screen {
    my ( $self, $args ) = @_;
    $args ||= {};
    $self->_ensure_schema;

    my $dbh  = C4::Context->dbh;
    my $form = $args->{form} || {};

    my @libraries;
    my $libraries_rs = Koha::Libraries->search( {}, { order_by => 'branchname' } );
    while ( my $library = $libraries_rs->next ) {
        push @libraries,
          {
            branchcode => $library->branchcode,
            branchname => $library->branchname,
          };
    }

    my $campaign_types = $dbh->selectall_arrayref(
        q{
            SELECT value_code, label
              FROM plugin_ajsn_promo_vocab_values
             WHERE dimension = 'campaign_type'
               AND is_active = 1
               AND deleted_at IS NULL
             ORDER BY sort_order, label
        },
        { Slice => {} },
    );
    my $channels = $dbh->selectall_arrayref(
        q{
            SELECT value_code, label
              FROM plugin_ajsn_promo_vocab_values
             WHERE dimension = 'channel'
               AND is_active = 1
               AND deleted_at IS NULL
             ORDER BY sort_order, label
        },
        { Slice => {} },
    );
    my $languages = $dbh->selectall_arrayref(
        q{
            SELECT value_code, label
              FROM plugin_ajsn_promo_vocab_values
             WHERE dimension = 'language'
               AND is_active = 1
               AND deleted_at IS NULL
             ORDER BY sort_order, label
        },
        { Slice => {} },
    );
    my $audiences = $dbh->selectall_arrayref(
        q{
            SELECT value_code, label
              FROM plugin_ajsn_promo_vocab_values
             WHERE dimension = 'audience'
               AND is_active = 1
               AND deleted_at IS NULL
             ORDER BY sort_order, label
        },
        { Slice => {} },
    );
    my $locations = $dbh->selectall_arrayref(
        q{
            SELECT vocab_value_id, value_code, label, is_active
              FROM plugin_ajsn_promo_vocab_values
             WHERE dimension = 'location'
               AND is_active = 1
               AND deleted_at IS NULL
             ORDER BY sort_order, label
        },
        { Slice => {} },
    );
    my %selected_location_ids =
      map { $_ => 1 } @{ $form->{location_value_ids} || [] };
    for my $location ( @{ $locations || [] } ) {
        $location->{selected} = $selected_location_ids{ $location->{vocab_value_id} } ? 1 : 0;
    }

    my $template = $self->get_template( { file => 'new_promotion.tt' } );
    $template->param(
        plugin_version     => $VERSION,
        libraries          => \@libraries,
        campaign_types     => $campaign_types || [],
        channels           => $channels || [],
        languages          => $languages || [],
        audiences          => $audiences || [],
        locations          => $locations || [],
        form               => $form,
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
    $self->_ensure_schema;
    my $dbh = C4::Context->dbh;

    my %seen_location_ids;
    my @location_value_ids =
      grep { !$seen_location_ids{$_}++ }
      grep { /^\d+$/ && $_ > 0 }
      map { _trim($_) } $cgi->multi_param('location_value_id');

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
        location_value_ids => \@location_value_ids,
        notes            => _trim( scalar $cgi->param('notes') ),
        status           => _trim( scalar $cgi->param('status') ) || 'draft',
        barcodes_text    => scalar( $cgi->param('barcodes') // q{} ),
    );

    my @errors;
    my @warnings;

    my %allowed_statuses = map { $_ => 1 } qw(draft active completed);

    my ($valid_type) = $dbh->selectrow_array(
        q{SELECT COUNT(*) FROM plugin_ajsn_promo_vocab_values
           WHERE dimension = 'campaign_type' AND value_code = ?
             AND is_active = 1 AND deleted_at IS NULL},
        undef, $form{campaign_type},
    );
    my ($valid_channel) = $dbh->selectrow_array(
        q{SELECT COUNT(*) FROM plugin_ajsn_promo_vocab_values
           WHERE dimension = 'channel' AND value_code = ?
             AND is_active = 1 AND deleted_at IS NULL},
        undef, $form{channel},
    );

    push @errors, 'Select a valid promotion type.' unless $valid_type;
    push @errors, 'Select a valid channel.' unless $valid_channel;
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
    push @errors, 'Select a valid status.' unless $allowed_statuses{ $form{status} };

    my @locations;
    for my $location_id (@location_value_ids) {
        my $location = $dbh->selectrow_hashref(
            q{
                SELECT vocab_value_id, value_code, label
                  FROM plugin_ajsn_promo_vocab_values
                 WHERE vocab_value_id = ?
                   AND dimension = 'location'
                   AND is_active = 1
                   AND deleted_at IS NULL
            },
            undef,
            $location_id,
        );
        if ($location) {
            push @locations, $location;
        } else {
            push @errors, 'One or more selected campaign locations are invalid or disabled.';
            last;
        }
    }
    $form{display_location} = join '; ', map { $_->{label} } @locations;

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

        my $location_sth = $dbh->prepare(q{
            INSERT INTO plugin_ajsn_promo_campaign_locations
                (campaign_id, location_value_id, added_by)
            VALUES (?, ?, ?)
        });
        for my $location (@locations) {
            $location_sth->execute(
                $campaign_id,
                $location->{vocab_value_id},
                $actor,
            );
        }

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
                location_value_ids => [ map { $_->{vocab_value_id} } @locations ],
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


sub _edit_promotion_screen {
    my ( $self, $args ) = @_;
    $args ||= {};
    $self->_ensure_schema;

    my $cgi = $self->{cgi};
    my $campaign_id = _trim(
        defined $args->{campaign_id}
        ? $args->{campaign_id}
        : scalar $cgi->param('campaign_id')
    );

    unless ( $campaign_id =~ /^\d+$/ && $campaign_id > 0 ) {
        return $self->_promotions_screen(
            { error_message => 'Select a valid campaign to edit.' }
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

    my $form = $args->{form};
    unless ($form) {
        $form = { %{$campaign} };
        my $barcodes = $dbh->selectcol_arrayref(
            q{
                SELECT barcode
                  FROM plugin_ajsn_promo_items
                 WHERE campaign_id = ?
                   AND deleted_at IS NULL
                 ORDER BY campaign_item_id
            },
            undef,
            $campaign_id,
        );
        $form->{barcodes_text} = join "\n", grep { defined && length } @{ $barcodes || [] };
    }
    $form->{campaign_id} = $campaign_id;

    my $selected_location_ids = $form->{location_value_ids};
    unless ($selected_location_ids) {
        $selected_location_ids = $dbh->selectcol_arrayref(
            q{
                SELECT location_value_id
                  FROM plugin_ajsn_promo_campaign_locations
                 WHERE campaign_id = ?
                   AND deleted_at IS NULL
            },
            undef,
            $campaign_id,
        );
        $form->{location_value_ids} = $selected_location_ids || [];
    }

    my @libraries;
    my $libraries_rs = Koha::Libraries->search( {}, { order_by => 'branchname' } );
    while ( my $library = $libraries_rs->next ) {
        push @libraries,
          {
            branchcode => $library->branchcode,
            branchname => $library->branchname,
          };
    }

    my $campaign_types = $dbh->selectall_arrayref(
        q{
            SELECT value_code, label, is_active
              FROM plugin_ajsn_promo_vocab_values
             WHERE dimension = 'campaign_type'
               AND deleted_at IS NULL
               AND (is_active = 1 OR value_code = ?)
             ORDER BY sort_order, label
        },
        { Slice => {} },
        $campaign->{campaign_type},
    );
    my $channels = $dbh->selectall_arrayref(
        q{
            SELECT value_code, label, is_active
              FROM plugin_ajsn_promo_vocab_values
             WHERE dimension = 'channel'
               AND deleted_at IS NULL
               AND (is_active = 1 OR value_code = ?)
             ORDER BY sort_order, label
        },
        { Slice => {} },
        $campaign->{channel},
    );
    my $languages = $dbh->selectall_arrayref(
        q{
            SELECT value_code, label, is_active
              FROM plugin_ajsn_promo_vocab_values
             WHERE dimension = 'language'
               AND deleted_at IS NULL
               AND (is_active = 1 OR value_code = ? OR label = ?)
             ORDER BY sort_order, label
        },
        { Slice => {} },
        $campaign->{language_code},
        $campaign->{language_code},
    );
    my $audiences = $dbh->selectall_arrayref(
        q{
            SELECT value_code, label, is_active
              FROM plugin_ajsn_promo_vocab_values
             WHERE dimension = 'audience'
               AND deleted_at IS NULL
               AND (is_active = 1 OR value_code = ? OR label = ?)
             ORDER BY sort_order, label
        },
        { Slice => {} },
        $campaign->{target_audience},
        $campaign->{target_audience},
    );

    my ( $language_match, $audience_match ) = ( 0, 0 );
    for my $language ( @{ $languages || [] } ) {
        $language->{selected} =
          length( $form->{language_code} || q{} )
          && ( $form->{language_code} eq $language->{value_code}
            || $form->{language_code} eq $language->{label} ) ? 1 : 0;
        $language_match = 1 if $language->{selected};
    }
    for my $audience ( @{ $audiences || [] } ) {
        $audience->{selected} =
          length( $form->{target_audience} || q{} )
          && ( $form->{target_audience} eq $audience->{value_code}
            || $form->{target_audience} eq $audience->{label} ) ? 1 : 0;
        $audience_match = 1 if $audience->{selected};
    }
    my $legacy_language =
      !$language_match ? ( $form->{language_code} || q{} ) : q{};
    my $legacy_audience =
      !$audience_match ? ( $form->{target_audience} || q{} ) : q{};

    my $locations = $dbh->selectall_arrayref(
        q{
            SELECT vocab_value_id, value_code, label, is_active
              FROM plugin_ajsn_promo_vocab_values
             WHERE dimension = 'location'
               AND deleted_at IS NULL
             ORDER BY sort_order, label
        },
        { Slice => {} },
    );
    my %selected_location_ids = map { $_ => 1 } @{ $form->{location_value_ids} || [] };
    for my $location ( @{ $locations || [] } ) {
        $location->{selected} = $selected_location_ids{ $location->{vocab_value_id} } ? 1 : 0;
    }

    my $template = $self->get_template( { file => 'edit_promotion.tt' } );
    $template->param(
        plugin_version     => $VERSION,
        campaign           => $campaign,
        libraries          => \@libraries,
        campaign_types     => $campaign_types || [],
        channels           => $channels || [],
        languages          => $languages || [],
        audiences          => $audiences || [],
        legacy_language    => $legacy_language,
        legacy_audience    => $legacy_audience,
        locations          => $locations || [],
        form               => $form,
        errors             => $args->{errors} || [],
        warnings           => $args->{warnings} || [],
        invalid_barcodes   => $args->{invalid_barcodes} || [],
        duplicate_barcodes => $args->{duplicate_barcodes} || [],
        valid_item_count   => $args->{valid_item_count} || 0,
    );
    return $self->output_html( $template->output() );
}

sub _update_promotion {
    my ($self) = @_;
    my $cgi = $self->{cgi};
    $self->_ensure_schema;

    my $campaign_id = _trim( scalar $cgi->param('campaign_id') );
    unless ( $campaign_id =~ /^\d+$/ && $campaign_id > 0 ) {
        return $self->_promotions_screen(
            { error_message => 'Select a valid campaign to update.' }
        );
    }

    my $dbh = C4::Context->dbh;
    my $existing = $dbh->selectrow_hashref(
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

    unless ($existing) {
        return $self->_promotions_screen(
            { error_message => 'The requested campaign does not exist or is no longer available.' }
        );
    }

    my %seen_location_ids;
    my @location_value_ids =
      grep { !$seen_location_ids{$_}++ }
      grep { /^\d+$/ && $_ > 0 }
      map { _trim($_) } $cgi->multi_param('location_value_id');

    my %form = (
        campaign_id      => $campaign_id,
        campaign_type    => _trim( scalar $cgi->param('campaign_type') ),
        channel          => _trim( scalar $cgi->param('channel') ),
        name             => _trim( scalar $cgi->param('name') ),
        start_date       => _trim( scalar $cgi->param('start_date') ),
        end_date         => _trim( scalar $cgi->param('end_date') ),
        branchcode       => _trim( scalar $cgi->param('branchcode') ),
        target_audience  => _trim( scalar $cgi->param('target_audience') ),
        language_code    => _trim( scalar $cgi->param('language_code') ),
        display_location => _trim( scalar $cgi->param('display_location') ),
        location_value_ids => \@location_value_ids,
        notes            => _trim( scalar $cgi->param('notes') ),
        status           => _trim( scalar $cgi->param('status') ) || 'draft',
        barcodes_text    => scalar( $cgi->param('barcodes') // q{} ),
    );

    warn "PE_DEBUG display_location=[" . ($form{display_location} // q{undef}) . "]\n";

    my @errors;
    my @warnings;

    my %allowed_statuses = map { $_ => 1 } qw(draft active completed);

    my ($valid_type) = $dbh->selectrow_array(
        q{SELECT COUNT(*) FROM plugin_ajsn_promo_vocab_values
           WHERE dimension = 'campaign_type' AND value_code = ?
             AND deleted_at IS NULL AND (is_active = 1 OR value_code = ?)},
        undef, $form{campaign_type}, $existing->{campaign_type},
    );
    my ($valid_channel) = $dbh->selectrow_array(
        q{SELECT COUNT(*) FROM plugin_ajsn_promo_vocab_values
           WHERE dimension = 'channel' AND value_code = ?
             AND deleted_at IS NULL AND (is_active = 1 OR value_code = ?)},
        undef, $form{channel}, $existing->{channel},
    );

    push @errors, 'Select a valid promotion type.' unless $valid_type;
    push @errors, 'Select a valid channel.' unless $valid_channel;
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
    push @errors, 'Select a valid status.' unless $allowed_statuses{ $form{status} };

    my $existing_location_rows = $dbh->selectall_arrayref(
        q{
            SELECT campaign_location_id, location_value_id, deleted_at
              FROM plugin_ajsn_promo_campaign_locations
             WHERE campaign_id = ?
        },
        { Slice => {} },
        $campaign_id,
    );
    my %existing_active_location_ids =
      map { $_->{location_value_id} => 1 }
      grep { !defined $_->{deleted_at} } @{ $existing_location_rows || [] };

    my @locations;
    for my $location_id (@location_value_ids) {
        my $location = $dbh->selectrow_hashref(
            q{
                SELECT vocab_value_id, value_code, label, is_active
                  FROM plugin_ajsn_promo_vocab_values
                 WHERE vocab_value_id = ?
                   AND dimension = 'location'
                   AND deleted_at IS NULL
            },
            undef,
            $location_id,
        );
        if ( $location && ( $location->{is_active} || $existing_active_location_ids{$location_id} ) ) {
            push @locations, $location;
        } else {
            push @errors, 'One or more selected campaign locations are invalid or disabled.';
            last;
        }
    }

    if (@locations) {
        $form{display_location} = join '; ', map { $_->{label} } @locations;
    } elsif ( keys %existing_active_location_ids ) {
        $form{display_location} = q{};
    } else {
        $form{display_location} = length( $form{display_location} )
          ? $form{display_location}
          : ( $existing->{display_location} // q{} );
    }

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
          'No changes were saved because one or more barcodes do not exist in Koha. Correct or remove the invalid barcodes and submit again.';
    }
    if (@duplicate_barcodes) {
        push @warnings,
          'Duplicate barcode entries were detected. Each duplicate is ignored and each Koha item can be linked only once per campaign.';
    }

    if (@errors) {
        return $self->_edit_promotion_screen(
            {
                campaign_id        => $campaign_id,
                form               => \%form,
                errors             => \@errors,
                warnings           => \@warnings,
                invalid_barcodes   => \@invalid_barcodes,
                duplicate_barcodes => \@duplicate_barcodes,
                valid_item_count   => scalar @items,
            }
        );
    }

    my $actor = C4::Context->userenv ? C4::Context->userenv->{number} : undef;

    my @tracked_fields = qw(
      campaign_type channel name start_date end_date branchcode target_audience
      language_code display_location notes status
    );
    my @changed_fields;
    for my $field (@tracked_fields) {
        my $before = defined $existing->{$field} ? $existing->{$field} : q{};
        my $after  = defined $form{$field}       ? $form{$field}       : q{};
        push @changed_fields, $field if $before ne $after;
    }

    my $existing_item_rows = $dbh->selectall_arrayref(
        q{
            SELECT campaign_item_id, itemnumber, barcode, deleted_at
              FROM plugin_ajsn_promo_items
             WHERE campaign_id = ?
        },
        { Slice => {} },
        $campaign_id,
    );
    my %existing_by_item = map { $_->{itemnumber} => $_ } @{ $existing_item_rows || [] };
    my %desired_by_item  = map { $_->{itemnumber} => $_ } @items;

    my @added_itemnumbers;
    my @removed_itemnumbers;

    my %existing_by_location =
      map { $_->{location_value_id} => $_ } @{ $existing_location_rows || [] };
    my %desired_by_location =
      map { $_->{vocab_value_id} => $_ } @locations;
    my @added_location_ids;
    my @removed_location_ids;

    my $ok = eval {
        local $dbh->{RaiseError} = 1;
        $dbh->begin_work;

        $dbh->do(
            q{
                UPDATE plugin_ajsn_promo_campaigns
                   SET campaign_type = ?, channel = ?, name = ?, start_date = ?,
                       end_date = ?, branchcode = ?, target_audience = ?,
                       language_code = ?, display_location = ?, notes = ?, status = ?
                 WHERE campaign_id = ?
                   AND deleted_at IS NULL
            },
            undef,
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
            $campaign_id,
        );

        for my $row ( @{ $existing_location_rows || [] } ) {
            my $location_id = $row->{location_value_id};
            if ( $desired_by_location{$location_id} ) {
                if ( defined $row->{deleted_at} ) {
                    $dbh->do(
                        q{
                            UPDATE plugin_ajsn_promo_campaign_locations
                               SET added_by = ?, added_at = NOW(), deleted_at = NULL
                             WHERE campaign_location_id = ?
                        },
                        undef,
                        $actor,
                        $row->{campaign_location_id},
                    );
                    push @added_location_ids, $location_id;
                }
            } elsif ( !defined $row->{deleted_at} ) {
                $dbh->do(
                    q{
                        UPDATE plugin_ajsn_promo_campaign_locations
                           SET deleted_at = NOW()
                         WHERE campaign_location_id = ?
                    },
                    undef,
                    $row->{campaign_location_id},
                );
                push @removed_location_ids, $location_id;
            }
        }

        my $location_sth = $dbh->prepare(q{
            INSERT INTO plugin_ajsn_promo_campaign_locations
                (campaign_id, location_value_id, added_by)
            VALUES (?, ?, ?)
        });
        for my $location (@locations) {
            next if $existing_by_location{ $location->{vocab_value_id} };
            $location_sth->execute(
                $campaign_id,
                $location->{vocab_value_id},
                $actor,
            );
            push @added_location_ids, $location->{vocab_value_id};
        }

        for my $row ( @{ $existing_item_rows || [] } ) {
            my $itemnumber = $row->{itemnumber};
            if ( $desired_by_item{$itemnumber} ) {
                if ( defined $row->{deleted_at} ) {
                    my $item = $desired_by_item{$itemnumber};
                    $dbh->do(
                        q{
                            UPDATE plugin_ajsn_promo_items
                               SET barcode = ?, added_by = ?, added_at = NOW(), deleted_at = NULL
                             WHERE campaign_item_id = ?
                        },
                        undef,
                        $item->{barcode},
                        $actor,
                        $row->{campaign_item_id},
                    );
                    push @added_itemnumbers, $itemnumber;
                }
            } elsif ( !defined $row->{deleted_at} ) {
                $dbh->do(
                    q{
                        UPDATE plugin_ajsn_promo_items
                           SET deleted_at = NOW()
                         WHERE campaign_item_id = ?
                    },
                    undef,
                    $row->{campaign_item_id},
                );
                push @removed_itemnumbers, $itemnumber;
            }
        }

        my $item_sth = $dbh->prepare(q{
            INSERT INTO plugin_ajsn_promo_items
                (campaign_id, itemnumber, barcode, added_by)
            VALUES (?, ?, ?, ?)
        });
        for my $item (@items) {
            next if $existing_by_item{ $item->{itemnumber} };
            $item_sth->execute(
                $campaign_id,
                $item->{itemnumber},
                $item->{barcode},
                $actor,
            );
            push @added_itemnumbers, $item->{itemnumber};
        }

        my $details = encode_json(
            {
                campaign_uuid      => $existing->{campaign_uuid},
                changed_fields     => \@changed_fields,
                status_before      => $existing->{status},
                status_after       => $form{status},
                added_itemnumbers  => \@added_itemnumbers,
                removed_itemnumbers => \@removed_itemnumbers,
                added_location_ids => \@added_location_ids,
                removed_location_ids => \@removed_location_ids,
                item_count         => scalar @items,
                location_count     => scalar @locations,
            }
        );

        $dbh->do(
            q{
                INSERT INTO plugin_ajsn_promo_audit
                    (campaign_id, actor_borrowernumber, action_type, entity_type,
                     entity_id, details_json)
                VALUES (?, ?, 'campaign_updated', 'campaign', ?, ?)
            },
            undef,
            $campaign_id,
            $actor,
            $existing->{campaign_uuid},
            $details,
        );

        if ( ( $existing->{status} // q{} ) ne ( $form{status} // q{} ) ) {
            my $status_details = encode_json(
                {
                    from => $existing->{status},
                    to   => $form{status},
                }
            );
            $dbh->do(
                q{
                    INSERT INTO plugin_ajsn_promo_audit
                        (campaign_id, actor_borrowernumber, action_type, entity_type,
                         entity_id, details_json)
                    VALUES (?, ?, 'campaign_status_changed', 'campaign', ?, ?)
                },
                undef,
                $campaign_id,
                $actor,
                $existing->{campaign_uuid},
                $status_details,
            );
        }

        $dbh->commit;
        1;
    };

    if ( !$ok ) {
        my $error = $@ || 'Unknown database error';
        eval { $dbh->rollback };
        warn "Promotion & Engagement campaign update failed: $error";
        push @errors, 'The campaign could not be updated because of a database error. No partial changes were kept.';
        return $self->_edit_promotion_screen(
            {
                campaign_id        => $campaign_id,
                form               => \%form,
                errors             => \@errors,
                warnings           => \@warnings,
                duplicate_barcodes => \@duplicate_barcodes,
                valid_item_count   => scalar @items,
            }
        );
    }

    return $self->_promotion_detail_screen(
        {
            success_message => sprintf( 'Campaign "%s" was updated successfully.', $form{name} ),
        }
    );
}

sub _archive_promotion {
    my ($self) = @_;
    my $cgi = $self->{cgi};
    $self->_ensure_schema;

    my $campaign_id = _trim( scalar $cgi->param('campaign_id') );
    my $confirmed   = _trim( scalar $cgi->param('archive_confirm') );

    unless ( $campaign_id =~ /^\d+$/ && $campaign_id > 0 && $confirmed eq '1' ) {
        return $self->_promotions_screen(
            { error_message => 'The campaign was not archived because the archive request was invalid or unconfirmed.' }
        );
    }

    my $dbh = C4::Context->dbh;
    my $campaign = $dbh->selectrow_hashref(
        q{
            SELECT campaign_id, campaign_uuid, name, status
              FROM plugin_ajsn_promo_campaigns
             WHERE campaign_id = ?
               AND deleted_at IS NULL
        },
        undef,
        $campaign_id,
    );

    unless ($campaign) {
        return $self->_promotions_screen(
            { error_message => 'The requested campaign does not exist or is already archived.' }
        );
    }

    my $actor = C4::Context->userenv ? C4::Context->userenv->{number} : undef;
    my $ok = eval {
        local $dbh->{RaiseError} = 1;
        $dbh->begin_work;

        my $rows = $dbh->do(
            q{
                UPDATE plugin_ajsn_promo_campaigns
                   SET deleted_at = NOW()
                 WHERE campaign_id = ?
                   AND deleted_at IS NULL
            },
            undef,
            $campaign_id,
        );
        die 'Campaign was not archived' unless $rows && $rows > 0;

        my ($active_item_count) = $dbh->selectrow_array(
            q{
                SELECT COUNT(*)
                  FROM plugin_ajsn_promo_items
                 WHERE campaign_id = ?
                   AND deleted_at IS NULL
            },
            undef,
            $campaign_id,
        );

        $dbh->do(
            q{
                UPDATE plugin_ajsn_promo_items
                   SET deleted_at = NOW()
                 WHERE campaign_id = ?
                   AND deleted_at IS NULL
            },
            undef,
            $campaign_id,
        );

        $dbh->do(
            q{
                UPDATE plugin_ajsn_promo_campaign_locations
                   SET deleted_at = NOW()
                 WHERE campaign_id = ?
                   AND deleted_at IS NULL
            },
            undef,
            $campaign_id,
        );

        my $details = encode_json(
            {
                campaign_uuid  => $campaign->{campaign_uuid},
                name           => $campaign->{name},
                status         => $campaign->{status},
                archived_items => $active_item_count || 0,
            }
        );
        $dbh->do(
            q{
                INSERT INTO plugin_ajsn_promo_audit
                    (campaign_id, actor_borrowernumber, action_type, entity_type,
                     entity_id, details_json)
                VALUES (?, ?, 'campaign_archived', 'campaign', ?, ?)
            },
            undef,
            $campaign_id,
            $actor,
            $campaign->{campaign_uuid},
            $details,
        );

        $dbh->commit;
        1;
    };

    if ( !$ok ) {
        my $error = $@ || 'Unknown database error';
        eval { $dbh->rollback };
        warn "Promotion & Engagement campaign archive failed: $error";
        return $self->_promotions_screen(
            {
                error_message => 'The campaign could not be archived because of a database error. No partial archive was kept.',
            }
        );
    }

    return $self->_promotions_screen(
        {
            success_message => sprintf( 'Campaign "%s" was archived successfully.', $campaign->{name} ),
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

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS plugin_ajsn_promo_vocab_values (
            vocab_value_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            dimension VARCHAR(40) NOT NULL,
            value_code VARCHAR(80) NOT NULL,
            label VARCHAR(255) NOT NULL,
            sort_order INT NOT NULL DEFAULT 100,
            is_active TINYINT(1) NOT NULL DEFAULT 1,
            created_by INT NULL,
            updated_by INT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            deleted_at DATETIME NULL,
            PRIMARY KEY (vocab_value_id),
            UNIQUE KEY uq_promo_vocab_dimension_code (dimension, value_code),
            KEY idx_promo_vocab_dimension_active_sort (dimension, is_active, sort_order)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    });

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS plugin_ajsn_promo_campaign_locations (
            campaign_location_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            campaign_id BIGINT UNSIGNED NOT NULL,
            location_value_id BIGINT UNSIGNED NOT NULL,
            added_by INT NULL,
            added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            deleted_at DATETIME NULL,
            PRIMARY KEY (campaign_location_id),
            UNIQUE KEY uq_promo_campaign_location (campaign_id, location_value_id),
            KEY idx_promo_location_value (location_value_id),
            CONSTRAINT fk_ajsn_promo_campaign_location_campaign
                FOREIGN KEY (campaign_id)
                REFERENCES plugin_ajsn_promo_campaigns (campaign_id)
                ON DELETE CASCADE,
            CONSTRAINT fk_ajsn_promo_campaign_location_value
                FOREIGN KEY (location_value_id)
                REFERENCES plugin_ajsn_promo_vocab_values (vocab_value_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    });

    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS plugin_ajsn_promo_recommendations (
            recommendation_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            campaign_id BIGINT UNSIGNED NOT NULL,
            biblionumber INT NOT NULL,
            decision_status VARCHAR(20) NOT NULL DEFAULT 'candidate',
            recommended_quantity SMALLINT UNSIGNED NOT NULL DEFAULT 1,
            reviewer_note TEXT NULL,
            evidence_json LONGTEXT NULL,
            decided_by INT NULL,
            decided_at DATETIME NULL,
            koha_suggestion_id INT NULL,
            submitted_at DATETIME NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (recommendation_id),
            UNIQUE KEY uq_promo_recommendation_campaign_biblio
                (campaign_id,biblionumber),
            KEY idx_promo_recommendation_status (decision_status),
            KEY idx_promo_recommendation_suggestion (koha_suggestion_id),
            CONSTRAINT fk_ajsn_promo_recommendation_campaign
                FOREIGN KEY (campaign_id)
                REFERENCES plugin_ajsn_promo_campaigns (campaign_id)
                ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    });

    unless ( _column_exists( $dbh, 'plugin_ajsn_promo_recommendations', 'evidence_json' ) ) {
        $dbh->do(q{
            ALTER TABLE plugin_ajsn_promo_recommendations
            ADD COLUMN evidence_json LONGTEXT NULL AFTER reviewer_note
        });
    }

    _seed_default_vocab_values($dbh);

    return 1;
}


sub _seed_default_vocab_values {
    my ($dbh) = @_;

    my @defaults = (
        [ campaign_type => subject_display     => 'Subject / thematic display', 10 ],
        [ campaign_type => new_arrivals        => 'New arrivals',               20 ],
        [ campaign_type => recommendation      => 'Recommendation campaign',    30 ],
        [ campaign_type => email_campaign      => 'Email campaign',             40 ],
        [ campaign_type => digital_signage     => 'Digital signage',            50 ],
        [ campaign_type => physical_signage    => 'Physical signage',           60 ],
        [ campaign_type => resource_feature    => 'Resource feature',           70 ],
        [ campaign_type => author_feature      => 'Author feature',             80 ],
        [ campaign_type => publication_feature => 'Publication feature',        90 ],
        [ campaign_type => event               => 'Event',                     100 ],
        [ campaign_type => outreach            => 'Outreach',                  110 ],
        [ campaign_type => other               => 'Other',                     120 ],
        [ channel       => physical_display    => 'Physical display',           10 ],
        [ channel       => email               => 'Email',                      20 ],
        [ channel       => digital_signage     => 'Digital signage',            30 ],
        [ channel       => print_signage       => 'Print signage',              40 ],
        [ channel       => web                 => 'Web',                        50 ],
        [ channel       => social              => 'Social',                     60 ],
        [ channel       => event               => 'Event',                      70 ],
        [ channel       => other               => 'Other',                      80 ],
    );

    my $sth = $dbh->prepare(q{
        INSERT IGNORE INTO plugin_ajsn_promo_vocab_values
            (dimension, value_code, label, sort_order, is_active)
        VALUES (?, ?, ?, ?, 1)
    });
    for my $row (@defaults) {
        $sth->execute( @{$row} );
    }

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