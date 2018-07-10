#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    char *rp = realpath(argv[1], NULL);
    printf("%s\n", rp);
    free(rp);
    return 0;
}
