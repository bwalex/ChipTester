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

#include <jansson.h>

#include "http_json.h"

#define LOGDEBUG                1
#define LOGINFO                 2
#define LOGWARN                 3
#define LOGERR                  4


const char *base_url = NULL;

static
void
vlog(int loglevel, const char *fmt, va_list ap)
{
	static int active;
	char urlbuf[512];
	char msgbuf[4096];
	json_t *j_in;

	/* Don't allow vlog recursion */
	if (active)
		return;

	active = 1;
	vsnprintf(msgbuf, sizeof(msgbuf), fmt, ap);

	if (loglevel == LOGERR)
		fprintf(stderr, "%s\n", msgbuf);
	else
		printf("%s\n", msgbuf);

	/*
	 * Do our best to log remotely, but fail silently if it
	 * doesn't work out.
	 */
	j_in = json_pack("{s:i,s:s,s:i,s:s}",
			 "type", loglevel,
			 "file", "rlog",
			 "line", "0",
			 "message", msgbuf);
	if (j_in == NULL)
		goto out;

	snprintf(urlbuf, sizeof(urlbuf), "%s/api/log", base_url);
	req_json(urlbuf, METHOD_POST, j_in, NULL);

out:
	active = 0;
	return;
}

static
void
logger(int loglevel, const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	vlog(loglevel, fmt, ap);
	va_end(ap);
}


static
void
usage(int exitval)
{
	fprintf(stderr,
	    "Usage: rlog [-l <level>] -b <base_url> <message>\n");

	exit(exitval);
}


int
main(int argc, char *argv[])
{
	int c;
	int loglevel = LOGINFO;

	while ((c = getopt (argc, argv, "b:l:h?")) != -1) {
		switch(c) {
		case 'b':
			base_url = optarg;
			break;

		case 'l':
			if (strcmp(optarg, "info") == 0)
				loglevel = LOGINFO;
			else if (strcmp(optarg, "debug") == 0)
				loglevel = LOGDEBUG;
			else if (strcmp(optarg, "warn") == 0)
				loglevel = LOGWARN;
			else if (strcmp(optarg, "err") == 0)
				loglevel = LOGERR;
			else
				usage(1);
			break;

		case 'h':
		case '?':
			usage(0);
			/* NOT REACHED */

		default:
			usage(1);
			/* NOT REACHED */
		}
	}

	argc -= optind;
	argv += optind;

	if (base_url == NULL) {
		usage(1);
		/* NOT REACHED */
	}

	if (argc < 1) {
		usage(1);
		/* NOT REACHED */
	}

	http_begin();

	logger(loglevel, "%s", argv[0]);

	http_end();

	return 0;
}
