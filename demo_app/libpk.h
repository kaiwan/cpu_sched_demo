/*
 * libpk.h
 * Small collection of common routines for pthread programs;
 * kaiwan
 */
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <asm/param.h>		// HZ

static inline void beep(int what)
{
	char buf[2];

	buf[0] = (char)(what);
	buf[1] = '\0';
	write(STDOUT_FILENO, buf, 1);
}

/*
 * @val : ASCII value to print
 * @loop_count : times to loop around
 */
#define DELAY_LOOP(val, loop_count) \
{ \
	int c = 0;\
	unsigned int for_index, inner_index; \
	double x; \
	for (for_index = 0; for_index < loop_count; for_index++) { \
		beep((val)); \
		c++;\
		for (inner_index = 0; inner_index < HZ*100000; inner_index++) \
			x = (inner_index%2)*((22/7)%3); \
		} \
		/*printf("c=%d\n",c);*/\
}
