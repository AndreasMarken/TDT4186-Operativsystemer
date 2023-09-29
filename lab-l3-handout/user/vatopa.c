#include "kernel/types.h"
#include "user.h"

int main(int argc, char *argv[])
{
    uint64 pa = 0;
    if (argc > 3 || argc < 2)
    {
        printf("Usage: vatopa virtual_address [pid]\n");
        exit(1);
    }
    else if (argc == 3)
    {
        int pid = (*argv[2]) - '0';
        pa = va2pa(atoi(argv[1]), pid);
    } 
    else if (argc == 2)
    {
        int pid = getpid();
        pa = va2pa(*argv[1], pid);
    }
    

    printf("0x%x\n", pa);
    return pa;
}
