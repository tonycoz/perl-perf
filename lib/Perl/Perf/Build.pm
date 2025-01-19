package Perl::Perf::Build;
use Perl::Perf::Defaults;
use Path::Tiny;

sub new ($class, $cfg) {
  return bless { config => $cfg }, $class;
}

sub _prefix ($self) {
  $self->{config}{prefix};
}

sub _clone ($self) {
  $self->{config}{clone};
}

sub build ($self, $req) {
  my $build_name = $req->{build};
  my $build = $self->{config}{builds}{$build_name};
  unless ($build) {
    return { error => "unknown build name '$build_name'" };
  }

  $self->_clean_prefix()
    or return 1;

  my $pid = open my $fh, "-|";
  unless (defined $pid) {
    return { error => "cannot fork :$!" };
  }

  if ($pid) {
    my %result = { log => "" };
    # parent
    my $log = '';
    while (my $line = <$fh>) {
      $result{log} .= $line;
      print $line if $req->{verbose};
    }
    unless (close($fh)) {
      $result{error} = "child exit $?";
      $self->{exit} = $?;
    }
    $result{prefix} = $self->_prefix;
    return \%result;
  }
  else {
    # child
    # capture stderr too
    open *STDERR, ">&", \*STDOUT;
    if ($build->{command}) {
      exit $self->build_external($req, $build_name, $build);
    }
    else {
      exit $self->build_internal($req, $build_name, $build);
    }
  }
}

sub build_external ($self, $req, $build_name, $build) {
  local $ENV{PERL_PERF_BUILD_VERBOSE} = $req->{verbose} ? 1 : 0;
  local $ENV{PERL_PERF_BUILD_PREFIX} = $self->_prefix;
  local $ENV{PERL_PERF_SOURCE_TREE} = $self->_clone;

  my $result;
  if (ref $build->{command}) {
    $result = system($build->{command}->@*);
  }
  else {
    $result = system($build->{command});
  }
  return $result;
}

sub build_internal ($self, $req, $build_name, $build) {
  my $clone = $self->_clone;
  my $dir = File::Temp->newdir;
  my $dirname = $dir->dirname;

  chdir $dirname
    or die "Cannot chdir to build directory: $!\n";

  my @cfg_cmd = ( "sh", "$clone/Configure", "-de",
		  "-Dprefix=" . $self->_prefix,
		  "-Dusedevel",
		  "-Uversiononly" );
  push @cfg_cmd, @{$build->{configure_extra}}
    if $build->{configure_extra};

  print "** Configure\n@cfg_cmd\n";

  system @cfg_cmd;
  unless ($?) {
    my @build_cmd = ( "make" );
    my $jobs = $build->{make_jobs} // $build->{jobs};
    push @build_cmd, "-j$jobs"
      if defined $jobs && $jobs != 1;
    my $test_jobs = $build->{test_jobs} // $build->{jobs};
    push @build_cmd, "TEST_JOBS=$test_jobs"
      if defined $test_jobs && $test_jobs != 1;
    push @build_cmd, "test_harness";
    print "** make\n@build_cmd\n";
    system @build_cmd;
  }

  return $?;
}

sub _clean_prefix ($self) {
  my $prefix = $self->_prefix;
  if (-d $prefix) {
    my @kids = path($prefix)->children;
    for my $kid (@kids) {
      unless (eval { $kid->remove_tree(); 1 }) {
	print "Error removing $kid: $@\n";
	return 0;
      }
    }
  }

  return 1;
}

1;

=head1 NAME

Perl::Perf::Build - build perl for perl-perf

=head1 SYNOPSIS

  perl-perf build [-v] [build-name]

  my $builder = Perl::Perf::Build->new($config);
  my $result = $builder->build(\@ARGV);

=head1 DESCRIPTION

Builds perl based on the supplied configuration.

=head1 CONFIGURATION

Each build type has an entry in the C<builds> hash, indexed by the
supplied C<build-name>, or C<default> if none is supplied.

Keys for a build include:

=over

=item C<command>

A command that builds perl, if supplied the other keys are ignored.

This can be a string or an array.

The following environment variables are supplied:

=back
