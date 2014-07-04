
#include <stdio.h>

int main(void)
{
    puts("Hello, world");

    for (;;)
        ++*(unsigned char*)0xd020;
}
