module tcmallocd.allocator;

import std.experimental.allocator.common;

/**
 * The struct TCMallocator is a typed D allocator, similar to Mallocator except
 * that it's based on the high performance mallocator functions from Google
 * ($(REF https://github.com/gperftools/gperftools)).
 */
struct TCMallocator
{
    /**
     * The alignment is a static constant equal to $(D platformAlignment), which
     * ensures proper alignment for any D data type.
     */
    enum uint alignment = platformAlignment;

    /**
     * Tries to to allocate $(D_PARAM size) bytes.
     *
     * Params:
     *      size = The count of byte to allocates.
     *
     * Returns:
     *      a `null` if the allocation fails otherwise a `void[]` array.
     */
    @trusted @nogc nothrow
    void[] allocate(size_t size) shared
    {
        if (!size)
            return null;
        import tcmallocd.itf: tc_malloc;
        auto p = tc_malloc(size);
        return p ? p[0 .. size] : null;
    }

    /**
     * Deallocates a `void[]` buffer previously obtained with
     * `TCMallocator.allocate()`.
     *
     * Params:
     *      buffer = The `void[]` array to deallocate.
     *
     * Returns:
     *      always true.
     */
    @system @nogc nothrow
    bool deallocate(ref void[] buffer) shared
    {
        import tcmallocd.itf: tc_free;
        tc_free(buffer.ptr);
        buffer = null;
        return true;
    }

    /**
     * Resize a `void[]` buffer previously obtained with
     * `TCMallocator.allocate()`.
     *
     * Params:
     *      buffer = The `void[]` array to resize.
     *      size = The new size.
     *
     * Returns:
     *      false if the reallocation fails, otherwise true.
     */
    @system @nogc nothrow
    bool reallocate(ref void[] buffer, size_t size) shared
    {
        if (!size)
            return deallocate(buffer);

        import tcmallocd.itf: tc_realloc;
        void* p = tc_realloc(buffer.ptr, size);
        if (!p)
            return false;
        buffer = p[0 .. size];
        return true;
    }

    /**
     * Allows to retrieve the real bound of a buffer previously
     * obtained with `TCMallocator.allocate()`.
     *
     * Params:
     *      buffer = The `void[]` array whose size is to retrieve.
     *
     * Returns:
     *      `0` is $(D_PARAM buffer) is null or not allocated with TCMallocator,
     *      otherwise the real size of the memory chunk, which may be greater
     *      of the size initially requested.
     */
    @trusted @nogc nothrow
    size_t bound(void[] buffer) shared
    {
        import tcmallocd.itf: tc_malloc_size;
        if (!buffer.ptr)
            return 0;
        else
            return tc_malloc_size(buffer.ptr);
    }

    /**
     * Returns the global instance of this allocator type.
     */
    static shared TCMallocator instance;
}
///
@nogc nothrow unittest
{
    void[] chunk;
    chunk = TCMallocator.instance.allocate(32);
    assert(chunk.ptr);
    assert(chunk.length == 32);
    TCMallocator.instance.reallocate(chunk, 0);
    assert(!chunk.ptr);
    chunk = TCMallocator.instance.allocate(32);
    assert(chunk.ptr);
    assert(chunk.length == 32);
    TCMallocator.instance.reallocate(chunk, 64);
    assert(chunk.ptr);
    assert(chunk.length == 64);
    TCMallocator.instance.deallocate(chunk);
    assert(!chunk.ptr);
    chunk = TCMallocator.instance.allocate(15);
    assert(chunk.ptr);
    assert(TCMallocator.instance.bound(chunk) == 16);
    TCMallocator.instance.deallocate(chunk);
    assert(!chunk.ptr);
}

