use 5.010;
use strict;
use utf8;
use warnings;

use Test::More tests => 3;

use Test::Exception;

use_ok 'Callable';

sub foo { 'main:foo' }

{

    package Foo;

    use Callable;

    sub foo             { 'Foo:foo' }
    sub with_package    { Callable->new('Foo::foo') }
    sub without_package { Callable->new('foo'); }
}

subtest 'Make subroutine callable' => sub {
    plan tests => 2;

    my $source   = sub { 'foo' };
    my $callable = Callable->new($source);

    is $callable->() => 'foo', 'Valid call result';
    is "$callable"   => 'foo', 'Valid interpolation result';
};

subtest 'Make scalar callable' => sub {
    plan tests => 9;

    my $source   = 'foo';
    my $callable = Callable->new($source);

    is $callable->() => 'main:foo', 'Valid call result';
    is "$callable"   => 'main:foo', 'Valid interpolation result';

    $callable = Callable->new('Foo::foo');
    is $callable->() => 'Foo:foo', 'Valid call result';
    is "$callable"   => 'Foo:foo', 'Valid interpolation result';

    $callable = Foo::with_package;
    is $callable->() => 'Foo:foo', 'Valid call result';
    is "$callable"   => 'Foo:foo', 'Valid interpolation result';

    $callable = Foo::without_package;
    is $callable->() => 'main:foo', 'Valid call result';
    is "$callable"   => 'main:foo', 'Valid interpolation result';

    $source   = 'not_existing_subroutine';
    $callable = Callable->new($source);
    dies_ok { $callable->() }, 'Unable to call not existing';
};
