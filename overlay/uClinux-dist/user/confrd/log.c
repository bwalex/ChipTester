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
#include "confrd.h"
#include "de2lcd_if.h"


extern char *cur_filename;
extern int cur_lineno;
extern int wflag;

extern char *base_url;


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

	if (loglevel == LOGERR) {
		fprintf(stderr, "%s\n", msgbuf);
		/* We also log errors to the LCD */
		de2lcd_printf(msgbuf);
	} else {
		printf("%s\n", msgbuf);
	}

	if (!wflag || base_url == NULL)
		goto out;

	/*
	 * Do our best to log remotely, but fail silently if it
	 * doesn't work out.
	 */
	j_in = json_pack("{s:i,s:s,s:i,s:s}",
			 "type", loglevel,
			 "file", cur_filename,
			 "line", cur_lineno,
			 "message", msgbuf);
	if (j_in == NULL)
		goto out;

	snprintf(urlbuf, sizeof(urlbuf), "%s/api/log", base_url);
	req_json(urlbuf, METHOD_POST, j_in, NULL);

out:
	active = 0;
	return;
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

