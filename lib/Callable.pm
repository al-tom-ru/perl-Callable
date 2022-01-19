package Callable;

use 5.010;
use strict;
use utf8;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);

use overload '&{}' => 'to_sub', '""' => 'to_string';
use constant ( USAGE => 'Usage: Callable->new(sub { ... } | "subroutine_name")',
);

our $VERSION = "0.01";

sub new {
    my ( $class, @options ) = @_;

    if (   @options == 1
        && blessed( $options[0] )
        && $options[0]->isa(__PACKAGE__) )
    {
        return $options[0]->clone;
    }

    my $self = bless { options => \@options }, $class;
    $self->_validate_options();

    return $self;
}

sub clone {
    my ($self) = @_;

    return bless { options => $self->{options} }, ref($self);
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

    my $source = $self->{options}->[0];
    my $ref    = ref $source;

    my $handler =
        $ref eq 'CODE'
      ? $source
      : $self->_make_scalar_handler( $source, $caller );
    my @args = $self->_first_arg;

    if (@args) {
        my $inner = $handler;
        $handler = sub { $inner->(@args) };
    }

    return $handler;
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

    croak USAGE unless @{ $self->{options} } == 1;

    my $source = $self->{options}->[0];
    my $ref    = ref($source);
    croak USAGE
      unless $ref eq 'CODE'
      || $ref eq ''
      || ( blessed $source && $source->isa(__PACKAGE__) );
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

