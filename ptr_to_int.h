#include <stdint.h>

intptr_t ptr_to_int(void* ptr) {
    return (intptr_t)ptr;
}

char* mymemcpy(char* dest, char* src, int n);

void my_addToString(void* buffer, char* str);

void* my_getBufferDataPtr(void* buffer);
