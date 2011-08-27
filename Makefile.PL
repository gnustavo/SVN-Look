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

# Check if we have a suitable version of the svnlook command.
{
    open my $svnlook, '-|', 'svnlook --version'
	or die "Aborting because I couldn't find the 'svnlook' executable in PATH=$ENV{PATH}.\n";
    $_ = <$svnlook>;
    if (my ($major, $minor, $patch) = (/(\d+)\.(\d+)\.(\d+)/)) {
	$major > 1 || $major == 1 && $minor >= 4
	    or die "I need at least version 1.4.0 of svnlook but you have only $major.$minor.$patch.\n";
    } else {
	die "Can't grok Subversion version from svnlook --version command.\n";
    }
    local $/ = undef;		# slurp mode
    <$svnlook>;
    close $svnlook or die "Can't close svnlook commnand.\n";
}

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
