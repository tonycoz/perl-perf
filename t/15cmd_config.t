#!perl
use Perl::Perf::Defaults;
use Test::More;
use Perl::Perf::Config;
use Perl::Perf::Cmd;
use lib 't/lib';
use PE::Test "do_cmd_test";

{
  my $res = do_cmd_test(args => [ qw(config clone) ]);
  ok(!$res->{exception}, "config clone: no exception");
  is($res->{out}, "perl\n", "config clone: expected output");
}

{
  my $res = do_cmd_test(args => [ qw(config branches.blead.0) ]);
  ok(!$res->{exception}, "config branches.blead.0: no exception");
  is($res->{out}, "**\n", "config braches.blead.0: expected output");
}

{
  my $res = do_cmd_test(args => [ qw(config) ]);
  ok(!$res->{exception}, "config: no exception");
  my $parsed = Cpanel::JSON::XS->new->decode($res->{out});
  is_deeply($parsed, PE::Test::def_config(), "config: expected output");
}

done_testing();
