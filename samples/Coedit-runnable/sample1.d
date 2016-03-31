#!runnable-flags: -L-ltcmalloc
module runnable;

import tcmallocd.itf;
import tcmallocd.allocator;
import std.experimental.allocator;

class Foo
{
    uint a;
}

void main(string[] args)
{
    import std.stdio, std.string: fromStringz;
    writeln(fromStringz(tc_version(null,null,null)));

    auto p = tc_malloc(27);
    if (p)
    {
        writeln(tc_malloc_size(p));
        tc_free(p);
    }

    Foo foo = make!Foo(TCMallocator.instance);
    dispose(TCMallocator.instance, foo);
}
