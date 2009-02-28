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

sub newdir {
    my $num = 1 + Test::Builder->new()->current_test();
    my $dir = "$T/$num";
    mkdir $dir;
    $dir;
}

sub do_script {
    my ($dir, $cmd) = @_;
    {
	open my $script, '>', "$dir/script" or die;
	print $script $cmd;
	close $script;
	chmod 0755, "$dir/script";
    }

    system("$dir/script 1>$dir/stdout 2>$dir/stderr");
}

sub work_ok {
    my ($tag, $cmd) = @_;
    my $dir = newdir();
    ok((do_script($dir, $cmd) == 0), $tag)
	or diag("work_ok command failed with following stderr:\n", `cat $dir/stderr`);
}

sub work_nok {
    my ($tag, $error_expect, $cmd) = @_;
    my $dir = newdir();
    my $exit = do_script($dir, $cmd);
    if ($exit == 0) {
	fail($tag);
	diag("work_nok command worked but it shouldn't!\n");
	return;
    }

    my $stderr = `cat $dir/stderr`;

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
