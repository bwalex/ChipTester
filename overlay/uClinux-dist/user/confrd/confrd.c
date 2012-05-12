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
#include "trunner_if.h"



int pflag = 0;
int wflag = 0;
int sflag = 0;
int vflag = 0;
char *sram_file = NULL;
char *base_url = NULL;


char *cur_filename;
int cur_lineno;


uint8_t sram_stage[SRAM_SIZE];


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


char *
build_url(parserinfo_t pi, const char *req_path_fmt, ...)
{
	va_list ap;
	static char buffer[2048];
	char fmt[512];
	const char *baseurl;

	baseurl = pi->gd->base_url;

	snprintf(fmt, sizeof(fmt), "%s/%s", baseurl,
		 req_path_fmt);

	va_start(ap, fmt);
	vsnprintf(buffer, sizeof(buffer), fmt, ap);
	va_end(ap);

	return buffer;
}


int
init_remote(parserinfo_t pi)
{
	/* Push out team number and other global info (Result) */
	globaldata_t gd = pi->gd;
	json_t *j_in;
	json_t *j_out;
	int error;

	j_in = json_pack("{s:i, s:s, s:b}",
			 "team", gd->team_no,
			 "academic_year", gd->academic_year,
			 "virtual", vflag);
	if (j_in == NULL) {
		logger(LOGERR, "Error packing JSON for 'Result'");
		return -1;
	}

	error = req_json(build_url(pi, "api/result"), METHOD_POST,
			 j_in, &j_out);

	json_decref(j_in);

	if (error) {
		logger(LOGERR, "Error sending JSON for 'Result', %d",
		       error);
		return error;
	}

	error = json_unpack(j_out, "{s:i}", "id", &gd->result_id);

	json_decref(j_out);

	if (error) {
		logger(LOGERR, "Error parsing received JSON for 'Result'");
		return error;
	}

	if (gd->result_id < 1) {
		logger(LOGERR, "Invalid result id");
		return -1;
	}

	return 0;
}


int
submit_measurement_freq(parserinfo_t pi, double freq)
{
	int error;
	json_t *j_in;
	char *url;

	url = build_url(pi, "api/result/%d/design/%d/measurement/frequency",
			pi->gd->result_id, pi->design_result_id);

	j_in = json_pack("{s:f}", "frequency", freq);
	if (j_in == NULL) {
		logger(LOGERR, "Error packing JSON for frequency measurement");
		return -1;
	}

	error = req_json(url, METHOD_POST, j_in, NULL);
	json_decref(j_in);
	return error;
}


