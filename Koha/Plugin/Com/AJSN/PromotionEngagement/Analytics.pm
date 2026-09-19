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
    my ( $self, $campaign_id ) = @_;
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
        data_quality_warnings  => [],
    };
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

sub _round {
    my ($value) = @_;
    return 0 + sprintf '%.4f', $value;
}

1;
