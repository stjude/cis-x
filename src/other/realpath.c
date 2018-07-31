#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "%s: missing operand\n", argv[0]);
        return EXIT_FAILURE;
    }

    for (int i = 1; i < argc; i++) {
        char *rp = realpath(argv[i], NULL);
        printf("%s\n", rp);
        free(rp);
    }

    return EXIT_SUCCESS;
}
