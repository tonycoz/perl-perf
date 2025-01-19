package Perl::Perf::Config 1.000;
use Perl::Perf::Defaults;
use Cpanel::JSON::XS;
use YAML::XS;
use Path::Tiny;

my @default_files = ( qw(perl-perf.json perl-perf.yml) );

sub load ($class, $file = undef) {
  unless ($file) {
    for my $try (@default_files) {
      if (-f $try) {
	$try = $file;
	last;
      }
    }

    unless ($file) {
      die "No config file specified and neither ",
	join(" nor ", @default_files), " found\n";
    }
  }

  my $content = path($file)->slurp;
  my $type =
    $file =~ /\.jso?n$/ ? "json" :
    $file =~ /\.ya?ml$/ ? "yaml" :
    die "Cannot find file type from filename '$file'\n";

  return $class->parse($content, $type, $file);
}


sub parse ($class, $content, $type, $file) {
  my $data;
  if ($type eq "json") {
    eval { $data = decode_json($content); 1 }
      or die "Could not parse $file as JSON: $@\n";
    return $class->fill_defaults($data);
  }
  elsif ($type eq "yaml") {
    eval { $data = Load($content); 1; }
      or die "Could not parse $file as YAML: $@\n";
    return $class->fill_defaults($data);
  }
  else {
    die "Unknown file type $type";
  }
}

sub fill_defaults ($class, $data) {
  $data->{clone} //= path(".")->child("perl");
  $data->{prefix} //= path(".")->child("prefix");
  $data->{branches} //=
    +{
      "blead" => [ ], # HEAD is always tested
      'maint-5.*' => [ ],
      'smoke-me/*' => [ ],
     };
  $data->{builds} //=
    +{
      "default" => {}
     };

  $data;
}

1;

=head1 NAME

Perl::Perf::Config - configuration for Perl::Perf

=head1 SYNOPSIS

  my $confdata = Perl::Perf::Confog->load()
  my $confdata = Perl::Perf::Config->load($filename);

  # the following are intended mostly for testing
  my $confdata = Perl::Perf::Config->parse($content, 'json', $filename);
  my $confdata = Perl::Perf::Config->parse($content, 'yaml', $filename);

  my $confdata = Perl::Perf::Config->fill_defaults($confdata);

=cut
