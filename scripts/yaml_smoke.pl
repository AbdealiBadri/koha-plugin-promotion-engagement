use Modern::Perl;
use YAML::XS qw(LoadFile);
my @files = qw(
  .project-memory/state.yaml
  .project-memory/modules.yaml
  .project-memory/issues.yaml
  .project-memory/decisions.yaml
);
LoadFile($_) for @files;
say 'yaml-parse PASS';
