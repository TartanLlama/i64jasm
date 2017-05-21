char* mymemcpy(char* dest, char* src, int n) {
    for (int i = 0; i < n; ++i) {
        dest[i] = src[i];
    }
    return dest;
}


typedef struct {
    char* string;
    int len;
} StrBuffer;

#include <string.h>

void my_addToString(void* buffer, char* str) {
    StrBuffer* sb = (StrBuffer*)buffer;
    int len = strlen(str);

    memcpy(sb->string + sb->len, str, len+1);
    sb->len += len;
}

typedef struct {
    int size;
    unsigned char* data;
} Buffer;

void* my_getBufferDataPtr(void* buffer) {
    return ((Buffer*)buffer)->data;
}
