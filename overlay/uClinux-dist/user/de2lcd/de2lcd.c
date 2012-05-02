#include <sys/types.h>
#include <stdio.h>
#include <limits.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <assert.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>
#include <getopt.h>
#include <time.h>

#include "de2lcd_if.h"


static
void
usage(int exitval)
{
	fprintf(stderr,
		"Usage: de2lcd <options>\n"
		"Valid options are:\n"
		" -c\n"
		"\t Clear LCD.\n"
		" -n\n"
		"\t Enable blinking cursor.\n"
		" -f\n"
		"\t Disable blinking cursor.\n"
		" -s <miliseconds>\n"
		"\t Enable left shift every <miliseconds> ms\n"
		" -t\n"
		"\t Test.\n"
		" -w <Text>\n"
		"\t Writes <Text> starting at first character of LCD\n"
		);

	exit(exitval);
}


int
main(int argc, char *argv[])
{
	int c, ms;


	while ((c = getopt (argc, argv, "cfns:tw:h?")) != -1) {
		switch (c) {
		case 'c':
			de2lcd_clear();
			break;

		case 'f':
			de2lcd_cursor_off();
			break;

		case 'n':
			de2lcd_cursor_on();
			break;

		case 's':
			ms = atoi(optarg);
			de2lcd_set_shl(ms);
			break;

		case 't':
			de2lcd_test();
			break;

		case 'w':
			de2lcd_write(optarg);
			break;

		case '?':
		case 'h':
			usage(0);
			/* NOT REACHED */

		default:
			usage(1);
			/* NOT REACHED */
		}
	}

	argc -= optind;
	argv += optind;

	return 0;
}
