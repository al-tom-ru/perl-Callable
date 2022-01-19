use 5.010;
use strict;
use utf8;
use warnings;

use Test::More tests => 5;

use Test::Exception;

use_ok 'Callable';

sub foo { 'main:foo' }
sub bar { ( $_[0] // '' ) eq __PACKAGE__ ? 'main:bar' : 'Bad method call' }

{

    package Foo;

    use Callable;

    sub foo { 'Foo:foo' }
    sub bar { ( $_[0] // '' ) eq __PACKAGE__ ? 'Foo:bar' : 'Bad method call' }
    sub with_package           { Callable->new('Foo::foo') }
    sub without_package        { Callable->new('foo'); }
    sub method_with_package    { Callable->new('Foo->bar') }
    sub method_without_package { Callable->new('->bar') }
}

{

    package Class;

    use Carp qw(croak);

    sub new         { bless [@_], __PACKAGE__ }
    sub constructor { bless [@_], __PACKAGE__ }

    sub foo {
        croak 'Bad instance method call' unless $_[0]->isa(__PACKAGE__);
        'Class:foo';
    }

    sub bar {
        croak 'Bad instance method call' unless $_[0]->isa(__PACKAGE__);
        my @args = @{ $_[0] };
        'Class:bar:' . join( ',', splice( @args, 1 ) );
    }
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
    plan tests => 13;

    test_callable( 'foo'      => 'main:foo', 'scalar without package' );
    test_callable( 'Foo::foo' => 'Foo:foo',  'scalar with package' );

    test_callable( Foo::with_package() => 'Foo:foo', 'with_package' );
    test_callable(
        Foo::without_package() => 'main:foo',
        'without_package'
    );

    test_callable(
        Foo::method_with_package() => 'Foo:bar',
        'method_with_package'
    );
    test_callable(
        Foo::method_without_package() => 'main:bar',
        'method_without_package'
    );

    my $source   = 'not_existing_subroutine';
    my $callable = Callable->new($source);
    dies_ok { $callable->() }, 'Unable to call not existing';
};

subtest 'Make instance callable' => sub {
    plan tests => 2;

    test_callable(
        [ Class->new(), 'foo' ] => 'Class:foo',
        'instance as source'
    );
};

subtest 'Make class callable' => sub {
    plan tests => 6;

    test_callable( [ Class => 'foo' ] => 'Class:foo', 'class name as source' );
    test_callable(
        [ 'Class->constructor' => 'foo' ] => 'Class:foo',
        'class name with constructor as source'
    );

    test_callable(
        [ Class => 'bar', 'foo', 'bar' ] => 'Class:bar:foo,bar',
        'class name with constructor args'
    );
};
