# This file was generated by http://search.cpan.org/dist/Dist-Zilla-Plugins-CJM/lib/Dist/Zilla/Plugin/MakeMaker/Custom.pm

use strict;
use warnings;

# Check if we have a suitable version of the svnlook command.
eval {
    my $path = $ENV{PATH} || '';
    open my $svnlook, '-|', 'svnlook --version'
        or die "Aborting because I couldn't find the 'svnlook' executable in PATH='$path'.\n";
    $_ = <$svnlook>;
    if (my ($major, $minor, $patch) = (/(\d+)\.(\d+)\.(\d+)/)) {
        $major > 1 || $major == 1 && $minor >= 4
            or die "I need at least version 1.4.0 of svnlook but you have only $major.$minor.$patch.\n";
    } else {
        die "Can't grok Subversion version from svnlook --version command.\n";
    }
    local $/ = undef;           # slurp mode
    <$svnlook>;
    close $svnlook or die "Can't close svnlook commnand.\n";
};
if ($@) {
    warn $@;
    # CPAN Testers says
    # (http://wiki.cpantesters.org/wiki/CPANAuthorNotes) that we
    # should simply exit normally before generating the Makefile if
    # there is an unmet dependency.
    exit 0;
}

use ExtUtils::MakeMaker ##{ $eumm_version ##};

my %WriteMakefileArgs = (
    ##{ $plugin->get_default(keys %default_args) ##}
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
