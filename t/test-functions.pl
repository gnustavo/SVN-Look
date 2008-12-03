# Copyright (C) 2008 by CPqD

BEGIN { $ENV{PATH} = '/usr/local/bin:/usr/bin:/bin' }

use strict;
use warnings;
use Cwd;
use File::Temp qw/tempdir/;
use File::Spec::Functions qw/catfile path/;

# Make sure the svn messages come in English.
$ENV{LC_MESSAGES} = 'C';

sub has_svn {
  CMD:
    for my $cmd (qw/svn svnadmin svnlook/) {
	for my $path (path()) {
	    next CMD if -x catfile($path, $cmd);
	}
	return 0;
    }
    return 1;
}

our $T;

sub do_script {
    my ($num, $cmd) = @_;
    {
	open my $script, '>', "$T/script" or die;
	print $script $cmd;
	close $script;
	chmod 0755, "$T/script";
    }

    system("$T/script 1>$T/$num.stdout 2>$T/$num.stderr");
}

sub work_ok {
    my ($tag, $cmd) = @_;
    my $num = 1 + Test::Builder->new()->current_test();
    ok((do_script($num, $cmd) == 0), $tag)
	or diag("work_ok command failed.\n");
}

sub work_nok {
    my ($tag, $error_expect, $cmd) = @_;

    my $num = 1 + Test::Builder->new()->current_test();
    my $exit = do_script($num, $cmd);
    if ($exit == 0) {
	fail($tag);
	diag("work_nok command worked but it shouldn't!\n");
	return;
    }

    my $stderr = `cat $T/$num.stderr`;

    if (! ref $error_expect) {
	ok(index($stderr, $error_expect) >= 0, $tag)
	    or diag("work_nok:\n  '$stderr'\n    does not contain\n  '$error_expect'\n");
    }
    elsif (ref $error_expect eq 'Regexp') {
	like($stderr, $error_expect, $tag);
    }
    else {
	fail($tag);
	diag("work_nok: invalid second argument to test.\n");
    }
}

sub reset_repo {
    my $cleanup = exists $ENV{REPO_CLEANUP} ? $ENV{REPO_CLEANUP} : 1;
    $T = tempdir('t.XXXX', DIR => getcwd(), CLEANUP => $cleanup);

    system(<<"EOS");
svnadmin create $T/repo
EOS

    system(<<"EOS");
svn co -q file://$T/repo $T/wc
EOS

    return $T;
}

1;
