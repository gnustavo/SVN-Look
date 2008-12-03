#!/usr/bin/perl

use strict;
use warnings;
use lib 't';
use Test::More;

require "test-functions.pl";

if (has_svn()) {
    plan tests => 1;
}
else {
    plan skip_all => 'Need svn commands in the PATH.';
}

require_ok('SVN::Look');
