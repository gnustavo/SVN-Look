package SVN::Look;

use strict;
use warnings;
use Carp;
use File::Spec::Functions;

=head1 NAME

SVN::Look - A caching wrapper aroung the svnlook command.

=head1 VERSION

Version 0.27

=cut

our $VERSION = '0.27';

=head1 SYNOPSIS

  use SVN::Look;
  my $revlook = SVN::Look->new('/repo/path', -r => 123);
  my $author  = $revlook->author();
  my $msg     = $revlook->log_msg();
  my @added_files   = $revlook->added();
  my @updated_files = $revlook->updated();
  my @deleted_files = $revlook->deleted();
  my @changed_files = $revlook->changed();
  my $file_contents = $revlook->cat('/path/to/file/in/repository');

  my $trxlook = SVN::Look->new('/repo/path', -t => 123);

=head1 DESCRIPTION

The svnlook command is the workhorse of Subversion hook scripts, being
used to gather all sorts of information about a repository, its
revisions, and its transactions. This script provides a simple object
oriented interface to a specific svnlook invocation, to make it easier
to hook writers to get and use the information they need. Moreover,
all the information gathered buy calling the svnlook command is cached
in the object, avoiding repetitious calls.

=cut

BEGIN {
    my $path = $ENV{PATH} || '';
    open my $svnlook, '-|', 'svnlook', '--version'
	or die "Aborting because I couldn't find the 'svnlook' executable in PATH='$path'.\n";
    $_ = <$svnlook>;
    if (my ($major, $minor, $patch) = (/(\d+)\.(\d+)\.(\d+)/)) {
	$major > 1 || $major == 1 && $minor >= 4
	    or die "I need at least version 1.4.0 of svnlook but you have only $major.$minor.$patch in PATH='$path'.\n";
    } else {
	die "Can't grok Subversion version from svnlook --version command.\n";
    }
    local $/ = undef;		# slurp mode
    <$svnlook>;
    close $svnlook or die "Can't close svnlook commnand.\n";
}

=head1 METHODS

=over 4

=item B<new> REPO [, WHAT, NUMBER]

The SVN::Look constructor needs one or three arguments:

=over

=item REPO is the path to the repository.

=item WHAT must be either '-r' or '-t', specifying if the third
argument is a revision number or a transaction number, respectivelly.

=item NUMBER is either a revision or transaction NUMBER, as specified
by WHAT.

=back

=cut

sub new {
    my ($class, $repo, @opts) = @_;
    my $self = {
        repo => $repo,
        opts => [@opts],
    };
    bless $self, $class;
    return $self;
}

sub _svnlook {
    my ($self, $cmd, @args) = @_;
    my @cmd = (svnlook => $cmd, $self->{repo});
    push @cmd, @{$self->{opts}} unless $cmd =~ /^(?:youngest|uuid|lock)$/;
    open my $fd, '-|', '"' . join('"  "', @cmd, @args) . '"'
        or die "Can't exec svnlook $cmd: $!\n";
    if (wantarray) {
        my @lines = <$fd>;
        close $fd or die "Failed closing svnlook $cmd: $!\n";
        chomp @lines;
        return @lines;
    }
    else {
        local $/ = undef;
        my $line = <$fd>;
        close $fd or die "Failed closing svnlook $cmd: $!\n";
        chomp $line unless $cmd eq 'cat';
        return $line;
    }
}

=item B<author>

Returns the author of the revision/transaction.

=cut

sub author {
    my $self = shift;
    unless (exists $self->{author}) {
        chomp($self->{author} = $self->_svnlook('author'));
    }
    return $self->{author};
}

=item B<cat> PATH

Returns the contents of the file at PATH. In scalar context, return
the whole contents in a single string. In list context returns a list
of chomped lines.

=cut

sub cat {
    my ($self, $path) = @_;
    return $self->_svnlook('cat', $path);
}

=item B<changed_hash>

Returns a reference to a hash containing information about all file
changes occurred in the revision. The hash always has the following
keys:

=over

=item added

A list of files added in the revision.

=item deleted

A list of files deleted in the revision.

=item updated

A list of files updated in the revision.

=item prop_modified

A list of files that had properties modified in the revision.

=item copied

A hash containing information about each file or diretory copied in the revision. The hash keys are the names of elements copied to. The value associated with a key is a two-element array containing the name of the element copied from and the specific revision from which it was copied.

=back

=cut

sub changed_hash {
    my $self = shift;
    unless ($self->{changed_hash}) {
        my (@added, @deleted, @updated, @prop_modified, %copied);
        foreach ($self->_svnlook('changed', '--copy-info')) {
            next if length($_) <= 4;
            chomp;
            my ($action, $prop, undef, undef, $changed) = unpack 'AAAA A*', $_;
            if    ($action eq 'A') {
                push @added,   $changed;
            }
            elsif ($action eq 'D') {
                push @deleted, $changed;
            }
            elsif ($action eq 'U') {
                push @updated, $changed;
            }
            else {
                if ($changed =~ /^\(from (.*?):r(\d+)\)$/) {
                    $copied{$added[-1]} = [$1 => $2];
                }
            }
            if ($prop eq 'U') {
                push @prop_modified, $changed;
            }
        }
        $self->{changed_hash} = {
            added         => \@added,
            deleted       => \@deleted,
            updated       => \@updated,
            prop_modified => \@prop_modified,
            copied        => \%copied,
        };
    }
    return $self->{changed_hash};
}

=item B<added>

Returns the list of files added in the revision/transaction.

=cut

sub added {
    my $self = shift;
    return @{$self->changed_hash()->{added}};
}

=item B<updated>

Returns the list of files updated in the revision/transaction.

=cut

