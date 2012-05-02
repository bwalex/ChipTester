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

#include "fcounter_if.h"


static
void
usage(int exitval)
{
	fprintf(stderr,
		"Usage: fcounter <options>\n"
		"Valid options are:\n"
		" -m\n"
		"\t Get magic number.\n"
		" -e\n"
		"\t Enable.\n"
		" -f\n"
		"\t Print cycle count.\n"
		" -a\n"
		"\t Print cycle count (alt).\n"
		" -c <cycles>\n"
		"\t Set timeout <cycles>.\n"
		" -s <sel>\n"
		"\t Select <sel> line as input.\n"
		);

	exit(exitval);
}


int
main(int argc, char *argv[])
{
	int c;
	int error;
	uint32_t d;


	while ((c = getopt (argc, argv, "amefc:s:h?")) != -1) {
		switch (c) {
		case 'm':
			fcounter_print_magic();
			break;

		case 'e':
			printf("Enabling.\n");
			fcounter_enable();
			printf("Waiting for completion\n");
			fcounter_wait_done();
			break;

		case 'f':
			error = fcounter_get_count(&d);
			if (error)
				fprintf(stderr, "fcounter_get_count error\n");
			else
				printf("Cycles: %u\n", d);
			break;

		case 'a':
			error = fcounter_read_count(&d);
			if (error)
				fprintf(stderr, "fcounter_read_count error\n");
			else
				printf("Cycles: %u\n", d);
			break;

		case 'c':
			d = (uint32_t)atol(optarg);
			fcounter_set_cycles(d);
			break;

		case 's':
			d = (uint32_t)atol(optarg);
			fcounter_select(d);
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
