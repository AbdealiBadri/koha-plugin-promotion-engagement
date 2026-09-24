package Koha::Plugin::Com::AJSN::PromotionEngagement::BookDisplayImpact;

use Modern::Perl;
use POSIX qw(ceil);
use Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics;

our $SPEC_VERSION = '1.0.0';

sub new {
    my ( $class, $args ) = @_;
    die 'dbh is required' unless $args && $args->{dbh};
    return bless { dbh => $args->{dbh} }, $class;
}

sub campaign_rows {
    my ( $self, $campaign_id, $args ) = @_;
    $args ||= {};
    my $analytics =
      Koha::Plugin::Com::AJSN::PromotionEngagement::Analytics->new(
        { dbh => $self->{dbh} }
      )->campaign_metrics( $campaign_id, $args );
    my @itemnumbers = @{ $analytics->{eligible_itemnumbers} || [] };
    return { analytics => $analytics, rows => [], summary => _summary( [], $analytics ) }
      unless @itemnumbers;

    my $placeholders = join q{,}, (q{?}) x @itemnumbers;
    my $metadata = $self->{dbh}->selectall_arrayref(
        qq{
            SELECT i.itemnumber, i.biblionumber, i.barcode, b.title, b.author
              FROM items i JOIN biblio b ON b.biblionumber = i.biblionumber
             WHERE i.itemnumber IN ($placeholders)
        },
        { Slice => {} }, @itemnumbers,
    ) || [];
    my %meta_by_item = map { $_->{itemnumber} => $_ } @{$metadata};
    my %response_by_item =
      map { $_->{itemnumber} => $_ } @{ $analytics->{item_response_rows} || [] };
    my %biblios;
    for my $itemnumber (@itemnumbers) {
        my $meta = $meta_by_item{$itemnumber} || next;
        my $row = $biblios{ $meta->{biblionumber} } ||= {
            biblionumber => 0 + $meta->{biblionumber},
            title => $meta->{title} || 'Untitled',
            author => $meta->{author} || q{},
            displayed_items => 0,
            baseline_count => 0,
            during_count => 0,
            after_60_count => 0,
            barcodes => [],
        };
        my $response = $response_by_item{$itemnumber} || {};
        $row->{displayed_items}++;
        push @{ $row->{barcodes} }, $meta->{barcode} if $meta->{barcode};
        $row->{baseline_count} += $response->{baseline_count} || 0;
        $row->{during_count} += $response->{during_count} || 0;
        $row->{after_60_count} += $response->{after_60_count} || 0;
    }
    my @biblionumbers = sort { $a <=> $b } keys %biblios;
    $self->_add_copy_and_hold_evidence( \%biblios, \@biblionumbers );
    $self->_add_saved_decisions( $campaign_id, \%biblios );
    my $followup_complete =
      ( $analytics->{windows}->{after_60}->{state} || q{} ) eq 'complete' ? 1 : 0;
    my @rows =
      map { _classify_row( $biblios{$_}, $followup_complete ) } @biblionumbers;
    @rows = sort {
           $b->{priority_rank} <=> $a->{priority_rank}
        || $b->{active_holds} <=> $a->{active_holds}
        || lc($a->{title}) cmp lc($b->{title})
    } @rows;

    my $during_available =
      ( $analytics->{windows}->{during}->{state} || q{} ) ne 'pending' ? 1 : 0;
    my $max_during_count = 0;
    if ($during_available) {
        for my $row (@rows) {
            $max_during_count = $row->{during_count}
              if ( $row->{during_count} || 0 ) > $max_during_count;
        }
    }
    for my $row (@rows) {
        $row->{is_zero_response} =
          $during_available && !( $row->{during_count} || 0 ) ? 1 : 0;
        $row->{is_top_issuing} =
          $during_available
          && $max_during_count > 0
          && ( $row->{during_count} || 0 ) == $max_during_count ? 1 : 0;
    }

    my $summary = _summary( \@rows, $analytics );
    $summary->{max_during_count} = $max_during_count;

    return {
        spec_version => $SPEC_VERSION,
        analytics => $analytics,
        rows => \@rows,
        summary => $summary,
    };
}

sub _add_copy_and_hold_evidence {
    my ( $self, $biblios, $ids ) = @_;
    return unless @{$ids};
    my $ph = join q{,}, (q{?}) x @{$ids};
    my $copies = $self->{dbh}->selectall_arrayref(
        qq{
            SELECT i.biblionumber, COUNT(*) AS total_copies,
              SUM(CASE WHEN COALESCE(i.itemlost,0)=0
                AND COALESCE(i.withdrawn,0)=0 AND COALESCE(i.damaged,0)=0
                AND COALESCE(i.notforloan,0)=0 THEN 1 ELSE 0 END)
                AS serviceable_copies,
              SUM(CASE WHEN iss.issue_id IS NULL
                AND COALESCE(i.itemlost,0)=0 AND COALESCE(i.withdrawn,0)=0
                AND COALESCE(i.damaged,0)=0 AND COALESCE(i.notforloan,0)=0
                THEN 1 ELSE 0 END) AS available_copies
              FROM items i LEFT JOIN issues iss ON iss.itemnumber = i.itemnumber
             WHERE i.biblionumber IN ($ph)
             GROUP BY i.biblionumber
        }, { Slice => {} }, @{$ids},
    ) || [];
    for my $copy (@{$copies}) {
        my $row = $biblios->{ $copy->{biblionumber} } || next;
        $row->{total_copies} = 0 + ( $copy->{total_copies} || 0 );
        $row->{serviceable_copies} =
          0 + ( $copy->{serviceable_copies} || 0 );
        $row->{available_copies} = 0 + ( $copy->{available_copies} || 0 );
    }
    my $holds = $self->{dbh}->selectall_arrayref(
        qq{
            SELECT biblionumber, COUNT(*) AS active_holds
              FROM reserves WHERE biblionumber IN ($ph)
               AND cancellationdate IS NULL
             GROUP BY biblionumber
        }, { Slice => {} }, @{$ids},
    ) || [];
    $biblios->{ $_->{biblionumber} }->{active_holds} =
      0 + ( $_->{active_holds} || 0 ) for @{$holds};
    my ($target) = $self->{dbh}->selectrow_array(
        q{SELECT value FROM systempreferences WHERE variable='HoldRatioDefault'}
    );
    $target = 3 unless defined $target && $target =~ /^\d+(?:\.\d+)?$/ && $target > 0;
    $biblios->{$_}->{hold_ratio_target} = 0 + $target for @{$ids};
}

