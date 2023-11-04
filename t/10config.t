#!perl
use Perl::Perf::Defaults;
use Test::More;
use Perl::Perf::Config;

{
  my $conf = Perl::Perf::Config->fill_defaults({});
  is($conf->{clone}, "perl", "clone");
  is_deeply($conf->{branches},
    +{
      "blead" => [ ],
      'maint-5.*' => [ ],
      'smoke-me/*' => [ ],
     }, "branches");
}
{
  my $conf = Perl::Perf::Config->fill_defaults({ clone => "perl2" });
  is($conf->{clone}, "perl2", "clone");
}

{
  my $conf = Perl::Perf::Config->parse(<<'CONF', 'json', 'test.json');
{
  "test": 1,
  "clone": "perl3"
}
CONF
  is($conf->{test}, 1 , "json: test");
  is($conf->{clone}, "perl3", "json: clone");
}
{
  my $conf = Perl::Perf::Config->parse(<<'CONF', 'yaml', 'test.json');
test: 1
clone: perl3
CONF
  is($conf->{test}, 1 , "yaml: test");
  is($conf->{clone}, "perl3", "yaml: clone");
}

{
  my $conf = Perl::Perf::Config->load("t/data/testconf.json");
  is($conf->{clone}, "perl4", "json file: clone");
}
{
  my $conf = Perl::Perf::Config->load("t/data/testconf.yaml");
  is($conf->{clone}, "perl5", "yaml file: clone");
}

done_testing();
