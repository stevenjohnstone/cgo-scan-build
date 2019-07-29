#include <stdio.h>
#include <stdlib.h>

void foo() {
    puts("foo\n");
    char *buf = malloc(1);
    buf[1] = 0;
}
