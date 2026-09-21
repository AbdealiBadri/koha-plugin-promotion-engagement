package Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics;

use Modern::Perl;
use DateTime;

our $SPEC_VERSION = '1.1.0';
our @AFTER_WINDOWS = ( 7, 14, 30, 60 );

sub new {
    my ( $class, $args ) = @_;
    die 'dbh is required' unless $args && $args->{dbh};
    return bless { dbh => $args->{dbh} }, $class;
}

sub campaign_metrics {
    my ( $self, $campaign_id, $args ) = @_;
    $args ||= {};
    die 'campaign_id must be a positive integer'
      unless defined $campaign_id && $campaign_id =~ /^\d+$/ && $campaign_id > 0;

    my $campaign = $self->{dbh}->selectrow_hashref(
        q{
            SELECT campaign_id, campaign_uuid, name, start_date, end_date,
                   campaign_type, channel, branchcode, target_audience,
                   language_code, status, deleted_at
              FROM plugin_ajsn_promo_campaigns
             WHERE campaign_id = ?
        },
        undef,
        $campaign_id,
    );
    die 'Campaign not found' unless $campaign;
    die 'Archived campaign requires historical authorization'
      if $campaign->{deleted_at} && !$args->{include_archived};
    die 'Campaign start date is required' unless $campaign->{start_date};

    my $as_of_date =
      $args->{as_of_date} && $args->{as_of_date} =~ /^\d{4}-\d{2}-\d{2}$/
      ? $args->{as_of_date}
      : DateTime->now( time_zone => 'floating' )->strftime('%F');
    my $analysis_period = _analysis_period( $campaign, $as_of_date );
    my $windows = _resolve_windows(
        $campaign->{start_date},
        $analysis_period->{effective_end_date},
    );
    _annotate_window_states( $windows, $as_of_date );

    my $items = $self->_eligible_items( $campaign_id, $windows->{during} );
    my @itemnumbers = sort { $a <=> $b } keys %{$items};
    my $events = @itemnumbers
      ? $self->_checkout_events(
        \@itemnumbers,
        $windows->{baseline}->{start},
        $windows->{after_60}->{end},
      )
      : [];

    my %metrics;
    for my $window_name (qw(baseline during after_7 after_14 after_30 after_60)) {
        $metrics{$window_name} =
          $windows->{$window_name}->{state} eq 'pending'
          ? _pending_window_metrics( scalar @itemnumbers )
          : _window_metrics(
                $events,
                $windows->{$window_name},
                scalar @itemnumbers,
            );
    }

    my $baseline_rate = $metrics{baseline}->{daily_checkout_rate};
    my $during_rate   = $metrics{during}->{daily_checkout_rate};
    my $absolute_delta =
      defined $baseline_rate && defined $during_rate
      ? _round( $during_rate - $baseline_rate )
      : undef;
    my $uplift_percent =
      !defined $absolute_delta || !$baseline_rate
      ? undef
      : _round( ( $absolute_delta / $baseline_rate ) * 100 );

    my $first_checkout = _first_checkout_on_or_after(
        $events,
        $windows->{during}->{start_epoch},
        $windows->{after_60}->{end_epoch},
    );
    my $days_to_first = defined $first_checkout
      ? _round( ( $first_checkout - $windows->{during}->{start_epoch} ) / 86_400 )
      : undef;
    my $impact_evidence = _impact_evidence(
        $metrics{baseline},
        $metrics{during},
        scalar @itemnumbers,
        $windows->{during},
    );
    my $item_response_rows = $self->_item_response_rows(
        \@itemnumbers,
        $events,
        $windows,
    );
    my $title_response_rows = $self->_title_response_rows(
        \@itemnumbers,
        $events,
        $windows,
    );
    my $title_summary = _title_summary( $title_response_rows, $windows->{during}->{state} );

    my @warnings;
    push @warnings, $analysis_period->{warning}
      if $analysis_period->{warning};

    return {
        spec_version           => $SPEC_VERSION,
        campaign               => $campaign,
        analysis_period        => $analysis_period,
        windows                => $windows,
        eligible_item_count    => scalar @itemnumbers,
        eligible_itemnumbers   => \@itemnumbers,
        promoted_title_count   => $title_summary->{promoted_title_count},
        titles_used_count      => $title_summary->{titles_used_count},
        title_utilization_rate => $title_summary->{title_utilization_rate},
        titles_increased_count => $title_summary->{titles_increased_count},
        zero_response_title_count => $title_summary->{zero_response_title_count},
        repeat_demand_title_count => $title_summary->{repeat_demand_title_count},
        metrics                => \%metrics,
        absolute_rate_delta    => $absolute_delta,
        uplift_percent         => $uplift_percent,
        days_to_first_checkout => $days_to_first,
        impact_evidence        => $impact_evidence,
        item_response_rows     => $item_response_rows,
        title_response_rows    => $title_response_rows,
        multi_attributed_issue_count => 0,
        data_quality_warnings  => \@warnings,
        calculated_at          => DateTime->now( time_zone => 'floating' )->strftime('%F %T'),
    };
}

