#include <stdio.h>
#include <signal.h>
#include <stddef.h>

int main(void)
{
	struct sigaction sa;

	printf("%zd %zd\n%zd %zd\n%zd %zd\n%zd %zd\n",
		offsetof(struct sigaction, sa_handler), sizeof(sa.sa_handler), 
		offsetof(struct sigaction, sa_sigaction), sizeof(sa.sa_sigaction), 
		offsetof(struct sigaction, sa_mask), sizeof(sa.sa_mask), 
		offsetof(struct sigaction, sa_flags), sizeof(sa.sa_flags));

	return 0;
}
