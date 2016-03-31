## tcmallocd

D bindings of the high performance mallocator functions from the [Google performance tools](https://github.com/gperftools/gperftools).

## setup

- clone
- `dub build --build=release --config=lib`.
- in Coedit, after compilation from the UI, use the _book-link_ icon to register in the _libman_.

## usage

- linux only
- _libtcmalloc_ must be setup as a static library.
- `tcmallocd.itf`: contains the C functions.
- `tcmallocd.allocator`: contains a typed D allocator similar to _Mallocator_.

## license

- MIT