sub updated {
    my $self = shift;
    return @{$self->changed_hash()->{updated}};
}

=item B<deleted>

Returns the list of files deleted in the revision/transaction.

=cut

sub deleted {
    my $self = shift;
    return @{$self->changed_hash()->{deleted}};
}

=item B<prop_modified>

Returns the list of files that had properties modified in the
revision/transaction.

=cut

sub prop_modified {
    my $self = shift;
    return @{$self->changed_hash()->{prop_modified}};
}

=item B<changed>

Returns the list of all files added, updated, deleted, and the ones
that had properties modified in the revision/transaction.

=cut

sub changed {
    my $self = shift;
    my $hash = $self->changed_hash();
    unless (exists $hash->{changed}) {
        $hash->{changed} = [@{$hash->{added}}, @{$hash->{updated}}, @{$hash->{deleted}}, @{$hash->{prop_modified}}];
    }
    return @{$hash->{changed}};
}

=item B<copied_to>

Returns the list of new names of files that were copied in the
revision/transaction.

=cut

sub copied_to {
    my $self = shift;
    return keys %{$self->changed_hash()->{copied}};
}

=item B<copied_from>

Returns the list of original names of files that were copied in the
revision/transaction. The order of this list is guaranteed to agree
with the order generated by the method copied_to.

=cut

sub copied_from {
    my $self = shift;
    return map {$_->[0]} values %{$self->changed_hash()->{copied}};
}

=item B<date>

Returns the date of the revision/transaction.

=cut

sub date {
    my $self = shift;
    unless (exists $self->{date}) {
        $self->{date} = $self->_svnlook('date');
    }
    return $self->{date};
}

=item B<diff> [OPTS, ...]

Returns the GNU-style diffs of changed files and properties. There are
three optional options that can be passed as strings:

=over

=item C<--no-diff-deleted>

Do not print differences for deleted files

=item C<--no-diff-added>

Do not print differences for added files.

=item C<--diff-copy-from>

Print differences against the copy source.

=back

In scalar context, return the whole diff in a single string. In list
context returns a list of chomped lines.

=cut

sub diff {
    my ($self, @opts) = @_;
    return $self->_svnlook('diff', @opts);
}

=item B<dirs_changed>

Returns the list of directories changed in the revision/transaction.

=cut

sub dirs_changed {
    my $self = shift;
    unless (exists $self->{dirs_changed}) {
        my @dirs = $self->_svnlook('dirs-changed');
        $self->{dirs_changed} = \@dirs;
    }
    return @{$self->{dirs_changed}};
}

=item B<info>

Returns the author, datestamp, log message size, and log message of
the revision/transaction.

=cut

sub info {
    my $self = shift;
    return $self->_svnlook('info');
}

=item B<lock> PATH

If PATH has a lock, returns a hash containing information about the lock, with the following keys:

=over

=item UUID Token

A string with the opaque lock token.

=item Owner

The name of the user that has the lock.

=item Created

The time at which the lock was created, in a format like this: '2010-02-16 17:23:08 -0200 (Tue, 16 Feb 2010)'.

=item Comment

The lock comment.

=back

If PATH has no lock, returns undef.

=cut

sub lock {
    my ($self, $path) = @_;
    my %lock = ();
    my @lock = $self->_svnlook('lock', $path);

    while (my $line = shift @lock) {
	chomp $line;
	my ($key, $value) = split /:\s*/, $line, 2;
	if ($key =~ /^Comment/) {
	    $lock{Comment} = join('', @lock);
	    last;
	}
	else {
	    $lock{$key} = $value;
	}
    }

    return %lock ? \%lock : undef;
}

=item B<log_msg>

Returns the log message of the revision/transaction.

=cut

sub log_msg {
    my $self = shift;
    unless (exists $self->{log}) {
        $self->{log} = $self->_svnlook('log');
    }
    return $self->{log};
}

=item B<propget> PROPNAME PATH

Returns the value of PROPNAME in PATH.

=cut

sub propget {
    my ($self, @args) = @_;
    return $self->_svnlook('propget', @args);
}

=item B<proplist> PATH

Returns a reference to a hash containing the properties associated with PATH.

=cut

sub proplist {
    my ($self, $path) = @_;
    unless ($self->{proplist}{$path}) {
        my $text = $self->_svnlook('proplist', '--verbose', $path);
        my @list = split /^\s\s(\S+)\s:\s/m, $text;
        shift @list;            # skip the leading empty field
        chomp(my %hash = @list);
        $self->{proplist}{$path} = \%hash;
    }
    return $self->{proplist}{$path};
}

=item B<tree> [PATH_IN_REPOS, OPTS, ...]

Returns the repository tree as a list of paths, starting at
PATH_IN_REPOS (if supplied, at the root of the tree otherwise),
optionally showing node revision ids.

=over

=item C<--full-paths>

show full paths instead of indenting them.

=item C<--show-ids>

Returns the node revision ids for each path.

=item C<--non-recursive>

Operate on single directory only.

=back

=cut

sub tree {
    my ($self, @args) = @_;
    return $self->_svnlook('tree', @args);
}

=item B<uuid>

Returns the repository's UUID.

=cut

sub uuid {
    my ($self) = @_;
    return $self->_svnlook('uuid');
}

=item B<youngest>

Returns the repository's youngest revision number.

=cut

sub youngest {
    my ($self) = @_;
    return $self->_svnlook('youngest');
}

=back

=head1 AUTHOR

Gustavo Chaves, C<< <gnustavo@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-svn-look at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVN-Hooks>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SVN::Look

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVN-Hooks>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SVN-Hooks>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SVN-Hooks>

=item * Search CPAN

L<http://search.cpan.org/dist/SVN-Hooks>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 CPqD, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of SVN::Look
