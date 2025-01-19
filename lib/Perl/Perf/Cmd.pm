package Perl::Perf::Cmd 1.000;
use Perl::Perf::Defaults;
use Getopt::Long "GetOptionsFromArray";

sub new ($class, %opts) {
  %opts =
    (
     out => \*STDOUT,
     %opts,
    );
  bless \%opts, $class;
}

sub cmd ($self, $args) {
  GetOptionsFromArray($args,
		      "c|config=s" => \($self->{config_file}));
  unless (@$args) {
    die <<"EOS";
Usage: $0 [globaloptions] command [command options]
Commands: help
EOS
  }
  my $cmd = shift @$args;
  my $method = "cmd_$cmd";
  unless ($self->can($method)) {
    say "Unknown command $cmd";
    $method = "cmd_help";
  }
  return $self->$method($args);
}

my %help =
  (
   help => <<'EOS',
perl-perf help - display this help
perl-perf help <command> - display help for <command>
EOS
   config => <<'EOS',
perl-perf config key.key.... - display given key from the configuration
EOS
   build => <<'EOS'
perl-perf build [-v] [build-name] - build perl based on the configuration
   build-name defaults to "default"
   -v - displays output of build commands
EOS
   );

sub cmd_help ($self, $args) {
  my $sub = shift @$args // "help";
  unless ($help{$sub}) {
    say "Unknown command $sub";
    say "Known commands: ", join (", ", sort keys %help);
    return;
  }
  print $help{$sub};
}

sub _config ($self) {
  unless ($self->{config}) {
    require Perl::Perf::Config;
    $self->{config} = Perl::Perf::Config->load($self->{config_file});
  }
  $self->{config};
}

sub cmd_config ($self, $args) {
  my $cfg = $self->_config();

  my $out = $self->{out};

  if (@$args) {
    my $path = shift @$args;
    my @path = split /\./, $path;
    my @seen;
    while (@path) {
      if (!ref $cfg) {
	die join(".", @seen), " isn't a hash, cannot resolve ", join(".", @path), "\n";
      }
      my $comp = shift @path;
      if (ref $cfg eq "HASH") {
	$cfg = $cfg->{$comp};
      }
      elsif (ref $cfg eq "ARRAY") {
	$comp =~ /^(0|[1-9][0-9]+)$/
	  or die "Component corresponding to $comp is an array, but $comp isn't an integer]\n";
	$comp < @$cfg
	  or die "$comp out of range ", join(".", @seen), " has ", scalar @$cfg, " elements\n";
	$cfg = $cfg->[$comp];
      }
      elsif (!ref $cfg) {
	die join(".", @seen), " is not a reference\n";
      }
      else {
	die "Paths through ", ref $cfg, " not implemented\n";
      }
      push @seen, $comp;
    }
    if (ref $cfg) {
      die join(".", @seen), " is a ", ref $cfg, " reference\n";
    }
    say $out $cfg;
  }
  else {
    require Cpanel::JSON::XS;
    say $out Cpanel::JSON::XS->new->pretty(1)->canonical(1)->encode($cfg);
  }
}

sub cmd_build ($self, $args) {
  my $cfg = $self->_config;

  my $verbose;
  GetOptionsFromArray($args,
		      "v" => \$verbose);
  require Perl::Perf::Build;
  my $build_name = @$args ? shift @$args : "default";
  @$args
    and $self->_usage("build", "$0 build: Too many arguments\n");
  my $result = Perl::Perf::Build->new($cfg)->build
    ( { args => $args, verbose => $verbose } );
  if ($result->{error}) {
    die "$0 build: $result->{error}\n";
  }
  else {
    print "Build success!\n" if $verbose;
  }
}

sub _usage ($self, $cmd, $error = undef) {
  print STDERR $error if defined $error;
  $cmd //= "";
  if ($help{$cmd}) {
    print STDERR $help{$cmd};
  }
  else {
    print STDERR "Unknown usage '$cmd'\n";
  }
  exit 1;
}

1;