sub _analysis_period {
    my ( $campaign, $as_of_date ) = @_;
    my $start = _date_start( $campaign->{start_date} );
    my $as_of = _date_start($as_of_date);
    my $status = lc( $campaign->{status} || q{} );
    my $configured_end = $campaign->{end_date};
    my $effective_end;
    my $live_to_date = 0;
    my $warning;

    if ( $status eq 'active' && DateTime->compare( $start, $as_of ) <= 0 ) {
        if ($configured_end) {
            my $planned_end = _date_start($configured_end);
            if ( DateTime->compare( $planned_end, $as_of ) < 0 ) {
                $effective_end = $planned_end;
                $warning =
                  'Campaign status is active although its configured end date has passed.';
            } else {
                $effective_end = $as_of;
                $live_to_date = 1;
            }
        } else {
            $effective_end = $as_of;
            $live_to_date = 1;
        }
    } else {
        $effective_end = $configured_end
          ? _date_start($configured_end)
          : $start->clone;
        if ( $status eq 'completed' && !$configured_end ) {
            $warning =
              'Completed campaign has no end date; analytics use the start date as its only measured day.';
        }
    }

    die 'Campaign end date cannot be before start date'
      if DateTime->compare( $effective_end, $start ) < 0;

    return {
        as_of_date          => $as_of_date,
        configured_end_date => $configured_end,
        effective_end_date  => $effective_end->strftime('%F'),
        live_to_date        => $live_to_date,
        warning             => $warning,
    };
}

sub _annotate_window_states {
    my ( $windows, $as_of_date ) = @_;
    my $as_of_start = _date_start($as_of_date);
    my $as_of_end = $as_of_start->clone->add( days => 1 );
    my $as_of_epoch = $as_of_end->epoch;

    for my $name ( keys %{$windows} ) {
        my $window = $windows->{$name};
        if ( $as_of_epoch <= $window->{start_epoch} ) {
            $window->{state} = 'pending';
            $window->{available} = 0;
            $window->{partial} = 0;
        } elsif ( $as_of_epoch >= $window->{end_epoch} ) {
            $window->{state} = 'complete';
            $window->{available} = 1;
            $window->{partial} = 0;
        } else {
            $window->{state} = 'partial';
            $window->{available} = 1;
            $window->{partial} = 1;
        }
    }
    return $windows;
}

sub _pending_window_metrics {
    my ($eligible_item_count) = @_;
    return {
        checkout_count           => undef,
        unique_items_checked_out => undef,
        unique_borrower_count    => undef,
        eligible_item_count      => 0 + $eligible_item_count,
        conversion_rate          => undef,
        daily_checkout_rate      => undef,
    };
}

sub _impact_evidence {
    my ( $baseline, $during, $eligible_count, $during_window ) = @_;

    return {
        code    => 'no_items',
        label   => 'No promoted items to measure',
        tone    => 'default',
        finding => 'Link Koha items to this campaign before circulation impact can be measured.',
        provisional => 0,
    } unless $eligible_count;

    return {
        code    => 'scheduled',
        label   => 'Awaiting campaign activity',
        tone    => 'info',
        finding => 'This promotion has not started. Baseline data may be available, but impact cannot yet be assessed.',
        provisional => 1,
    } if ( $during_window->{state} || q{} ) eq 'pending';

    my $provisional =
      ( $during_window->{state} || q{} ) eq 'partial' ? 1 : 0;
    my $baseline_rate = $baseline->{daily_checkout_rate} || 0;
    my $during_rate   = $during->{daily_checkout_rate} || 0;
    my ( $code, $label, $tone, $finding );

    if ( !$during->{checkout_count} ) {
        ( $code, $label, $tone, $finding ) = (
            'no_response',
            'No circulation response recorded',
            'default',
            'No promoted item checkout has been recorded during the measured promotion period.',
        );
    } elsif ( !$baseline->{checkout_count} && $during->{checkout_count} ) {
        ( $code, $label, $tone, $finding ) = (
            'new_response',
            'New circulation response',
            'success',
            'Promoted items with no baseline checkout activity were borrowed during the measured promotion period.',
        );
    } elsif ( $during_rate > $baseline_rate ) {
        ( $code, $label, $tone, $finding ) = (
            'positive',
            'Positive circulation response',
            'success',
            'The promoted collection is circulating faster during the promotion than in the comparable baseline period.',
        );
    } elsif ( $during_rate < $baseline_rate ) {
        ( $code, $label, $tone, $finding ) = (
            'lower',
            'Circulation below baseline',
            'warning',
            'The promoted collection is circulating more slowly during the promotion than in the comparable baseline period.',
        );
    } else {
        ( $code, $label, $tone, $finding ) = (
            'unchanged',
            'No measured circulation change',
            'info',
            'The promoted collection is circulating at the same daily rate as the comparable baseline period.',
        );
    }

    return {
        code        => $code,
        label       => $label,
        tone        => $tone,
        finding     => $finding,
        provisional => $provisional,
    };
}

