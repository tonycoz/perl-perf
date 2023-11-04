use v5.32.0;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => "Perl::Perf",
    VERSION_FROM => "lib/Perl/Perf/Cmd.pm",
    EXE_FILES => [ "scripts/perl-perf" ],
    PREREQ_PM => {
	"Cpanel::JSON::XS" => 0,
	"YAML::XS" => 0,
	"Path::Tiny" => 0,
    }
);

