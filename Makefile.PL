use 5.008;
use strict;
use warnings;
use File::Spec::Functions;
use ExtUtils::MakeMaker;
use Getopt::Long  qw(GetOptions);

# clean up the testing flag file.
my $t_author = catfile('t', 'author.enabled');
unlink($t_author);

my $usage        = "$0 [--author-tests]\n";
my $author_tests = 0;
GetOptions(
    'author-tests' => \$author_tests,
) or die $usage;

# Check if we have the svnlook command.
eval {
    open my $svnlook, '-|', 'svnlook --version' or die;
    local $/ = undef;		# slurp mode
    <$svnlook>;
    close $svnlook or die;
};
die "Aborting because I couldn't find the 'svnlook' executable.\n"
    if $@;

if ($author_tests) {
    open(ENABLED, '>', $t_author) or die "Can't touch $t_author: $!\n";
    close(ENABLED)                or die "Can't touch $t_author: $!\n";
}

my $look_pm = catfile('lib', 'SVN', 'Look.pm');

WriteMakefile(
    NAME                => 'SVN::Look',
    AUTHOR              => 'Gustavo Chaves <gustavo+perl@gnustavo.org>',
    VERSION_FROM        => $look_pm,
    ABSTRACT_FROM       => $look_pm,
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
	'File::Spec::Functions' => 0,
	'URI::file' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SVN-Look-*' },
);