sub _item_response_rows {
    my ( $self, $itemnumbers, $events, $windows ) = @_;
    return [] unless @{$itemnumbers};

    my $placeholders = join q{,}, (q{?}) x @{$itemnumbers};
    my $metadata = $self->{dbh}->selectall_arrayref(
        qq{
            SELECT i.itemnumber, i.barcode, b.title, b.author
              FROM items i
              JOIN biblio b ON b.biblionumber = i.biblionumber
             WHERE i.itemnumber IN ($placeholders)
        },
        { Slice => {} },
        @{$itemnumbers},
    ) || [];
    my %metadata = map { $_->{itemnumber} => $_ } @{$metadata};

    my %counts;
    for my $event ( @{$events} ) {
        my $itemnumber = $event->{itemnumber};
        if ( $event->{issuedate_epoch} >= $windows->{baseline}->{start_epoch}
            && $event->{issuedate_epoch} < $windows->{baseline}->{end_epoch} ) {
            $counts{$itemnumber}->{baseline}++;
        }
        if ( $event->{issuedate_epoch} >= $windows->{during}->{start_epoch}
            && $event->{issuedate_epoch} < $windows->{during}->{end_epoch} ) {
            $counts{$itemnumber}->{during}++;
        }
        if ( $event->{issuedate_epoch} >= $windows->{after_60}->{start_epoch}
            && $event->{issuedate_epoch} < $windows->{after_60}->{end_epoch} ) {
            $counts{$itemnumber}->{after}++;
        }
    }

    return [
        map {
            my $itemnumber = $_;
            my $baseline = $counts{$itemnumber}->{baseline} || 0;
            my $during   = $counts{$itemnumber}->{during} || 0;
            my $response =
                $during > $baseline ? 'Increased'
              : $during < $baseline ? 'Lower'
              : $during             ? 'Unchanged'
              :                       'No checkout';
            {
                itemnumber       => $itemnumber,
                barcode          => $metadata{$itemnumber}->{barcode} || q{},
                title            => $metadata{$itemnumber}->{title} || "Item $itemnumber",
                author           => $metadata{$itemnumber}->{author} || q{},
                baseline_count   => $baseline,
                during_count     => $during,
                after_60_count   => $counts{$itemnumber}->{after} || 0,
                response_label   => $response,
            }
        } @{$itemnumbers}
    ];
}

sub _title_response_rows {
    my ( $self, $itemnumbers, $events, $windows ) = @_;
    return [] unless @{$itemnumbers};

    my $placeholders = join q{,}, (q{?}) x @{$itemnumbers};
    my $metadata = $self->{dbh}->selectall_arrayref(
        qq{
            SELECT i.itemnumber, i.biblionumber, i.barcode, b.title, b.author
              FROM items i
              JOIN biblio b ON b.biblionumber = i.biblionumber
             WHERE i.itemnumber IN ($placeholders)
        },
        { Slice => {} },
        @{$itemnumbers},
    ) || [];

    my %meta_by_item = map { $_->{itemnumber} => $_ } @{$metadata};
    my %titles;
    for my $meta ( @{$metadata} ) {
        my $row = $titles{ $meta->{biblionumber} } ||= {
            biblionumber     => 0 + $meta->{biblionumber},
            title            => $meta->{title} || 'Untitled',
            author           => $meta->{author} || q{},
            promoted_copies  => 0,
            barcodes         => [],
            baseline_count   => 0,
            during_count     => 0,
            after_60_count   => 0,
        };
        $row->{promoted_copies}++;
        push @{ $row->{barcodes} }, $meta->{barcode}
          if defined $meta->{barcode} && length $meta->{barcode};
    }

    for my $event ( @{$events} ) {
        my $meta = $meta_by_item{ $event->{itemnumber} } || next;
        my $row = $titles{ $meta->{biblionumber} } || next;
        if ( $event->{issuedate_epoch} >= $windows->{baseline}->{start_epoch}
            && $event->{issuedate_epoch} < $windows->{baseline}->{end_epoch} ) {
            $row->{baseline_count}++;
        }
        if ( $event->{issuedate_epoch} >= $windows->{during}->{start_epoch}
            && $event->{issuedate_epoch} < $windows->{during}->{end_epoch} ) {
            $row->{during_count}++;
        }
        if ( $event->{issuedate_epoch} >= $windows->{after_60}->{start_epoch}
            && $event->{issuedate_epoch} < $windows->{after_60}->{end_epoch} ) {
            $row->{after_60_count}++;
        }
    }

    return [
        map {
            my $row = $titles{$_};
            my $baseline = $row->{baseline_count} || 0;
            my $during = $row->{during_count} || 0;
            $row->{response_label} =
                $during > $baseline ? 'Increased'
              : $during < $baseline ? 'Lower'
              : $during             ? 'Unchanged'
              :                       'No checkout';
            $row->{during_state} = $windows->{during}->{state};
            $row->{after_60_state} = $windows->{after_60}->{state};
            $row;
        } sort { $a <=> $b } keys %titles
    ];
}

