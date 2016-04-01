## tcmallocd

This DUB package contains the D bindings of the _thread caching mallocator_ functions from the [Google performance tools](https://github.com/gperftools/gperftools).
It also contains typed D allocators, conform with the interface defined in the std.experimental.allocator.

## setup

- clone
- `dub build --build=release --config=lib`.
- if you use Coedit, after compilation from the UI, use the _book-link_ icon to register in the _libman_, then this library can be used in runnable modules by adding the script line `#!runnable-flags: -L-ltcmalloc` or in CE projects by adding the library alias `libtcmallocd`.

## usage

- Posix only
- _libtcmalloc_ must be setup as a static library, this can be done by installing the _gperftools_ development package for your distribution.
- the module `tcmallocd.itf` contains the definition C functions.
- the module `tcmallocd.allocator` contains typed D allocators.

## license

- MIT
