package Callable;

use 5.010;
use strict;
use utf8;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);

use overload '&{}' => 'to_sub', '""' => 'to_string';
use constant ( USAGE =>
'Usage: Callable->new(&|$|[object|"class"|"class->constructor", "method"])'
);

our $VERSION = "0.01";

our $DEFAULT_CLASS_CONSTRUCTOR = 'new';

sub new {
    my ( $class, @options ) = @_;

    if (   @options
        && blessed( $options[0] )
        && $options[0]->isa(__PACKAGE__) )
    {
        return $options[0]->clone( splice @options, 1 );
    }

    my $self = bless { options => \@options }, $class;
    $self->_validate_options();

    return $self;
}

sub clone {
    my ( $self, @options ) = @_;

    if (@options) {
        unshift @options, $self->{options}->[0];
    }
    else {
        @options = @{ $self->{options} };
    }

    return bless { options => \@options }, ref($self);
}

sub to_sub {
    my ( $self, $caller ) = @_;

    $caller //= caller;

    return $self->_handler($caller);
}

sub to_string {
    my ($self) = @_;

    return $self->to_sub( scalar caller )->();
}

sub _first_arg {
    my ( $self, $value ) = @_;

    if ( @_ > 1 ) {
        $self->{__first_arg} = $value;
    }

    if (wantarray) {
        return unless exists $self->{__first_arg};
        return ( $self->{__first_arg} );
    }

    return $self->{__first_arg} // undef;
}

sub _handler {
    my ( $self, $caller ) = @_;

    unless ( exists $self->{__handler} ) {
        $self->{__handler} = $self->_make_handler($caller);
    }

    return $self->{__handler};
}

sub _make_handler {
    my ( $self, $caller ) = @_;

    my ( $source, @default_args ) = @{ $self->{options} };
    my $ref = ref $source;

    my $handler =
      $ref eq 'CODE' ? $source
      : (
          $ref eq 'ARRAY' ? $self->_make_object_handler( $source, $caller )
        : $self->_make_scalar_handler( $source, $caller )
      );
    my @args = ( $self->_first_arg, @default_args );

    if (@args) {
        my $inner = $handler;
        $handler = sub { $inner->(@args, @_) };
    }

    return $handler;
}

sub _make_object_handler {
    my ( $self, $source, $caller ) = @_;

    my ( $object, $method, @args ) = @{$source};

    unless ( blessed $object) {
        my ( $class, $constructor, $garbage ) = split /\Q->\E/, $object;

        croak "Wrong class name format: $object" if defined $garbage;

        $constructor //= $DEFAULT_CLASS_CONSTRUCTOR;

        $object = $class->$constructor(@args);
    }

    $self->_first_arg($object);

    return $object->can($method);
}

sub _make_scalar_handler {
    my ( $self, $name, $caller ) = @_;

    my @path = split /\Q->\E/, $name;
    croak "Wrong subroutine name format: $name" if @path > 2;

    if ( @path == 2 ) {
        $path[0] ||= $caller;
        $self->_first_arg( $path[0] );
        $name = join '::', @path;
    }

    @path = split /::/, $name;

    if ( @path == 1 ) {
        unshift @path, $caller;
    }

    $name = join( '::', @path );
    my $handler = \&{$name};

    croak "Unable to find subroutine: $name" if not $handler;

    return $handler;
}

sub _validate_options {
    my ($self) = @_;

    croak USAGE unless @{ $self->{options} };

    my $source = $self->{options}->[0];
    my $ref    = ref($source);
    croak USAGE unless $ref eq 'CODE' || $ref eq 'ARRAY' || $ref eq '';

    if ( $ref eq 'ARRAY' ) {
        croak USAGE if @{$source} < 2;
        croak USAGE unless blessed $source->[0] || ref( $source->[0] ) eq '';
        croak USAGE if ref $source->[1];
    }
}

1;
__END__

=encoding utf-8

=head1 DISCLAIMER

Sorry for my English ...

=head1 NAME

Callable - make different things callable

=head1 SYNOPSIS

    use Callable;

    {
        package Some::Module;

        sub some_function {
            return 'some_value';
        }
    }

    my $handler = Callable->new('Some::Module::some_function');
    my $value = $handler->();
    print $value; # some_value

=head1 DESCRIPTION

Callable is a simple wrapper for make subroutines from different sources.
Can be used in applications with configurable callback maps (e.g. website router config).
Inspired by PHP's L<callable|https://www.php.net/manual/ru/language.types.callable.php>

=head1 LICENSE

Copyright (C) Al Tom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Al Tom E<lt>al-tom.ru@yandex.ruE<gt>

=cut

