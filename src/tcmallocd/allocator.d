module tcmallocd.allocator;

import std.experimental.allocator.common;

/**
 * The struct TCMallocator is similar to Mallocator except that it's based
 * on the high performance mallocator from Google
 * ($(REF https://github.com/gperftools/gperftools)).
 */
struct TCMallocator
{
    unittest
    {
        //import std.experimental.allocator: testAllocator;
        //testAllocator!(() => TCMallocator.instance);
    }

    /**
    The alignment is a static constant equal to $(D platformAlignment), which
    ensures proper alignment for any D data type.
    */
    enum uint alignment = platformAlignment;

    /**
    Standard allocator methods per the semantics defined above. The
    $(D deallocate) and $(D reallocate) methods are $(D @system) because they
    may move memory around, leaving dangling pointers in user code. Somewhat
    paradoxically, $(D malloc) is $(D @safe) but that's only useful to safe
    programs that can afford to leak memory allocated.
    */
    @trusted @nogc nothrow
    void[] allocate(size_t bytes) shared
    {
        import tcmallocd.itf: tc_malloc;
        if (!bytes) return null;
        auto p = tc_malloc(bytes);
        return p ? p[0 .. bytes] : null;
    }

    /// Ditto
    @system @nogc nothrow
    bool deallocate(void[] b) shared
    {
        import tcmallocd.itf: tc_free;
        tc_free(b.ptr);
        return true;
    }

    /// Ditto
    @system @nogc nothrow
    bool reallocate(ref void[] b, size_t s) shared
    {
        if (!s)
        {
            // fuzzy area in the C standard, see http://goo.gl/ZpWeSE
            // so just deallocate and nullify the pointer
            deallocate(b);
            b = null;
            return true;
        }
        import tcmallocd.itf: tc_realloc;
        auto p = cast(ubyte*) tc_realloc(b.ptr, s);
        if (!p) return false;
        b = p[0 .. s];
        return true;
    }

    /**
    Returns the global instance of this allocator type. The C heap allocator is
    thread-safe, therefore all of its methods and `it` itself are
    $(D shared).
    */
    static shared TCMallocator instance;
}

