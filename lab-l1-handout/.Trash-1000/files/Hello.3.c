#include <stdio.h>

int main(int argc, char *argv[]) {
    if (argc > 1) {
        printf("Hello %s, nice to meet you!\n", argv[1]);
    } else{
        printf("Hello World!\n");
    }
}