sub _title_summary {
    my ( $rows, $during_state ) = @_;
    my $promoted = scalar @{ $rows || [] };
    return {
        promoted_title_count      => 0,
        titles_used_count         => 0,
        title_utilization_rate    => undef,
        titles_increased_count    => 0,
        zero_response_title_count => 0,
        repeat_demand_title_count => 0,
    } unless $promoted;

    if ( ( $during_state || q{} ) eq 'pending' ) {
        return {
            promoted_title_count      => $promoted,
            titles_used_count         => undef,
            title_utilization_rate    => undef,
            titles_increased_count    => undef,
            zero_response_title_count => undef,
            repeat_demand_title_count => undef,
        };
    }

    my $used = scalar grep { ( $_->{during_count} || 0 ) > 0 } @{$rows};
    my $increased = scalar grep {
        ( $_->{response_label} || q{} ) eq 'Increased'
    } @{$rows};
    my $zero = scalar grep { !( $_->{during_count} || 0 ) } @{$rows};
    my $repeat = scalar grep { ( $_->{during_count} || 0 ) >= 2 } @{$rows};

    return {
        promoted_title_count      => $promoted,
        titles_used_count         => $used,
        title_utilization_rate    => _round( ( $used / $promoted ) * 100 ),
        titles_increased_count    => $increased,
        zero_response_title_count => $zero,
        repeat_demand_title_count => $repeat,
    };
}

