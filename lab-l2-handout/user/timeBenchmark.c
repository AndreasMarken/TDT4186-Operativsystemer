#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    int totalTicks = 0;

    int i;
    for (i = 0; i < 10; i++) {
        int startticks = uptime();

        // we now start the program in a separate process:
        int uutPid = fork();

        // check if fork worked:
        if (uutPid < 0)
        {
            printf("fork failed... couldn't start %s", argv[1]);
            exit(1);
        }

        if (uutPid == 0)
        {
            // we are the unit under test part of the program - execute the program immediately
            exec(argv[1], argv + 1); // pass rest of the command line to the executable as args
        }
        else
        {
            // we are the timer process
            // wait for the uut to finish
            wait(0);
            int endticks = uptime();
            totalTicks += endticks - startticks;
            printf("Executing %s took %d ticks\n", argv[1], endticks - startticks);
        }
    }
    printf("Executing took a total of %d ticks\n", totalTicks);
    printf("Average execution time was %d ticks\n", totalTicks / 10);
    exit(0);
}