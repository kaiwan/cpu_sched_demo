/*
 * sched_pthrd_rtprio.c
 * (c) Kaiwan NB, kaiwanTECH.
 * License: MIT
 */
#include <stdio.h>
#include <unistd.h>
#include <pthread.h>
#include <stdlib.h>
#include "libpk.h"

/*
 * Undefine to switch off debug messages emitted via our MSG() macro
 * Typically do the -DDEBUG or -UDEBUG within the Makefile to avoid hard-coding it..
 * Here, we do hardcode it to be defined as otherwise the helpful prints won't
 * appear...
 */
#define DEBUG
#ifdef DEBUG
#define MSG(string, args...) fprintf(stderr, "%s:%s : " string, __FILE__, __func__, ##args)
#else
#define MSG(string, args...)
#endif

/* This thread runs with SCHED_FIFO policy and RT prio as passed */
void *thrd_p2(void *msg)
{
	struct sched_param p;
	/* The structure used is defined in linux/sched.h as:
	 * struct sched_param {
	 *      int sched_priority;
	 * };
	 */
	printf("  RT Thread p2 (LWP %d) here in function %s()\n"
			"   setting sched policy to SCHED_FIFO and RT priority to %ld in 2 seconds..\n",
				getpid(), __func__, (long)msg);
	sleep(2);

	/* pthread_setschedparam(3) internally becomes the syscall sched_setscheduler(2)) */
	p.sched_priority = (long)msg;
	if (pthread_setschedparam(pthread_self(), SCHED_FIFO, &p))
		perror("pthread_setschedparam");

	puts("  p2: working");
	DELAY_LOOP('2', 350);

	puts("  p2: exiting..");
	pthread_exit(NULL);
}

/* This thread runs with SCHED_FIFO policy and thrd_p2's RT prio + 10 ! */
void *thrd_p3(void *msg)
{
	struct sched_param p;
	/* The structure used is defined in linux/sched.h as:
	 * struct sched_param {
	 *      int sched_priority;
	 * };
	 */
	long pri = (long)msg;

	pri += 10;
	printf("  RT Thread p3 (LWP %d) here in function %s()\n"
	       " setting sched policy to SCHED_FIFO and RT priority HIGHER to %ld in 4 seconds..\n",
	       getpid(), __func__, pri);

	/* pthread_setschedparam(3) internally becomes the syscall sched_setscheduler(2))
	 * Used strace to figure this out!
     *  sudo taskset 02 strace -f ./sched_pthrd_rtprio 7 2>strc.txt
	 */
	p.sched_priority = pri;
	if (pthread_setschedparam(pthread_self(), SCHED_FIFO, &p))
		perror("pthread_setschedparam");
	sleep(4); /* blocking call; allow other thread(s) to run... */

	puts("  p3: working");
	DELAY_LOOP('3', 210);

	puts("  p3: exiting..");
	pthread_exit(NULL);
}

/* main() runs with SCHED_OTHER policy and RT prio of 0, by default */
int main(int argc, char **argv)
{
	pthread_t p2, p3;
	int r, min, max;
	long rt_pri = 1;

	if (argc == 1)
		fprintf(stderr, "Usage: %s realtime-priority\n",
			argv[0]), exit(1);
	min = sched_get_priority_min(SCHED_FIFO);
	if (min == -1) {
		perror("sched_get_priority_min failure");
		exit(1);
	}
	max = sched_get_priority_max(SCHED_FIFO);
	if (max == -1) {
		perror("sched_get_priority_max failure");
		exit(1);
	}
	MSG("SCHED_FIFO priority range is %d to %d\n", min, max);

	rt_pri = atoi(argv[1]); // TODO: better to use strtoul(3) for better checking/IoF ...
	if ((rt_pri < min) || (rt_pri > (max - 10))) {
		fprintf(stderr,
			"%s: Priority value passed (%ld) out of range [%d-%d].\n",
			argv[0], rt_pri, min, (max - 10));
		exit(1);
	}

	printf("\nNote: to create true (soft) RT threads, and have it run as expected, you need to:\n\
	1. Run this program as superuser -OR- have the capability CAP_SYS_NICE (better!)\n\
	2. Ensure it runs on a single CPU core (use, f.e., taskset -c02 <prg-name>)\n");
	printf("%s() thread (%d): now creating realtime pthread p2..\n",
	       __func__, getpid());
	r = pthread_create(&p2,	// thread id
			   NULL,	// thread attributes (use default)
			   thrd_p2,	// function to execute
			   (void *)rt_pri);	// argument to function
	if (r)
		perror("pthread creation"), exit(1);

	printf("%s() thread (%d): now creating realtime pthread p3..\n",
	       __func__, getpid());
	r = pthread_create(&p3,	// thread id
			   NULL,	// thread attributes (use default)
			   thrd_p3,	// function to execute
			   (void *)rt_pri);	// argument to function
	if (r)
		perror("pthread creation"), exit(1);

	DELAY_LOOP('m', 400);
	pthread_exit(NULL);
}