sub portfolio_metrics {
    my ( $self, $campaign_ids, $args ) = @_;
    $args ||= {};
    die 'campaign_ids must be a non-empty array'
      unless ref $campaign_ids eq 'ARRAY' && @{$campaign_ids};

    my @campaigns = map {
        $self->campaign_metrics(
            $_,
            {
                include_archived => $args->{include_archived} ? 1 : 0,
                ( $args->{as_of_date} ? ( as_of_date => $args->{as_of_date} ) : () ),
            }
        )
    } @{$campaign_ids};

    my ( %all_items, %all_titles, %increased_titles, @definitions );
    for my $result (@campaigns) {
        my %eligible = map { $_ => 1 } @{ $result->{eligible_itemnumbers} };
        $all_items{$_} = 1 for keys %eligible;
        for my $title ( @{ $result->{title_response_rows} || [] } ) {
            $all_titles{ $title->{biblionumber} } = 1;
            $increased_titles{ $title->{biblionumber} } = 1
              if ( $title->{response_label} || q{} ) eq 'Increased';
        }
        push @definitions, {
            campaign_id          => $result->{campaign}->{campaign_id},
            eligible             => \%eligible,
            baseline_start_epoch => $result->{windows}->{baseline}->{start_epoch},
            baseline_end_epoch   => $result->{windows}->{baseline}->{end_epoch},
            during_start_epoch   => $result->{windows}->{during}->{start_epoch},
            during_end_epoch     => $result->{windows}->{during}->{end_epoch},
            followup_end_epoch   => $result->{windows}->{after_60}->{end_epoch},
        };
    }

    my @itemnumbers = sort { $a <=> $b } keys %all_items;
    my %item_to_biblio;
    if (@itemnumbers) {
        my $placeholders = join q{,}, (q{?}) x @itemnumbers;
        my $item_rows = $self->{dbh}->selectall_arrayref(
            qq{SELECT itemnumber,biblionumber FROM items
                WHERE itemnumber IN ($placeholders)},
            { Slice => {} },
            @itemnumbers,
        ) || [];
        %item_to_biblio =
          map { $_->{itemnumber} => $_->{biblionumber} } @{$item_rows};
    }

    my @starts = sort { $a <=> $b }
      map { $_->{baseline_start_epoch} } @definitions;
    my @ends = sort { $a <=> $b }
      map { $_->{followup_end_epoch} } @definitions;
    my $events = @itemnumbers
      ? $self->_checkout_events(
            \@itemnumbers,
            _epoch_datetime( $starts[0] ),
            _epoch_datetime( $ends[-1] ),
        )
      : [];

    my (
        %portfolio_issues,
        %campaign_issues,
        %baseline_issues,
        %used_titles,
        %during_title_counts,
        %campaign_borrowers,
        %attribution_count
    );
    for my $event ( @{$events} ) {
        my @followup_matching = grep {
               $_->{eligible}->{ $event->{itemnumber} }
            && $event->{issuedate_epoch} >= $_->{during_start_epoch}
            && $event->{issuedate_epoch} < $_->{followup_end_epoch}
        } @definitions;
        if (@followup_matching) {
            $portfolio_issues{ $event->{issue_id} } = 1;
            $attribution_count{ $event->{issue_id} } =
              scalar @followup_matching;
        }

        my @during_matching = grep {
               $_->{eligible}->{ $event->{itemnumber} }
            && $event->{issuedate_epoch} >= $_->{during_start_epoch}
            && $event->{issuedate_epoch} < $_->{during_end_epoch}
        } @definitions;
        if (@during_matching) {
            $campaign_issues{ $event->{issue_id} } = 1;
            $campaign_borrowers{ $event->{borrowernumber} } = 1
              if defined $event->{borrowernumber};
            my $biblionumber = $item_to_biblio{ $event->{itemnumber} };
            if (defined $biblionumber) {
                $used_titles{$biblionumber} = 1;
                $during_title_counts{$biblionumber}++;
            }
        }

        my @baseline_matching = grep {
               $_->{eligible}->{ $event->{itemnumber} }
            && $event->{issuedate_epoch} >= $_->{baseline_start_epoch}
            && $event->{issuedate_epoch} < $_->{baseline_end_epoch}
        } @definitions;
        $baseline_issues{ $event->{issue_id} } = 1
          if @baseline_matching;
    }

    my $multi_count = scalar grep { $_ > 1 } values %attribution_count;
    for my $result (@campaigns) {
        my $campaign_id = $result->{campaign}->{campaign_id};
        my $count = 0;
        my ($definition) =
          grep { $_->{campaign_id} == $campaign_id } @definitions;
        for my $event ( @{$events} ) {
            next unless $attribution_count{ $event->{issue_id} }
              && $attribution_count{ $event->{issue_id} } > 1;
            next unless $definition->{eligible}->{ $event->{itemnumber} };
            next unless
                 $event->{issuedate_epoch} >= $definition->{during_start_epoch}
              && $event->{issuedate_epoch} < $definition->{followup_end_epoch};
            $count++;
        }
        $result->{multi_attributed_issue_count} = $count;
    }

    my $promoted_title_count = scalar keys %all_titles;
    my $titles_used_count = scalar keys %used_titles;
    my $zero_response_title_count =
      $promoted_title_count - $titles_used_count;
    my $repeat_demand_title_count =
      scalar grep { $_ >= 2 } values %during_title_counts;

    return {
        spec_version                    => $SPEC_VERSION,
        campaign_count                 => scalar @campaigns,
        campaign_results               => \@campaigns,
        promoted_item_count            => scalar @itemnumbers,
        promoted_title_count           => $promoted_title_count,
        titles_used_count              => $titles_used_count,
        title_utilization_rate         => $promoted_title_count
          ? _round( ( $titles_used_count / $promoted_title_count ) * 100 )
          : undef,
        zero_response_title_count      => $zero_response_title_count,
        titles_increased_count         => scalar keys %increased_titles,
        repeat_demand_title_count      => $repeat_demand_title_count,
        portfolio_baseline_checkout_count => scalar keys %baseline_issues,
        portfolio_campaign_checkout_count => scalar keys %campaign_issues,
        portfolio_unique_borrower_count   => scalar keys %campaign_borrowers,
        portfolio_checkout_count       => scalar keys %portfolio_issues,
        multi_attributed_issue_count   => $multi_count,
        calculated_at                  => DateTime->now( time_zone => 'floating' )->strftime('%F %T'),
    };
}

