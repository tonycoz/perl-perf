package Perl::Perf::Defaults;
use v5.32.0;
use strict;
use warnings;
use experimental;
use builtin;

sub import {
    strict->import;
    warnings->import;
    feature->unimport(":all"); # disable indirect etc
    feature->import(":5.32.0", "fc", "bitwise");
    experimental->import("re_strict", "regex_sets", "signatures", "builtin");
    feature->unimport("switch", "indirect");
    builtin->import(qw(true false trim));
}

1;

=head1 NAME

Perl::Perf::Defaults - sensible features/defaults for Perl::Perf code.

=head1 SYNOPSIS

  use SmokeReports::Sensible;

=head1 DESCRIPTION

Set reasonable features and compilation defaults for Perl::Perf
code, this includes:

  use strict;
  use warnings;
  use feature ':5.32.0', 'fc', 'bitwise';
  use experimental 're_strict', 'regex_sets', 'signatures';
  no feature "switch", "indirect";
  use builtin qw(true false trim);

=head1 RATIONALE

This allows me to centralize the modern features I want to use in this
particular project, in a way that I control.

=cut
