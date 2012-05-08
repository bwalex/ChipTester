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

#include "sram.h"
#include "confrd.h"
#include "trunner_if.h"


static int parse_line_team(char *, void *);


struct keyword meta_keywords[] = {
	{ .keyword = "team"	  , .lp = parse_line_team       },
	/* XXX: email, etc */
	{ .keyword = NULL	  , .lp = NULL }
};



extern char *cur_filename;
extern int cur_lineno;


static
int
parse_line_team(char *s, void *priv)
{
	globaldata_t gd = priv;
	char *e;

	gd->team_no = (int)strtol(s, &e, 10);
	if (s == e || *e != '\0') {
		syntax_error("team number must contain only "
		    "decimal digits");
		return -1;
	}

	gd->team_no &= DESIGN_NUMBER_MASK;

	return 0;
}


int
parse_cfg_file(char *filename, globaldata_t gd, parserinfo_t pi)
{
	FILE *fp;
	int rc = 0;

	fp = fopen(filename, "r");
	if (fp == NULL) {
		logger(LOGERR, "The file %s cannot be opened: %s",
		    filename, strerror(errno));
		return -1;
	}

	gd->team_no = -1;

	rc = parse_file(filename, fp, meta_keywords, NULL, gd);
	if (rc)
		goto out;

	if (gd->team_no < 0) {
		syntax_error("No team number specified in cfg file %s",
		    filename);
		rc = -1;
		goto out;
	}

out:
	fclose(fp);
	return rc;
}
