package PE::Test;
use Perl::Perf::Defaults;
use Exporter "import";

our @EXPORT_OK = qw(do_cmd_test);

sub def_config {
  +{
    clone => "perl",
    cloneurl => "https://github.com/Perl/perl5.git",
    branches =>
    {
     "blead" => [ "**" ], # HEAD is always tested
     'maint-5.*' => [ ],
     'smoke-me/*' => [ ],
    },
   };
}

sub do_cmd_test (%opts) {
  my $out = "";
  open my $outfh, ">", \$out;
  my $cmd = Perl::Perf::Cmd->new
    (
     config => $opts{config} || def_config(),
     out => $outfh,
    );
  my %result;
  my $ok = eval {
    if ($opts{sub}) {
      $opts{sub}->($cmd);
    }
    elsif ($opts{args}) {
      $cmd->cmd($opts{args});
    }
  } or do {
    $result{exception} = $@;
  };
  $result{out} = $out;

  \%result;
}

1;
