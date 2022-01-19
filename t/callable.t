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

sub test_callable {
    my ( $source, $expected, $comment ) = @_;

    $comment //= '';

    my $callable = Callable->new($source);

    is_deeply $callable->() => $expected, "Valid call result ($comment)";

    if ( not ref $expected ) {
        is "$callable" => $expected, "Valid interpolation result ($comment)";
    }
}

subtest 'Make subroutine callable' => sub {
    plan tests => 2;

    test_callable( sub { 'foo' } => 'foo' );
};

subtest 'Make scalar callable' => sub {
    plan tests => 9;

    my $source   = 'foo';
    my $callable = Callable->new($source);

    test_callable( 'foo'      => 'main:foo', 'scalar without package' );
    test_callable( 'Foo::foo' => 'Foo:foo',  'scalar with package' );
    test_callable( Foo::with_package() => 'Foo:foo', 'Foo::with_package' );
    test_callable(
        Foo::without_package() => 'main:foo',
        'Foo::without_package'
    );

    $source   = 'not_existing_subroutine';
    $callable = Callable->new($source);
    dies_ok { $callable->() }, 'Unable to call not existing';
};
