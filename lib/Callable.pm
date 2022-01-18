package Callable;

use 5.010;
use strict;
use utf8;
use warnings;

use Carp qw(croak);

use overload '&{}' => 'to_sub', '""' => 'to_string';
use constant ( USAGE => 'Usage: Callable->new(sub { ... })', );

our $VERSION = "0.01";

sub new {
    my ( $class, @options ) = @_;

    my $self = bless { options => \@options }, $class;
    $self->_validate_options();

    return $self;
}

sub to_sub {
    my ($self) = @_;

    return $self->_handler;
}

sub to_string {
    my ($self) = @_;

    return $self->to_sub()->();
}

sub _handler {
    my ($self) = @_;

    unless ( exists $self->{__handler} ) {
        $self->{__handler} = $self->_make_handler();
    }

    return $self->{__handler};
}

sub _make_handler {
    my ($self) = @_;

    return $self->{options}->[0];
}

sub _validate_options {
    my ($self) = @_;

    croak USAGE unless @{ $self->{options} } == 1;

    croak USAGE unless ref( $self->{options}->[0] ) eq 'CODE';
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