sub comparison_metrics {
    my ( $self, $dimension, $campaign_ids ) = @_;
    my %allowed = map { $_ => 1 }
      qw(campaign_type channel language_code target_audience location);
    die 'Unsupported comparison dimension' unless $allowed{$dimension};
    die 'campaign_ids must be a non-empty array'
      unless ref $campaign_ids eq 'ARRAY' && @{$campaign_ids};

    my %groups;
    for my $campaign_id ( @{$campaign_ids} ) {
        my $result = $self->campaign_metrics($campaign_id);
        my @values;
        if ( $dimension eq 'location' ) {
            @values = @{ $self->{dbh}->selectall_arrayref(
                q{
                    SELECT v.value_code AS code, v.label
                      FROM plugin_ajsn_promo_campaign_locations cl
                      JOIN plugin_ajsn_promo_vocab_values v
                        ON v.vocab_value_id = cl.location_value_id
                     WHERE cl.campaign_id = ?
                       AND cl.deleted_at IS NULL
                       AND v.deleted_at IS NULL
                     ORDER BY v.sort_order, v.label
                },
                { Slice => {} },
                $campaign_id,
            ) || [] };
            @values = ( { code => 'unassigned', label => 'Unassigned' } )
              unless @values;
        } else {
            my $code = $result->{campaign}->{$dimension};
            $code = 'unassigned' unless defined $code && length $code;
            my $vocab_dimension =
                $dimension eq 'language_code'   ? 'language'
              : $dimension eq 'target_audience' ? 'audience'
              : $dimension;
            my ($label) = $self->{dbh}->selectrow_array(
                q{
                    SELECT label
                      FROM plugin_ajsn_promo_vocab_values
                     WHERE dimension = ?
                       AND value_code = ?
                       AND deleted_at IS NULL
                },
                undef,
                $vocab_dimension,
                $code,
            );
            @values = ( { code => $code, label => $label || $code } );
        }

        my $events = $result->{eligible_item_count}
          && ( $result->{windows}->{during}->{state} || q{} ) ne 'pending'
          ? $self->_checkout_events(
                $result->{eligible_itemnumbers},
                $result->{windows}->{during}->{start},
                $result->{windows}->{during}->{end},
            )
          : [];
        my $baseline_events = $result->{eligible_item_count}
          ? $self->_checkout_events(
                $result->{eligible_itemnumbers},
                $result->{windows}->{baseline}->{start},
                $result->{windows}->{baseline}->{end},
            )
          : [];
        for my $value (@values) {
            my $group = $groups{ $value->{code} } ||= {
                code             => $value->{code},
                label            => $value->{label},
                campaign_ids     => {},
                eligible_items   => {},
                promoted_titles  => {},
                used_titles      => {},
                increased_titles => {},
                checkout_issues  => {},
                baseline_checkout_issues => {},
                exclusive_campaign_ids => {},
                exclusive_checkout_issues => {},
                multi_location_campaign_count => 0,
            };
            $group->{campaign_ids}->{$campaign_id} = 1;
            $group->{eligible_items}->{$_} = 1
              for @{ $result->{eligible_itemnumbers} };
            for my $title ( @{ $result->{title_response_rows} || [] } ) {
                $group->{promoted_titles}->{ $title->{biblionumber} } = 1;
                $group->{used_titles}->{ $title->{biblionumber} } = 1
                  if ( $title->{during_count} || 0 ) > 0;
                $group->{increased_titles}->{ $title->{biblionumber} } = 1
                  if ( $title->{response_label} || q{} ) eq 'Increased';
            }
            $group->{checkout_issues}->{ $_->{issue_id} } = 1 for @{$events};
            $group->{baseline_checkout_issues}->{ $_->{issue_id} } = 1
              for @{$baseline_events};
            if ( $dimension eq 'location' && @values == 1 ) {
                $group->{exclusive_campaign_ids}->{$campaign_id} = 1;
                $group->{exclusive_checkout_issues}->{ $_->{issue_id} } = 1
                  for @{$events};
            }
            $group->{multi_location_campaign_count}++
              if $dimension eq 'location' && @values > 1;
        }
    }

    my @rows = map {
        my $group = $groups{$_};
        my $promoted_titles = scalar keys %{ $group->{promoted_titles} };
        my $used_titles = scalar keys %{ $group->{used_titles} };
        my $baseline_checkouts =
          scalar keys %{ $group->{baseline_checkout_issues} };
        my $campaign_checkouts = scalar keys %{ $group->{checkout_issues} };
        {
            code             => $group->{code},
            label            => $group->{label},
            campaign_count   => scalar keys %{ $group->{campaign_ids} },
            eligible_item_count => scalar keys %{ $group->{eligible_items} },
            promoted_title_count => $promoted_titles,
            titles_used_count => $used_titles,
            title_utilization_rate => $promoted_titles
              ? _round( ( $used_titles / $promoted_titles ) * 100 )
              : undef,
            zero_response_title_count => $promoted_titles - $used_titles,
            titles_increased_count =>
              scalar keys %{ $group->{increased_titles} },
            baseline_checkout_count => $baseline_checkouts,
            checkout_count   => $campaign_checkouts,
            checkout_change_percent => $baseline_checkouts
              ? _round(
                    ( ( $campaign_checkouts - $baseline_checkouts )
                        / $baseline_checkouts ) * 100
                )
              : undef,
            exclusive_campaign_count =>
              scalar keys %{ $group->{exclusive_campaign_ids} },
            exclusive_checkout_count =>
              scalar keys %{ $group->{exclusive_checkout_issues} },
            multi_location_campaign_count =>
              $group->{multi_location_campaign_count},
        }
    } sort { lc($groups{$a}->{label}) cmp lc($groups{$b}->{label}) } keys %groups;

    return {
        spec_version => $SPEC_VERSION,
        dimension    => $dimension,
        rows         => \@rows,
    };
}