sub _add_saved_decisions {
    my ( $self, $campaign_id, $biblios ) = @_;
    my $rows = $self->{dbh}->selectall_arrayref(
        q{
            SELECT recommendation_id, biblionumber, decision_status,
                   recommended_quantity, reviewer_note, koha_suggestion_id,
                   decided_by, decided_at, submitted_at
              FROM plugin_ajsn_promo_recommendations
             WHERE campaign_id = ?
        },
        { Slice => {} }, $campaign_id,
    ) || [];
    for my $decision (@{$rows}) {
        my $row = $biblios->{ $decision->{biblionumber} } || next;
        $row->{decision} = $decision;
    }
}

sub _classify_row {
    my ( $row, $followup_complete ) = @_;
    $row->{total_copies} ||= 0;
    $row->{serviceable_copies} ||= 0;
    $row->{available_copies} ||= 0;
    $row->{active_holds} ||= 0;
    my $copies = $row->{serviceable_copies} || 1;
    $row->{hold_ratio} = 0 + sprintf '%.2f', $row->{active_holds} / $copies;
    my $target = $row->{hold_ratio_target} || 3;
    my $target_copies = ceil( $row->{active_holds} / $target );
    my $quantity = $target_copies - $row->{serviceable_copies};
    $quantity = 0 if $quantity < 0;
    my $sustained = $followup_complete
      && $row->{after_60_count} > $row->{baseline_count};
    $row->{followup_complete} = $followup_complete ? 1 : 0;
    my $increased = $row->{during_count} > $row->{baseline_count};

    if ( $quantity > 0 && ( $row->{hold_ratio} >= 2 || $sustained ) ) {
        $row->{priority} = 'High';
        $row->{priority_rank} = 3;
    } elsif ( $row->{active_holds} || $increased || $sustained ) {
        $row->{priority} = 'Review';
        $row->{priority_rank} = 2;
    } else {
        $row->{priority} = 'Monitor';
        $row->{priority_rank} = 1;
    }
    $row->{suggested_quantity} = $quantity || 1;
    $row->{purchase_signal} = $row->{priority} eq 'Monitor' ? 0 : 1;
    $row->{recommendation_reason} =
        $row->{active_holds}
      ? sprintf('%d active hold(s) across %d serviceable copy/copies.',
            $row->{active_holds}, $row->{serviceable_copies})
      : $sustained
      ? 'Borrowing remained above the baseline during the follow-up period.'
      : $increased
      ? 'Borrowing increased while the title was promoted.'
      : 'No additional-copy pressure is currently established.';
    $row->{evidence_grade} =
        $row->{active_holds} && ( $increased || $sustained ) ? 'Strong'
      : $row->{active_holds} || $increased || $sustained     ? 'Moderate'
      :                                                        'Limited';
    return $row;
}

sub _summary {
    my ( $rows, $analytics ) = @_;
    $analytics ||= {};
    return {
        title_count => scalar @{$rows},
        titles_used_count => $analytics->{titles_used_count},
        titles_used_display =>
          defined $analytics->{titles_used_count}
          ? q{} . $analytics->{titles_used_count} : '—',
        title_utilization_rate => $analytics->{title_utilization_rate},
        title_utilization_display =>
          defined $analytics->{title_utilization_rate}
          ? sprintf( '%.1f', $analytics->{title_utilization_rate} )
          : undef,
        during_checkout_count =>
          $analytics->{metrics}->{during}->{checkout_count},
        during_checkout_display =>
          defined $analytics->{metrics}->{during}->{checkout_count}
          ? q{} . $analytics->{metrics}->{during}->{checkout_count} : '—',
        baseline_checkout_count =>
          $analytics->{metrics}->{baseline}->{checkout_count},
        titles_increased_count => $analytics->{titles_increased_count},
        titles_increased_display =>
          defined $analytics->{titles_increased_count}
          ? q{} . $analytics->{titles_increased_count} : '—',
        zero_response_title_count => $analytics->{zero_response_title_count},
        zero_response_display =>
          defined $analytics->{zero_response_title_count}
          ? q{} . $analytics->{zero_response_title_count} : '—',
        repeat_demand_title_count => $analytics->{repeat_demand_title_count},
        high_priority_count => scalar( grep { $_->{priority} eq 'High' } @{$rows} ),
        active_holds => 0 + eval { my $n = 0; $n += $_->{active_holds} for @{$rows}; $n } || 0,
        approved_count => scalar( grep {
            $_->{decision} && $_->{decision}->{decision_status} eq 'approved'
        } @{$rows} ),
        submitted_count => scalar( grep {
            $_->{decision} && $_->{decision}->{decision_status} eq 'submitted'
        } @{$rows} ),
    };
}

1;
