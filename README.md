# DISCLAIMER

Sorry for my English ...

# NAME

Callable - make different things callable

# SYNOPSIS

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

# DESCRIPTION

Callable is a simple wrapper for make subroutines from different sources.
Can be used in applications with configurable callback maps (e.g. website router config).
Inspired by PHP's [callable](https://www.php.net/manual/ru/language.types.callable.php)

# LICENSE

Copyright (C) Al Tom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Al Tom <al-tom.ru@yandex.ru>
