module tcmallocd.itf;

extern(C) @nogc nothrow:

const (char*) tc_version(int* major, int* minor, const char** patch);

void*   tc_malloc(size_t size);
void*   tc_malloc_skip_new_handler(size_t size);
void    tc_free(void* ptr);
void    tc_free_sized(void *ptr, size_t size);
void*   tc_realloc(void* ptr, size_t size);
void*   tc_calloc(size_t nmemb, size_t size);
void    tc_cfree(void* ptr);
void*   tc_memalign(size_t __alignment, size_t __size);
int     tc_posix_memalign(void** ptr, size_t alignment, size_t size);
void*   tc_valloc(size_t __size);
void*   tc_pvalloc(size_t __size);
int     tc_mallopt(int cmd, int value);
size_t  tc_malloc_size(void* ptr);