sub borrower_category_breakdown {
    my ( $self, $campaign_id, $args ) = @_;
    $args ||= {};
    my $minimum = defined $args->{minimum_cohort}
      ? $args->{minimum_cohort}
      : 5;
    die 'minimum_cohort must be a positive integer'
      unless $minimum =~ /^\d+$/ && $minimum > 0;

    my $result = $self->campaign_metrics($campaign_id);
    return [] unless $result->{eligible_item_count};
    my $events = $self->_checkout_events(
        $result->{eligible_itemnumbers},
        $result->{windows}->{during}->{start},
        $result->{windows}->{after_60}->{end},
    );
    my %borrower_ids = map {
        defined $_->{borrowernumber} ? ( $_->{borrowernumber} => 1 ) : ()
    } @{$events};
    return [] unless keys %borrower_ids;

    my @ids = sort { $a <=> $b } keys %borrower_ids;
    my $placeholders = join q{,}, (q{?}) x @ids;
    my $rows = $self->{dbh}->selectall_arrayref(
        qq{
            SELECT b.borrowernumber, b.categorycode,
                   COALESCE(c.description, b.categorycode) AS category_label
              FROM borrowers b
              LEFT JOIN categories c ON c.categorycode = b.categorycode
             WHERE b.borrowernumber IN ($placeholders)
        },
        { Slice => {} },
        @ids,
    );
    my %borrower_category = map {
        $_->{borrowernumber} => {
            code  => $_->{categorycode},
            label => $_->{category_label},
        }
    } @{ $rows || [] };

    my %groups;
    for my $event ( @{$events} ) {
        my $category = $borrower_category{ $event->{borrowernumber} } || next;
        my $group = $groups{ $category->{code} } ||= {
            category_code  => $category->{code},
            category_label => $category->{label},
            borrowers      => {},
            issues          => {},
        };
        $group->{borrowers}->{ $event->{borrowernumber} } = 1;
        $group->{issues}->{ $event->{issue_id} } = 1;
    }
    my @aggregates = map {
        {
            category_code          => $groups{$_}->{category_code},
            category_label         => $groups{$_}->{category_label},
            unique_borrower_count  => scalar keys %{ $groups{$_}->{borrowers} },
            checkout_count         => scalar keys %{ $groups{$_}->{issues} },
        }
    } sort keys %groups;

    return _apply_privacy_threshold( \@aggregates, $minimum );
}

sub _apply_privacy_threshold {
    my ( $rows, $minimum ) = @_;
    return [
        map {
            my %row = %{$_};
            if ( $row{unique_borrower_count} < $minimum ) {
                $row{suppressed} = 1;
                $row{unique_borrower_count} = undef;
                $row{checkout_count} = undef;
            } else {
                $row{suppressed} = 0;
            }
            \%row;
        } @{$rows}
    ];
}

sub _eligible_items {
    my ( $self, $campaign_id, $during ) = @_;
    my $rows = $self->{dbh}->selectall_arrayref(
        q{
            SELECT itemnumber, added_at, deleted_at
              FROM plugin_ajsn_promo_items
             WHERE campaign_id = ?
               AND added_at < ?
               AND (deleted_at IS NULL OR deleted_at >= ?)
        },
        { Slice => {} },
        $campaign_id,
        $during->{end},
        $during->{start},
    );
    return { map { $_->{itemnumber} => 1 } @{ $rows || [] } };
}
sub _checkout_events {
    my ( $self, $itemnumbers, $range_start, $range_end ) = @_;
    return [] unless @{$itemnumbers};

    my $placeholders = join q{,}, (q{?}) x @{$itemnumbers};
    my $sql = qq{
        SELECT issue_id, itemnumber, borrowernumber, issuedate
          FROM issues
         WHERE itemnumber IN ($placeholders)
           AND issuedate >= ?
           AND issuedate < ?
        UNION ALL
        SELECT issue_id, itemnumber, borrowernumber, issuedate
          FROM old_issues
         WHERE itemnumber IN ($placeholders)
           AND issuedate >= ?
           AND issuedate < ?
    };
    my @bind = (
        @{$itemnumbers}, $range_start, $range_end,
        @{$itemnumbers}, $range_start, $range_end,
    );
    my $rows = $self->{dbh}->selectall_arrayref( $sql, { Slice => {} }, @bind );

    my %seen_issue;
    my @events;
    for my $row ( @{ $rows || [] } ) {
        next unless defined $row->{issue_id};
        next if $seen_issue{ $row->{issue_id} }++;
        my $epoch = _datetime_epoch( $row->{issuedate} );
        next unless defined $epoch;
        push @events, {
            issue_id      => 0 + $row->{issue_id},
            itemnumber    => 0 + $row->{itemnumber},
            borrowernumber => defined $row->{borrowernumber}
              ? 0 + $row->{borrowernumber}
              : undef,
            issuedate     => q{} . $row->{issuedate},
            issuedate_epoch => $epoch,
        };
    }
    return \@events;
}

