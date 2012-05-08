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
#include "pll_settings.h"


static int parse_line_design(char *, void *);
static int parse_line_pindef(char *, void *);
static int parse_line_vectors(char *, void *);
static int parse_line_clock(char *, void *);
static int parse_line_trgmask(char *, void *);
static int parse_line_frequency(char *, void *);
static int parse_line_measure(char *, void *);


struct keyword tv_keywords[] = {
	{ .keyword = "design"	  , .lp = parse_line_design     },
	{ .keyword = "pindef"	  , .lp = parse_line_pindef     },
	{ .keyword = "vectors"	  , .lp = parse_line_vectors    },
	{ .keyword = "clock"	  , .lp = parse_line_clock      },
	{ .keyword = "trigger"    , .lp = parse_line_trgmask    },
	{ .keyword = "frequency"  , .lp = parse_line_frequency  },
	{ .keyword = NULL	  , .lp = NULL }
};

struct dotcommand dot_commands[] = {
	{ .command = "measure"	  , .lp = parse_line_measure     },
	{ .command = NULL	  , .lp = NULL }
};


extern char *cur_filename;
extern int cur_lineno;


static
int
parse_line_measure(char *s, void *priv)
{
	parserinfo_t pi = priv;
	char *tokens[32];
	char *e;
	uint32_t timeout = (1 << 24);
	int error;
	int pin_no;
	int ntokens;

	/* Flush current content */
	if (pi->suspend_fn != NULL) {
		error = pi->suspend_fn(pi);
		if (error)
			return error;
	}

	ntokens = tokenizer(s, tokens, 32);
	if (ntokens < 1) {
		syntax_error("Too many arguments to .measure command");
		return error;
	}

	if ((strcmp(tokens[0], "frequency")) == 0) {
		if (ntokens < 2) {
			syntax_error("frequency measurement requires pin number");
			return -1;
		}

		if (*tokens[1] == 'Q')
			*tokens[1]++;

		pin_no = strtol(tokens[1], &e, 10);
		if (*e != '\0') {
			syntax_error("frequency measurement requires a valid pin number");
			return -1;
		}

		if (ntokens > 2) {
			timeout = strtol(tokens[2], &e, 10);
			if (*e != '\0') {
				syntax_error("cycle timeout is invalid");
				return -1;
			}
		}

		/* XXX */
	} else if ((strcmp(tokens[0], "adc")) == 0) {
	} else {
		syntax_error("Unknown measurement command");
		return -1;
	}

	return 0;
}


static
int
parse_line_vectors(char *s, void *priv)
{
	parserinfo_t pi = priv;
	dotcommand_t dc;
	test_vector tv;
	size_t len;
	char *e;
	int n = 0;
	int cycles = 1;
	int mode = 0; /* XXX: add constant #defines */
	int mode_set = 0;
	int error;

	if (!pi->seen_vectors) {
		error = emit_pre_vectors(pi);
		if (error)
			return error;
		pi->seen_vectors = 1;
	}

	if (*s == '.') {
		++s;

		for (dc = &dot_commands[0]; dc->command != NULL; dc++) {
			len = strlen(dc->command);
			if ((strncmp(dc->command, s, len)) != 0)
				continue;

			/* Trim whitespace */
			for (e = &(s[len]); *e != '\0' && iswhitespace(*e); e++)
				;

			return dc->lp(s, priv);
		}

		if (dc->command == NULL) {
			syntax_error("Unknown dot command");
			return -1;
		}
	}

	memset(&tv, 0, sizeof(tv));

	while (*s != '\0') {
		if (*s == 'w' || *s == 'W') {
			if (mode_set) {
				syntax_error("Vector already defined wait/trigger mode");
				return -1;
			}

			++s;

			for (; *s != '\0' && iswhitespace(*s); s++)
				;

			cycles = strtol(s, &e, 10);
			if (e)
				s = e;

			/* XXX */
			if (cycles < 1 || cycles > 32) {
				syntax_error("Wait cycles must be between 1 and 32");
				return -1;
			}

			mode = 0;
			mode_set = 1;
		} else if (*s == 't' || *s == 'T') {
			if (mode_set) {
				syntax_error("Vector already defined wait/trigger mode");
				return -1;
			}

			cycles = 32; /* XXX */
			mode = 1; /* XXX */
			mode_set = 1;

			++s;
		} else if (*s == '0' || *s == '1') {
			if (n >= pi->pin_count) {
				syntax_error("Vector contains too many pins");
				return -1;
			}

			/*
			 * Set the correct pin according to the pin info assembled
			 * earlier when parsing the pindef.
			 */
			if (pi->pins[n].type == INPUT_PIN)
				tv.input_vector[pi->pins[n].bidx] |=
					(*s - '0') << pi->pins[n].shiftl;
			else
				tv.output_vector[pi->pins[n].bidx] |=
					(*s - '0') << pi->pins[n].shiftl;

			++n;

			++s;
		} else {
			syntax_error("Vector contains invalid "
			    "character: %c", *s);
			return -1;
		}

		/* Skip all whitespace and commas after each bit */
		for (; *s != '\0' && (iswhitespace(*s) || *s == ','); s++)
			;
	}

	if (n < pi->pin_count) {
		syntax_error("Vector contains too few pins");
		return -1;
	}

	tv.metadata = REQ_TYPE(REQ_TEST_VECTOR);
	tv.metadata2 |= MD2_SET_CYCLES(cycles);
	tv.metadata2 |= MD2_SET_MODE(mode);

	return emit(pi, &tv, sizeof(tv));
}


