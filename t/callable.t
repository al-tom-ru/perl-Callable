use 5.010;
use strict;
use utf8;
use warnings;

use Test::More tests => 2;

use_ok 'Callable';

subtest 'Make subroutine callable' => sub {
    plan tests => 2;

    my $source   = sub { 'foo' };
    my $callable = Callable->new($source);

    is $callable->() => 'foo', 'Valid call result';
    is "$callable"   => 'foo', 'Valid interpolation result';
};