sub _resolve_windows {
    my ( $start_date, $end_date ) = @_;
    my $start = _date_start($start_date);
    my $end   = _date_start($end_date);
    die 'Campaign end date cannot be before start date'
      if DateTime->compare( $end, $start ) < 0;

    my $end_exclusive = $end->clone->add( days => 1 );
    my $during_days = int(
        ( $end_exclusive->epoch - $start->epoch ) / 86_400
    );
    my $baseline_start = $start->clone->subtract( days => $during_days );
    my %windows = (
        baseline => _window( $baseline_start, $start, $during_days ),
        during   => _window( $start, $end_exclusive, $during_days ),
    );
    for my $days (@AFTER_WINDOWS) {
        my $name = 'after_' . $days;
        $windows{$name} = _window(
            $end_exclusive,
            $end_exclusive->clone->add( days => $days ),
            $days,
        );
    }
    return \%windows;
}

sub _window {
    my ( $start, $end, $days ) = @_;
    return {
        start       => $start->strftime('%F %T'),
        end         => $end->strftime('%F %T'),
        start_epoch => $start->epoch,
        end_epoch   => $end->epoch,
        days        => 0 + $days,
    };
}

sub _window_metrics {
    my ( $events, $window, $eligible_item_count ) = @_;
    my @matching = grep {
           $_->{issuedate_epoch} >= $window->{start_epoch}
        && $_->{issuedate_epoch} < $window->{end_epoch}
    } @{$events};

    my %unique_items = map { $_->{itemnumber} => 1 } @matching;
    my %unique_borrowers = map {
        defined $_->{borrowernumber} ? ( $_->{borrowernumber} => 1 ) : ()
    } @matching;
    my $checkout_count = scalar @matching;
    my $unique_items_checked_out = scalar keys %unique_items;

    return {
        checkout_count           => $checkout_count,
        unique_items_checked_out => $unique_items_checked_out,
        unique_borrower_count    => scalar keys %unique_borrowers,
        eligible_item_count      => 0 + $eligible_item_count,
        conversion_rate          => $eligible_item_count
          ? _round( ( $unique_items_checked_out / $eligible_item_count ) * 100 )
          : undef,
        daily_checkout_rate      => _round( $checkout_count / $window->{days} ),
    };
}
sub _first_checkout_on_or_after {
    my ( $events, $start_epoch, $end_epoch ) = @_;
    my @epochs = sort { $a <=> $b } map { $_->{issuedate_epoch} }
      grep {
             $_->{issuedate_epoch} >= $start_epoch
          && $_->{issuedate_epoch} < $end_epoch
      } @{$events};
    return @epochs ? $epochs[0] : undef;
}

sub _date_start {
    my ($value) = @_;
    my ($year, $month, $day) = ( q{} . $value ) =~ /^(\d{4})-(\d{2})-(\d{2})/
      or die 'Invalid campaign date';
    return DateTime->new(
        year      => $year,
        month     => $month,
        day       => $day,
        hour      => 0,
        minute    => 0,
        second    => 0,
        time_zone => 'floating',
    );
}

sub _datetime_epoch {
    my ($value) = @_;
    return undef unless defined $value;
    my ( $year, $month, $day, $hour, $minute, $second ) =
      ( q{} . $value ) =~ /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})/
      or return undef;
    return DateTime->new(
        year      => $year,
        month     => $month,
        day       => $day,
        hour      => $hour,
        minute    => $minute,
        second    => $second,
        time_zone => 'floating',
    )->epoch;
}

sub _epoch_datetime {
    my ($epoch) = @_;
    return DateTime->from_epoch(
        epoch     => $epoch,
        time_zone => 'floating',
    )->strftime('%F %T');
}

sub _round {
    my ($value) = @_;
    return 0 + sprintf '%.4f', $value;
}

1;
