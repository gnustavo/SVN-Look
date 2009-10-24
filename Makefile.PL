use 5.008;
use strict;
use warnings;
use File::Spec::Functions qw/catfile path/;
use ExtUtils::MakeMaker;

my $svnlook;
for my $d (
    path(),
    catfile('usr', 'local', 'bin'),
    catfile('usr', 'bin'),
    catfile('bin'),
) {
    my $f = catfile($d, 'svnlook');
    next unless -x $f;
    next unless system("$f help >/dev/null 2>/dev/null") == 0;
    $svnlook = $f;
    last;
}
die "Aborting because I couldn't find the 'svnlook' executable.\n"
    unless $svnlook;

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
