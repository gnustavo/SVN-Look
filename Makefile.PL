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
    if (-x $f) {
	$svnlook = $f;
	last;
    }
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