static
int
parse_line_pindef(char *s, void *priv)
{
	parserinfo_t pi = priv;
	change_bitmask cb;
	pin_type_t type;
	char *pins[MAX_PINS];
	char *e;
	int pin_no, bidx, shiftl;
	int ntoks, i;

	memset(&cb, 0, sizeof(cb));

	cb.metadata = REQ_TYPE(REQ_SETUP_BITMASK);

	pi->pin_count = 0;
	memset(pi->bitmask, 0, sizeof(pi->bitmask));

	/* Tokenize pindef, tokens being separated by whitespace or comma */
	if ((ntoks = tokenizer(s, pins, MAX_PINS)) == -1) {
		syntax_error("maximum number of pins exceeded");
		return -1;
	}

	for (i = 0; i < ntoks; i++) {
		/* Determine pin type by first character of pin */
		type = (pins[i][0] == INPUT_PIN) ? INPUT_PIN : OUTPUT_PIN;

		/* Pin number follows the pin type character */
		pin_no = strtol(&(pins[i][1]), &e, 10);
		if (*e != '\0') {
			syntax_error("pin number must consist "
			    "of only decimal digits");
			return -1;
		}

		if (pin_no > ((type == INPUT_PIN) ? MAX_INPUT_PIN : MAX_OUTPUT_PIN)) {
			syntax_error("pin number %d is out "
			    "of range", pin_no);
			return -1;
		}

		/* Find byte index as well as bit within that byte index */
		bidx = 2 /* XXX, magical constant */ - pin_no / 8;
		shiftl = pin_no % 8;

		/* If it's an output pin, update the result bitmask */
		if (type == OUTPUT_PIN)
			pi->bitmask[bidx] |= (1 << shiftl);

		pi->pins[i].pin_no = pin_no;
		pi->pins[i].type = type;
		pi->pins[i].bidx = bidx;
		pi->pins[i].shiftl = shiftl;

		++pi->pin_count;
	}

	memcpy(cb.bit_mask, pi->bitmask, sizeof(cb.bit_mask));
	return emit(pi, &cb, sizeof(cb));
}


/*
 * XXX: can add additional error checking to see whether clock: and pindef:
 *      overlap.
 */

static
int
parse_line_clock(char *s, void *priv)
{
	parserinfo_t pi = priv;
	send_dicmd sd;
	pin_type_t type;
	char *pins[MAX_PINS];
	char *e;
	int pin_no, bidx, shiftl;
	int ntoks, i;

	memset(&sd, 0, sizeof(sd));

	sd.metadata = REQ_TYPE(REQ_SEND_DICMD) | DICMD(DICMD_SETUP_MUXES);

	/* Tokenize pindef, tokens being separated by whitespace or comma */
	if ((ntoks = tokenizer(s, pins, MAX_INPUT_OUTPUT_SIZE)) == -1) {
		syntax_error("maximum number of pins "
		    "exceeded");
		return -1;
	}

	for (i = 0; i < ntoks; i++) {
		/* Determine pin type by first character of pin */
		type = (pins[i][0] == INPUT_PIN) ? INPUT_PIN : OUTPUT_PIN;
		if (type == OUTPUT_PIN) {
			syntax_error("clock signals need to be "
			    "connected to input pins, not output pins");
			return -1;
		}

		/* Pin number follows the pin type character */
		pin_no = strtol(&(pins[i][1]), &e, 10);
		if (*e != '\0') {
			syntax_error("pin number must consist "
			    "of only decimal digits");
			return -1;
		}

		if (pin_no > MAX_INPUT_PIN) {
			syntax_error("pin number %d is out "
			    "of range", pin_no);
		}

		/* Find byte index as well as bit within that byte index */
		bidx = 2 /* XXX, magical constant */ - pin_no / 8;
		shiftl = pin_no % 8;

		sd.payload[bidx] |= (1 << shiftl);
	}

	return emit(pi, &sd, sizeof(sd));
}


