/**
 * The module tcmallocd.allocator proposes some typed D allocators
 * based on Google Thread Caching mallocators.
 * ($(REF https://github.com/gperftools/gperftools)).
 */
module tcmallocd.allocator;

import std.experimental.allocator.common;

/**
 * The struct TCMallocator is a typed D allocator, similar to Mallocator.
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
     * obtained with a Thread Caching allocator (generally speaking).
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

/**
 * The struct TCAlignedMallocator is a typed D allocator, similar to
 * AlignedMallocator.
 */
struct TCAlignedMallocator
{
    /**
     * The alignment is a static constant equal to $(D platformAlignment), which
     * ensures proper alignment for any D data type.
     */
    enum uint alignment = platformAlignment;

    /**
     * Forwards to $(D alignedAllocate(bytes, platformAlignment)).
     */
    @trusted @nogc nothrow
    void[] allocate(size_t size) shared
    {
        if (!size)
            return null;
        else
            return alignedAllocate(size, alignment);
    }

    /**
     * Tries to allocate an aligned chunk of bytes.
     *
     * Params:
     *      size = The count of byte to allocates.
     *      a = The alignment.
     */
    @trusted @nogc nothrow
    void[] alignedAllocate(size_t size, uint a) shared
    in
    {
        //assert(a.isGoodDynamicAlignment);
    }
    body
    {
        import tcmallocd.itf: tc_posix_memalign;
        import core.stdc.errno : ENOMEM, EINVAL;

        void* result;
        auto code = tc_posix_memalign(&result, a, size);
        if (code == ENOMEM)
            return null;

        else if (code == EINVAL)
            assert (0, "AlignedMallocator.alignment is not a power of two multiple of (void*).sizeof, according to posix_memalign!");

        else if (code != 0)
            assert (0, "posix_memalign returned an unknown code!");

        else
            return result[0 .. size];
    }

    /**
     * Deallocates a `void[]` buffer previously obtained with
     * `TCAlignedMallocator.allocate()`.
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
        return TCMallocator.instance.deallocate(buffer);
    }

    /**
     * Resize a `void[]` buffer previously obtained with
     * `TCAlignedMallocator.allocate()`.
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
        return TCMallocator.instance.reallocate(buffer, size);
    }

    /**
     * See `TCMallocator.bound()`.
     */
    @trusted @nogc nothrow
    size_t bound(void[] buffer) shared
    {
        return TCMallocator.instance.bound(buffer);
    }

    /**
     * Returns the global instance of this allocator type.
     */
    static shared TCAlignedMallocator instance;
}
///
@nogc nothrow unittest
{
    void[] chunk;
    chunk = TCAlignedMallocator.instance.alignedAllocate(16, 256);
    assert(chunk.ptr);
    assert((cast(size_t)chunk.ptr & 0xFF) == 0);
    assert(TCAlignedMallocator.instance.bound(chunk) == 256);
    TCAlignedMallocator.instance.deallocate(chunk);
    assert(!chunk.ptr);
}

