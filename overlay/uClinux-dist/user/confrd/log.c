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


#include "confrd.h"


extern char *cur_filename;
extern int cur_lineno;


void
vlog(int loglevel, const char *fmt, va_list ap)
{
	char msgbuf[4096];

	vsnprintf(msgbuf, sizeof(msgbuf), fmt, ap);

	if (loglevel == LOGERR)
		fprintf(stderr, "%s\n", msgbuf);
	else
		printf("%s\n", msgbuf);

	/* XXX: add remote logging */
}


void
logger(int loglevel, const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	vlog(loglevel, fmt, ap);
	va_end(ap);
}


void
syntax_error(const char *fmt, ...)
{
	char msgbuf[4096];
	va_list ap;

	va_start(ap, fmt);
	vsnprintf(msgbuf, sizeof(msgbuf), fmt, ap);
	va_end(ap);

	logger(LOGERR, "%s:%d syntax error: %s", cur_filename, cur_lineno, msgbuf);
}