static
int
parse_line_trgmask(char *s, void *priv)
{
	parserinfo_t pi = priv;
	send_dicmd sd;
	pin_type_t type;
	char *pins[MAX_PINS];
	char *e;
	int pin_no, bidx, shiftl;
	int ntoks, i;

	memset(&sd, 0, sizeof(sd));

	sd.metadata = REQ_TYPE(REQ_SEND_DICMD) | DICMD(DICMD_TRGMASK);

	/* Tokenize pindef, tokens being separated by whitespace or comma */
	if ((ntoks = tokenizer(s, pins, MAX_INPUT_OUTPUT_SIZE)) == -1) {
		syntax_error("maximum number of pins "
		    "exceeded");
		return -1;
	}

	for (i = 0; i < ntoks; i++) {
		/* Determine pin type by first character of pin */
		type = (pins[i][0] == INPUT_PIN) ? INPUT_PIN : OUTPUT_PIN;
		if (type == INPUT_PIN) {
			syntax_error("trigger mask signals need to be "
			    "connected to output pins, not input pins");
			return -1;
		}

		/* Pin number follows the pin type character */
		pin_no = strtol(&(pins[i][1]), &e, 10);
		if (*e != '\0') {
			syntax_error("pin number must consist "
			    "of only decimal digits");
			return -1;
		}

		if (pin_no > MAX_INPUT_PIN) {
			syntax_error("pin number %d is out "
			    "of range", pin_no);
		}

		/* Find byte index as well as bit within that byte index */
		bidx = 2 /* XXX, magical constant */ - pin_no / 8;
		shiftl = pin_no % 8;

		sd.payload[bidx] |= (1 << shiftl);
	}

	return emit(pi, &sd, sizeof(sd));
}


static
int
parse_line_design(char *s, void *priv)
{
	parserinfo_t pi = priv;
	int error;

	if (pi->design_name != NULL) {
		/* Execute queued tests before changing design name */
		error = suspend_emit(pi);
		if (error)
			return error;

		free(pi->design_name);
		pi->design_name = NULL;
	}

	pi->design_name = strdup(s);

	return 0;
}


static
int
parse_line_frequency(char *s, void *priv)
{
	parserinfo_t pi = priv;
	char *e;
	int freq_mhz;

	freq_mhz = (int)strtol(s, &e, 10);
	if (s == e || *e != '\0') {
		syntax_error("frequency must contain only "
		    "decimal digits");
		return -1;
	}

	if (freq_mhz < 1 || freq_mhz > 100) {
		syntax_error("frequency must be between 1 and 100 MHz");
		return -1;
	}

	pi->pll_m = pll_settings[freq_mhz].m;
	pi->pll_n = pll_settings[freq_mhz].n;
	pi->pll_c = pll_settings[freq_mhz].c;

	return 0;
}


int
emit_end(parserinfo_t pi)
{
	mem_end me;

	memset(&me, 0, sizeof(me));

	me.metadata = REQ_TYPE(REQ_END);

	return emit(pi, &me, sizeof(me));
}


int
emit_pre_vectors(parserinfo_t pi)
{
	pll_reconfig pr;

	memset(&pr, 0, sizeof(pr));
	pr.metadata = REQ_TYPE(REQ_PLLRECONFIG);
	pr.mul_factor = pi->pll_m;
	pr.div_factor = pi->pll_n;
	pr.div_factor_post = pi->pll_c;

	return emit(pi, &pr, sizeof(pr));
}


int
emit_change_target(parserinfo_t pi, globaldata_t gd)
{
	change_target ct;

	memset(&ct, 0, sizeof(ct));

	ct.metadata = REQ_TYPE(REQ_SWITCH_TARGET);
	ct.design_number = gd->team_no & DESIGN_NUMBER_MASK;

	return emit(pi, &ct, sizeof(ct));
}


int
parse_vec_file(char *filename, suspend_fn sus_fn, parserinfo_t pi)
{
	FILE *fp;
	int rc;

	fp = fopen(filename, "r");
	if (fp == NULL) {
		logger(LOGERR, "The file %s cannot be opened: %s",
		    filename, strerror(errno));
		return -1;
	}

	pi->file_name = strdup(filename);
	pi->suspend_fn = sus_fn;

	rc = parse_file(filename, fp, tv_keywords, sus_fn, pi);
	if (rc)
		goto out;

	rc = emit_end(pi);
	if (rc)
		goto out;

out:
	fclose(fp);
	return rc;
}

