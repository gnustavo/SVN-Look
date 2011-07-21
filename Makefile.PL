use 5.008;
use strict;
use warnings;
use File::Spec::Functions;
use ExtUtils::MakeMaker;
use Getopt::Long  qw(GetOptions);

# clean up the testing flag file.
unlink('t/author.enabled');

my $usage        = "$0 [--author-tests]\n";
my $author_tests = 0;
GetOptions(
    'author-tests' => \$author_tests,
) or die $usage;

my $svnlook;

eval {
    open my $svnlook, '-|', 'svnlook --version' or die;
    local $/ = undef;		# slurp mode
    <$svnlook>;
    close $svnlook or die;
};
die "Aborting because I couldn't find the 'svnlook' executable.\n"
    if $@;

if ($author_tests) {
    open(ENABLED, ">t/author.enabled") or die "Can't touch ./t/author.enabled: $!";
    close(ENABLED)                     or die "Can't touch ./t/author.enabled: $!";
}

WriteMakefile(
    NAME                => 'SVN::Look',
    AUTHOR              => 'Gustavo Chaves <gustavo+perl@gnustavo.org>',
    VERSION_FROM        => 'lib/SVN/Look.pm',
    ABSTRACT_FROM       => 'lib/SVN/Look.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
	'File::Spec::Functions' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SVN-Look-*' },
);