static
int
process_sram_results(parserinfo_t pi)
{
	test_vector_t tv;
	json_t *j_in;
	json_t *j_out;

	char *url;
	uint8_t buf[256];
	uint8_t *pbuf;
	size_t sz = 0;
	int error = 0;
	int done = 0;
	off_t off = 0;
	int req;
	int i = 0;
	size_t reqsz;


	if (pi->design_result_id < 1) {
		/* Push out DesignResult */
		j_in = json_pack("{s:i, s:s, s:i, s:s, s:s}",
				 "file_name", pi->file_name,
				 "clock_freq", pi->pll_freq,
				 "triggers",  h_output(pi->trigger_mask, sizeof(pi->trigger_mask)),
				 "design_name", pi->design_name);
		if (j_in == NULL) {
			logger(LOGERR, "Error packing JSON for 'DesignResult'");
			return -1;
		}

		error = req_json(build_url(pi, "api/result/%d/design", pi->gd->result_id),
				 METHOD_POST, j_in, &j_out);

		json_decref(j_in);

		if (error) {
			logger(LOGERR, "Error sending JSON for 'DesignResult', %d",
			       error);
			return error;
		}

		error = json_unpack(j_out, "{s:i}", "id", &pi->design_result_id);

		json_decref(j_out);

		if (error) {
			logger(LOGERR, "Error parsing received JSON for 'DesignResult'");
			return error;
		}

		if (pi->design_result_id < 1) {
			logger(LOGERR, "Invalid design_result id");
			return -1;
		}
	}

	/* Pre-build url to avoid the cost on 'req' */
	url = build_url(pi, "api/result/%d/design/%d/vector", pi->gd->result_id,
			pi->design_result_id);

	do {
		error = sram_read(off, buf, sizeof(buf));
		if (error)
			return error;

		pbuf = buf;
		sz = sizeof(buf);

		while (sz > 0) {
			req = pbuf[0] >> 5;
			reqsz = req_sz(req);

			/*
			 * If we don't have enough bytes left, stop processing. We'll
			 * end up returning the number of bytes that were leftover.
			 */
			if (sz < reqsz)
				break;

			if (pflag)
				print_req(pbuf, reqsz, NULL);

			switch (req) {
			case REQ_TEST_VECTOR:
				tv = (test_vector_t)pbuf;
				/* Push out TestVectorResult */
				j_in = json_pack("{s:i,s:s,s:s,s:i,s:s,s:s,s:b,s:b,s:b}",
						 "type", MD2_MODE(tv->metadata2),
						 "input_vector", h_input(tv->input_vector,
								   pi->clock_mask,
								   sizeof(tv->input_vector)),
						 "expected_result", h_expected(&pi->output[i],
								      tv->x_mask, pi->bitmask,
								      sizeof(tv->output_vector)),
						 "actual_result", h_output(tv->output_vector,
								    sizeof(tv->output_vector)),
						 "cycle_count", MD2_CYCLES(tv->metadata2) + 1,
						 "trigger_timeout", tv->metadata2 & MD2_TIMEOUT,
						 "fail", tv->metadata2 & MD2_FAIL,
						 "has_run", tv->metadata2 & MD2_RUN);
				if (j_in == NULL) {
					logger(LOGERR, "Error packing JSON for Vector");
					return -1;
				}

				error = req_json(url, METHOD_POST, j_in, NULL);
				json_decref(j_in);
				if (error) {
					logger(LOGERR, "Error sending JSON for Vector, %d",
						error);
					return error;
				}

				break;
			}

			i += sizeof(tv->output_vector);
			sz   -= reqsz;
			pbuf += reqsz;
		}

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
run_trunner(parserinfo_t pi, int process)
{
	int error;

	if ((error = trunner_enable()) != 0)
		return error;

	if ((error = trunner_wait_done()) != 0)
		return error;

	if (process)
		process_sram_results(pi);
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

	error = go(pi, 1);
	if (error != 0)
		return error;

	/* Emit necessary restart code (XXX: presumably nothing) */
	/* Reset SRAM index and size */
	pi->sram_off = 0;
	pi->sram_free_bytes = SRAM_SIZE;

	return 0;
}


int
go(parserinfo_t pi, int process)
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

		return run_trunner(pi, process);
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

	init_parserinfo(&pi, &gd);

	snprintf(fname, PATH_MAX, "%s/%s", dirname, "team.cfg");
	error = parse_cfg_file(fname, &gd, &pi);
	if (error) {
		logger(LOGERR, "Invalid configuration file: %s",
		    fname);
		return -1;
	}

	if (gd.team_no < 0) {
		logger(LOGERR, "team.cfg is missing a valid team number");
		++error;
	}

	if (gd.base_url == NULL && wflag) {
		logger(LOGERR, "team.cfg is missing a valid base_url");
		++error;
	}

	base_url = gd.base_url;

	if (error)
		return error;

	rc = emit_change_target(&pi, &gd);
	if (rc)
		return -1;

	if (!sflag || wflag) {
                /* Don't emit the end in the sflag mode */
		rc = emit_end(&pi);
		if (rc)
			return -1;
	}

	if (wflag) {
		error = init_remote(&pi);
		if (error)
			return error;
	}

	rc = go(&pi, 0);
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

		init_parserinfo(&pi, &gd);
		snprintf(fname, PATH_MAX, "%s/%s", dirname, entry->d_name);
		logger(LOGINFO, "Processing %s", fname);

		if ((error = parse_vec_file(fname, suspend_emit, &pi)) != 0) {
			logger(LOGERR, "Error parsing %s", fname);
			continue;
		}

		rc = go(&pi, 1);
		if (rc)
			return -1;
	}

	if (gd.email)
		free(gd.email);
	if (gd.academic_year)
		free(gd.academic_year);
	if (gd.base_url)
		free(gd.base_url);

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
