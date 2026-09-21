package Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics;

use Modern::Perl;
use DateTime;

our $SPEC_VERSION = '1.0.0';
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

    my $windows = _resolve_windows(
        $campaign->{start_date},
        $campaign->{end_date} || $campaign->{start_date},
    );
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
        $metrics{$window_name} = _window_metrics(
            $events,
            $windows->{$window_name},
            scalar @itemnumbers,
        );
    }

    my $baseline_rate = $metrics{baseline}->{daily_checkout_rate};
    my $during_rate   = $metrics{during}->{daily_checkout_rate};
    my $absolute_delta = _round( $during_rate - $baseline_rate );
    my $uplift_percent = $baseline_rate == 0
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

    return {
        spec_version           => $SPEC_VERSION,
        campaign               => $campaign,
        windows                => $windows,
        eligible_item_count    => scalar @itemnumbers,
        eligible_itemnumbers   => \@itemnumbers,
        metrics                => \%metrics,
        absolute_rate_delta    => $absolute_delta,
        uplift_percent         => $uplift_percent,
        days_to_first_checkout => $days_to_first,
        impact_evidence        => $impact_evidence,
        item_response_rows     => $item_response_rows,
        multi_attributed_issue_count => 0,
        data_quality_warnings  => [],
        calculated_at          => DateTime->now( time_zone => 'floating' )->strftime('%F %T'),
    };
}

sub _impact_evidence {
    my ( $baseline, $during, $eligible_count, $during_window ) = @_;
    my $now_epoch = DateTime->now( time_zone => 'floating' )->epoch;

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
        finding => 'This display has not started. Baseline data is available, but impact cannot yet be assessed.',
        provisional => 1,
    } if $now_epoch < $during_window->{start_epoch};

    my $provisional = $now_epoch < $during_window->{end_epoch} ? 1 : 0;
    my $baseline_rate = $baseline->{daily_checkout_rate} || 0;
    my $during_rate   = $during->{daily_checkout_rate} || 0;
    my ( $code, $label, $tone, $finding );

    if ( !$during->{checkout_count} ) {
        ( $code, $label, $tone, $finding ) = (
            'no_response',
            'No circulation response recorded',
            'default',
            'No promoted item checkout has been recorded during the display period.',
        );
    } elsif ( !$baseline->{checkout_count} && $during->{checkout_count} ) {
        ( $code, $label, $tone, $finding ) = (
            'new_response',
            'New circulation response',
            'success',
            'Promoted items with no baseline checkout activity were borrowed during the display.',
        );
    } elsif ( $during_rate > $baseline_rate ) {
        ( $code, $label, $tone, $finding ) = (
            'positive',
            'Positive circulation response',
            'success',
            'The promoted collection is circulating faster during the display than in the comparable baseline period.',
        );
    } elsif ( $during_rate < $baseline_rate ) {
        ( $code, $label, $tone, $finding ) = (
            'lower',
            'Circulation below baseline',
            'warning',
            'The promoted collection is circulating more slowly during the display than in the comparable baseline period.',
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

sub portfolio_metrics {
    my ( $self, $campaign_ids, $args ) = @_;
    $args ||= {};
    die 'campaign_ids must be a non-empty array'
      unless ref $campaign_ids eq 'ARRAY' && @{$campaign_ids};

    my @campaigns = map {
        $self->campaign_metrics(
            $_,
            { include_archived => $args->{include_archived} ? 1 : 0 }
        )
    } @{$campaign_ids};

    my ( %all_items, @definitions );
    for my $result (@campaigns) {
        my %eligible = map { $_ => 1 } @{ $result->{eligible_itemnumbers} };
        $all_items{$_} = 1 for keys %eligible;
        push @definitions, {
            campaign_id => $result->{campaign}->{campaign_id},
            eligible    => \%eligible,
            start_epoch => $result->{windows}->{during}->{start_epoch},
            end_epoch   => $result->{windows}->{after_60}->{end_epoch},
        };
    }

    my @itemnumbers = sort { $a <=> $b } keys %all_items;
    my @starts = sort { $a <=> $b } map { $_->{start_epoch} } @definitions;
    my @ends   = sort { $a <=> $b } map { $_->{end_epoch} } @definitions;
    my $events = @itemnumbers
      ? $self->_checkout_events(
        \@itemnumbers,
        _epoch_datetime( $starts[0] ),
        _epoch_datetime( $ends[-1] ),
      )
      : [];

    my ( %portfolio_issues, %attribution_count );
    for my $event ( @{$events} ) {
        my @matching = grep {
               $_->{eligible}->{ $event->{itemnumber} }
            && $event->{issuedate_epoch} >= $_->{start_epoch}
            && $event->{issuedate_epoch} < $_->{end_epoch}
        } @definitions;
        next unless @matching;
        $portfolio_issues{ $event->{issue_id} } = 1;
        $attribution_count{ $event->{issue_id} } = scalar @matching;
    }

    my $multi_count = scalar grep { $_ > 1 } values %attribution_count;
    for my $result (@campaigns) {
        my $campaign_id = $result->{campaign}->{campaign_id};
        my $count = 0;
        for my $event ( @{$events} ) {
            next unless $attribution_count{ $event->{issue_id} }
              && $attribution_count{ $event->{issue_id} } > 1;
            my ($definition) =
              grep { $_->{campaign_id} == $campaign_id } @definitions;
            next unless $definition->{eligible}->{ $event->{itemnumber} };
            next unless $event->{issuedate_epoch} >= $definition->{start_epoch}
              && $event->{issuedate_epoch} < $definition->{end_epoch};
            $count++;
        }
        $result->{multi_attributed_issue_count} = $count;
    }

    return {
        spec_version                 => $SPEC_VERSION,
        campaign_count              => scalar @campaigns,
        campaign_results            => \@campaigns,
        portfolio_checkout_count    => scalar keys %portfolio_issues,
        multi_attributed_issue_count => $multi_count,
        calculated_at                => DateTime->now( time_zone => 'floating' )->strftime('%F %T'),
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
          ? $self->_checkout_events(
            $result->{eligible_itemnumbers},
            $result->{windows}->{during}->{start},
            $result->{windows}->{during}->{end},
          )
          : [];
        for my $value (@values) {
            my $group = $groups{ $value->{code} } ||= {
                code             => $value->{code},
                label            => $value->{label},
                campaign_ids     => {},
                eligible_items   => {},
                checkout_issues  => {},
                exclusive_campaign_ids => {},
                exclusive_checkout_issues => {},
                multi_location_campaign_count => 0,
            };
            $group->{campaign_ids}->{$campaign_id} = 1;
            $group->{eligible_items}->{$_} = 1
              for @{ $result->{eligible_itemnumbers} };
            $group->{checkout_issues}->{ $_->{issue_id} } = 1 for @{$events};
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
        {
            code             => $group->{code},
            label            => $group->{label},
            campaign_count   => scalar keys %{ $group->{campaign_ids} },
            eligible_item_count => scalar keys %{ $group->{eligible_items} },
            checkout_count   => scalar keys %{ $group->{checkout_issues} },
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
