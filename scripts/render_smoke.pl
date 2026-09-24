use strict;
use warnings;
use CGI;
use Koha::Plugin::Com::AJSN::PromotionEngagement;

my @cases = (
    [ dashboard => 'action=dashboard', 'Promotion &amp; Engagement', 'How to Use', 'Titles Issued / Borrowed' ],
    [ promotions => 'action=promotions', 'Promotion portfolio', 'How to Use', 'Compare selected campaigns' ],
    [ analytics => 'action=analytics&campaign_id=40', 'Promotion analytics', 'Chart View', 'Titles with Increased Issues' ],
    [ reports => 'action=reports', 'Promotion impact reports', 'Chart View', 'Table View' ],
    [ impact => 'action=book_display_impact&campaign_id=40', 'Promoted Resource Impact', 'Collection-development signals' ],
    [ detail => 'action=promotion_detail&campaign_id=40', 'MULTILOC-VISUAL-20260919', 'Impact at a glance' ],
    [ edit => 'action=edit_promotion&campaign_id=40', 'Edit promotion', 'Validate and update campaign' ],
    [ new_promotion => 'action=new_promotion', 'New promotion', 'Validate and save campaign' ],
);

sub new_plugin {
    return Koha::Plugin::Com::AJSN::PromotionEngagement->new(
        { enable_plugins => 1 }
    );
}

sub capture_output {
    my ($code) = @_;
    my $html = q{};
    {
        local *STDOUT;
        open STDOUT, '>', \$html or die "capture failed: $!";
        $code->();
    }
    return $html;
}

sub render_tool {
    my ($query) = @_;
    my $plugin = new_plugin();
    $plugin->{cgi} = CGI->new($query);
    return capture_output( sub { $plugin->tool } );
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
    my $plugin = new_plugin();
    $plugin->{cgi} = CGI->new(q{});
    my $html = eval { capture_output( sub { $plugin->configure } ) };
    die "configuration render died: $@" if $@;
    die "configuration returned empty output" unless length $html;
    die "configuration template failure" if $html =~ /Template process failed/i;
    for my $marker (
        'Promotion &amp; Engagement configuration',
        'How to Use',
        'Campaign types',
        'Cadence / frequency'
      )
    {
        die "configuration missing marker: $marker"
          unless index( $html, $marker ) >= 0;
    }
    print "configuration render PASS\n";
}

print "render-smoke PASS v0.6.1\n";
