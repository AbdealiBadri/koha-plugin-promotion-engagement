#!/usr/bin/env perl
use Modern::Perl;
use CGI;
use Koha::Plugins;

my $name  = shift @ARGV || 'dashboard';
my $query = shift @ARGV || q{};

my @plugins = Koha::Plugins->new()->GetPlugins( { method => 'tool' } );
my ($plugin) = grep {
    ref($_) eq 'Koha::Plugin::Com::AJSN::PromotionEngagement'
} @plugins;
die "Promotion & Engagement plugin not loaded\n" unless $plugin;
$plugin->{cgi} = CGI->new($query);

my $output = q{};
my $returned;
{
    open my $capture, '>', \$output or die $!;
    local *STDOUT = $capture;
    $returned = $plugin->tool;
}
$output .= $returned if defined $returned;
die "$name produced no Promotion HTML\n"
  unless $output =~ /Promotion/i;
die "$name exposed a template failure\n"
  if $output =~ /Template process failed/i;
say "$name render PASS (" . length($output) . " bytes)";
