use strict;
use warnings;
use CGI;
use Koha::Plugin::Com::AJSN::PromotionEngagement;

my $plugin = Koha::Plugin::Com::AJSN::PromotionEngagement->new(
    { enable_plugins => 1 }
);

my @cases = (
    [ dashboard => 'action=dashboard', 'Promotion &amp; Engagement', 'Configuration' ],
    [ promotions => 'action=promotions', 'Promotion portfolio', 'Configuration' ],
    [ analytics => 'action=analytics&campaign_id=40', 'Promotion analytics', 'Compare all campaigns' ],
    [ reports => 'action=reports', 'Promotion impact reports', 'All campaigns' ],
    [ impact => 'action=book_display_impact&campaign_id=40', 'Book Display Impact', 'Displayed-title demand and additional-copy review' ],
    [ detail => 'action=promotion_detail&campaign_id=40', 'MULTILOC-VISUAL-20260919', 'Edit promotion' ],
    [ edit => 'action=edit_promotion&campaign_id=40', 'Edit promotion', 'Validate and update campaign' ],
    [ new_promotion => 'action=new_promotion', 'New promotion', 'Validate and save campaign' ],
);

sub render_tool {
    my ( $query ) = @_;
    local $plugin->{cgi} = CGI->new($query);
    my $html = q{};
    open my $capture, '>', \$html or die "capture failed: $!";
    local *STDOUT = $capture;
    $plugin->tool;
    close $capture;
    return $html;
}
for my $case (@cases) {
    my ( $name, $query, @markers ) = @{$case};
    my $html = eval { render_tool($query) };
    die "$name render died: $@" if $@;
    die "$name returned empty output" unless length $html;
    die "$name template failure" if $html =~ /Template process failed/i;
    die "$name internal error" if $html =~ /Internal Server Error/i;
    for my $marker (@markers) {
        die "$name missing marker: $marker" unless index( $html, $marker ) >= 0;
    }
    print "$name render PASS\n";
}

{
    local $plugin->{cgi} = CGI->new(q{});
    my $html = q{};
    open my $capture, '>', \$html or die "capture failed: $!";
    local *STDOUT = $capture;
    $plugin->configure;
    close $capture;
    die "configuration returned empty output" unless length $html;
    die "configuration template failure" if $html =~ /Template process failed/i;
    die "configuration missing heading"
      unless index( $html, 'Promotion & Engagement configuration' ) >= 0;
    print "configuration render PASS\n";
}

print "render-smoke PASS\n";
