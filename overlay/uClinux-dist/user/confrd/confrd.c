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
#include "sram.h"
#include "trunner_if.h"



int pflag = 0;
int wflag = 0;
int sflag = 0;
char *sram_file = NULL;


char *cur_filename;
int cur_lineno;


static uint8_t sram_stage[SRAM_SIZE];


void *
stage_alloc_chunk(parserinfo_t pi, size_t sz)
{
	uint8_t *buf;

	if (pi->sram_free_bytes < sz + req_sz(REQ_END))
		return NULL;

	buf = &sram_stage[pi->sram_off];
	memset(buf, 0, sz);

	pi->sram_free_bytes -= sz;
	pi->sram_off += sz;

	return buf;
}


static
void
save_sram_file(uint8_t *buf, size_t sz)
{
	FILE *fp;
	size_t i;

	if ((fp = fopen(sram_file, "a")) == NULL) {
		perror("save_sram_file: fopen");
		return;
	}

	for (i = 0; i < sz; i += 2)
		fprintf(fp, "%.2x%.2x\n", buf[i], buf[i+1]);

	fclose(fp);
}


static
int
print_sram_results(void)
{
	uint8_t buf[256];
	size_t sz = 0;
	int error = 0;
	int done = 0;
	off_t off = 0;

	do {
		error = sram_read(off, buf, sizeof(buf));
		if (!error)
			sz = print_mem(buf, sizeof(buf), &done);

		off += sizeof(buf) - sz;
	} while(!error && !done);

	return (error && !done) ? -1 : 0;
}


int
emit(parserinfo_t pi, void *b, size_t bufsz)
{
	int rc = 0;

	if (bufsz == 0)
		return rc;

	return rc;
}


int
run_trunner(parserinfo_t pi)
{
	int error;

	if ((error = trunner_enable()) != 0)
		return error;

	if ((error = trunner_wait_done()) != 0)
		return error;

	print_sram_results();

	return 0;
}


int
suspend_emit(void *p)
{
	parserinfo_t pi = pi;
	int error;

	error = emit_end(pi);
	if (error != 0 && error != EAGAIN)
		return error;

	error = go(pi);
	if (error != 0)
		return error;

	/* Emit necessary restart code (XXX: presumably nothing) */
	/* Reset SRAM index and size */
	pi->sram_off = 0;
	pi->sram_free_bytes = SRAM_SIZE;

	return 0;
}


int
go(parserinfo_t pi)
{
	int error;

	if (pflag) {
		print_mem(sram_stage, (size_t)pi->sram_off, NULL);
	}

	if (sflag) {
		save_sram_file(sram_stage, (size_t)pi->sram_off);
	}

	if (wflag) {
		error = sram_write(0, sram_stage, (size_t)pi->sram_off);
		if (error)
			return error;

		return run_trunner(pi);
	}

	return 0;
}


static
int
parse_team_dir(char *dirname)
{
	struct globaldata gd;
	struct parserinfo pi;
	struct dirent *entry;
	DIR *dir;
	char fname[PATH_MAX];
	int error, rc;

	memset(&gd, 0, sizeof(gd));
	gd.team_no = -1;

	init_parserinfo(&pi);

	snprintf(fname, PATH_MAX, "%s/%s", dirname, "team.cfg");
	error = parse_cfg_file(fname, &gd, &pi);
	if (error) {
		logger(LOGERR, "Invalid configuration file: %s",
		    fname);
		return -1;
	}


	rc = emit_change_target(&pi, &gd);
	if (rc)
		return -1;

	if (!sflag || wflag) {
                /* Don't emit the end in the sflag mode */
		rc = emit_end(&pi);
		if (rc)
			return -1;
	}

	rc = go(&pi);
	if (rc != 0)
		return -1;

	dir = opendir(dirname);
	if (dir == NULL) {
		perror("opendir");
		return -1;
	}

	while ((entry = readdir(dir))) {
		if (entry->d_type != DT_REG)
			continue;

		if ((strcmp(entry->d_name, "team.cfg")) == 0)
			continue;

		init_parserinfo(&pi);
		snprintf(fname, PATH_MAX, "%s/%s", dirname, entry->d_name);
		logger(LOGINFO, "Processing %s", fname);

		if ((error = parse_vec_file(fname, suspend_emit, &pi)) != 0) {
			logger(LOGERR, "Error parsing %s", fname);
			continue;
		}
		if (wflag) {
			rc = run_trunner(&pi);
			if (rc)
				return -1;
		}
	}

	closedir(dir);

	return 0;
}


static
void
usage(int exitval)
{
	fprintf(stderr,
		"Usage: confrd [options] <configuration directory>\n"
		"Valid options are:\n"
		" -p\n"
		"\t Print out the data written to SRAM in a human readable form\n"
		"\t on screen.\n"
		" -s <file>\n"
		"\t Write an SRAM initialization file containing the data generated\n"
		"\t using the configuration file(s).\n"
		" -w\n"
		"\t Write to actual SRAM and start the test runner after reading\n"
		"\t a file.\n"
		);

	exit(exitval);
}


int
main(int argc, char *argv[])
{
	struct dirent *entry;
	DIR *mydir;
	char *rpath;
	char fname[PATH_MAX];
	int c, error;


	while ((c = getopt (argc, argv, "ps:wh?")) != -1) {
		switch (c) {
		case 'p':
			pflag = 1;
			break;

		case 's':
			sflag = 1;
			sram_file = optarg;
			/* Delete old file if present, since we'll be appending */
			unlink(sram_file);
			break;

		case 'w':
			wflag = 1;
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

	if (argc < 1) {
		usage(1);
		/* NOT REACHED */
	}

	if (wflag) {
		trunner_print_magic();

		error = sram_open();
		if (error) {
			perror("sram_open");
			exit(1);
		}
	}


	rpath = realpath(argv[0], NULL);
	mydir = opendir(rpath);
	if (mydir == NULL) {
		perror("opendir");
		exit(1);
	}

	while ((entry = readdir(mydir))) {
		if (entry->d_type != DT_DIR)
			continue;

		if ((strcmp(entry->d_name, ".")) == 0)
			continue;

		if ((strcmp(entry->d_name, "..")) == 0)
			continue;

		snprintf(fname, PATH_MAX, "%s/%s", rpath, entry->d_name);
		printf("Processing %s\n", fname);

		if ((error = parse_team_dir(fname)) != 0) {
			logger(LOGERR, "Error parsing %s", fname);
			continue;
		}
	}

	closedir(mydir);


	if (wflag)
		sram_close();

	return 0;
}
