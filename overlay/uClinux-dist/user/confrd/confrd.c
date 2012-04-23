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
#include <curl/curl.h>

#include "sram.h"
#include "trunner_if.h"


#define LOGDEBUG		1
#define LOGINFO			2
#define LOGWARN			3
#define LOGERR			4

#define COMMENT_CHAR		'#' //Comment definition

#define MAX_INPUT_OUTPUT_SIZE	24
#define MAX_INPUT_PIN		(MAX_INPUT_OUTPUT_SIZE-1)
#define MAX_OUTPUT_PIN		(MAX_INPUT_OUTPUT_SIZE-1)
#define BITMASK_BYTES		MAX_INPUT_OUTPUT_SIZE
#define MAX_PINS		(2*MAX_INPUT_OUTPUT_SIZE)

#define DESIGN_NUMBER_MASK	0x1f

#define REQ_SWITCH_TARGET	0x00
#define REQ_TEST_VECTOR		0x01
#define REQ_SETUP_BITMASK	0x02
#define REQ_SEND_DICMD		0x03
#define REQ_END			0x07

#define DICMD_SETUP_MUXES	0x01
#define DICMD_TRGMASK           0x02

#define MD2_FAIL		0x01
#define MD2_RUN			0x80
#define MD2_SET_CYCLES(c)       ((((c)-1) & 0x1f) << 1)
#define MD2_SET_MODE(m)         ((m & 0x01) << 6)
#define MD2_CYCLES(md2)         (((md2 >> 1) & 0x1f) + 1)
#define MD2_MODE(md2)           ((md2 >> 6) & 0x01)


#define REQ_TYPE(r)		((r & 0x07) << 5)
#define DICMD(c)		(c & 0x1f)

#define iswhitespace(c)		((c == ' ') || (c == '\t'))

typedef enum pin_type {
	INPUT_PIN = 'A', OUTPUT_PIN = 'Q'
} pin_type_t;


typedef struct test_vector {
	uint8_t metadata;
	uint8_t input_vector[3];
	uint8_t output_vector[3];
	uint8_t metadata2;
} test_vector;


struct change_target {
	uint8_t metadata;
	uint8_t design_number;
	uint8_t padding[2];
	uint8_t padding2[2];
} __attribute__((__packed__));

typedef struct change_target change_target;


struct change_bitmask {
	uint8_t metadata;
	uint8_t bit_mask[3];
	uint8_t padding[2];
} __attribute__((__packed__));

typedef struct change_bitmask change_bitmask;


struct send_dicmd {
	uint8_t metadata;
	uint8_t payload[3];
	uint8_t padding[2];
} __attribute__((__packed__));

typedef struct send_dicmd send_dicmd;


struct mem_end {
	uint8_t metadata;
	uint8_t unused1;
	uint8_t padding[2];
	uint8_t padding2[2];
} __attribute__((__packed__));

typedef struct mem_end mem_end;


typedef struct pininfo {
	pin_type_t	type;
	int		pin_no;
	int		bidx;
	int		shiftl;
} *pininfo_t;


typedef struct globaldata {
	int team_no;
} *globaldata_t;


typedef struct parserinfo {
	globaldata_t gd;

	char *file_name;
	char *design_name;

	size_t sram_free_bytes;
	off_t  sram_off;

	int pin_count;
	uint8_t bitmask[BITMASK_BYTES];
	struct pininfo pins[MAX_PINS];
} *parserinfo_t;


typedef int (*line_parser)(char *, void *);
typedef int (*suspend_fn)(void *);


typedef struct keyword {
	const char	*keyword;
	line_parser	lp;
} *keyword_t;


static int parse_line_team(char *, void *);
static int parse_line_design(char *, void *);
static int parse_line_pindef(char *, void *);
static int parse_line_vectors(char *, void *);
static int parse_line_clock(char *, void *);
static int parse_line_trgmask(char *, void *);

static int run_trunner(parserinfo_t pi);
static int emit(parserinfo_t pi, void *b, size_t bufsz);
static int suspend_emit(void *p);


struct keyword tv_keywords[] = {
	{ .keyword = "design"	, .lp = parse_line_design  },
	{ .keyword = "pindef"	, .lp = parse_line_pindef  },
	{ .keyword = "vectors"	, .lp = parse_line_vectors },
	{ .keyword = "clock"	, .lp = parse_line_clock   },
	{ .keyword = "trigger"  , .lp = parse_line_trgmask },
	{ .keyword = NULL	, .lp = NULL }
};

struct keyword meta_keywords[] = {
	{ .keyword = "team"	, .lp = parse_line_team    },
	/* XXX: email, etc */
	{ .keyword = NULL	, .lp = NULL }
};


int pflag = 0;
int wflag = 0;
int sflag = 0;
char *sram_file = NULL;


char *cur_filename;
int cur_lineno;


static
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
syntax_error(const char *fmt, ...)
{
	char msgbuf[4096];
	va_list ap;

	va_start(ap, fmt);
	vsnprintf(msgbuf, sizeof(msgbuf), fmt, ap);
	va_end(ap);

	logger(LOGERR, "%s:%d syntax error: %s", cur_filename, cur_lineno, msgbuf);
}


static
size_t
req_sz(int req)
{
	switch (req) {
	case REQ_SWITCH_TARGET:	return sizeof(change_target);
	case REQ_TEST_VECTOR:	return sizeof(test_vector);
	case REQ_SETUP_BITMASK:	return sizeof(change_bitmask);
	case REQ_SEND_DICMD:	return sizeof(send_dicmd);
	case REQ_END:		return sizeof(mem_end);
	default:		return 0;
	}
}


static
void
sbprint(char *s, uint8_t *n, size_t len)
{
	uint8_t mask;
	size_t i;

	for (i = 0; i < len; i++) {
		mask = 1 << (8*sizeof(*n) - 1);
		do {
			if (s == NULL)
				putchar((n[i] & mask) ? '1' : '0');
			else
				*s++ = (n[i] & mask) ? '1' : '0';
			mask >>= 1;
		} while (mask != 0);
	}

	if (s)
		*s = '\0';
}


static
void
bprint(uint8_t *n, size_t len)
{
	sbprint(NULL, n, len);
}


static
int
tokenizer(char *s, char **tokens, int max_tokens)
{
	int ntokens = 0;

	tokens[ntokens++] = s;

	for (; *s != '\0'; s++) {
		if (iswhitespace(*s) || *s == ',') {
			*s++ = '\0';
			for (; (*s == ',' || iswhitespace(*s)) && (*s != '\0'); s++)
				;

			tokens[ntokens++] = s;

			if (ntokens == max_tokens)
				return -1;
		}
	}

	tokens[ntokens] = NULL;

	return ntokens;
}


static
int
parse_line_vectors(char *s, void *priv)
{
	parserinfo_t pi = priv;
	test_vector tv;
	char *e;
	int n = 0;
	int cycles = 1;
	int mode = 0; /* XXX: add constant #defines */
	int mode_set = 0;

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
emit_end(parserinfo_t pi)
{
	mem_end me;

	memset(&me, 0, sizeof(me));

	me.metadata = REQ_TYPE(REQ_END);

	return emit(pi, &me, sizeof(me));
}


static
int
emit_change_target(parserinfo_t pi, globaldata_t gd)
{
	change_target ct;

	memset(&ct, 0, sizeof(ct));

	ct.metadata = REQ_TYPE(REQ_SWITCH_TARGET);
	ct.design_number = gd->team_no & DESIGN_NUMBER_MASK;

	return emit(pi, &ct, sizeof(ct));
}


static
size_t
print_mem(uint8_t *buf, int sz, int *end)
{
	change_target *ct;
	change_bitmask *cb;
	test_vector *tv;
	send_dicmd *sd;
	mem_end *me;
	int req;
	size_t reqsz;

	if (end)
		*end = 0;

	while (sz > 0) {
		req = buf[0] >> 5;

		/*
		 * If we don't have enough bytes left, stop processing. We'll
		 * end up returning the number of bytes that were leftover.
		 */
		reqsz = req_sz(req);
		if ((size_t)sz < reqsz)
			break;

		switch (req) {
		case REQ_SWITCH_TARGET:
			ct = (change_target *)buf;
			printf("REQ_SWITCH_TARGET:\ttarget=%d\n",
			    (int)ct->design_number);
			break;

		case REQ_SETUP_BITMASK:
			cb = (change_bitmask *)buf;
			printf("REQ_SETUP_BITMASK:\tbitmask=");
			bprint(cb->bit_mask, sizeof(cb->bit_mask));
			putchar('\n');
			break;

		case REQ_TEST_VECTOR:
			tv = (test_vector *)buf;
			printf("REQ_TEST_VECTOR:\tiv=");
			bprint(tv->input_vector, sizeof(tv->input_vector));
			printf(", ov=");
			bprint(tv->output_vector, sizeof(tv->output_vector));
			printf(", metadata2=%c %c (cycles: %d, mode: %s)\n",
			    (tv->metadata2 & MD2_RUN)  ? 'R' : ' ',
			    (tv->metadata2 & MD2_FAIL) ? 'F' : ' ',
			    (MD2_CYCLES(tv->metadata2)),
			    (MD2_MODE(tv->metadata2) ? "TRIG":"WAIT") );
			break;

		case REQ_SEND_DICMD:
			sd = (send_dicmd *)buf;
			printf("REQ_SEND_DICMD:\t\tcmd=");
			switch (DICMD(sd->metadata)) {
			case DICMD_SETUP_MUXES:
				printf("DICMD_SETUP_MUXES, mux_config=");
				bprint(sd->payload, sizeof(sd->payload));
				putchar('\n');
				break;
 			case DICMD_TRGMASK:
				printf("DICMD_TRGMASK, trigger_mask=");
				bprint(sd->payload, sizeof(sd->payload));
				putchar('\n');
				break;
			default:
				printf("unknown\n");
			}
			break;

		case REQ_END:
			me = (mem_end *)buf;
			if (end) {
				*end = 1;
				return 0;
			}
			printf("REQ_END\n");
			break;

		default:
			printf("INVALID REQUEST TYPE: %#x\n",
			    (unsigned int)(req));
			return sz;
		}

		sz -= reqsz;
		buf += reqsz;
	}

	return sz;
}


static
void
save_sram_file(uint8_t *buf, int sz)
{
	FILE *fp;
	int i;

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


static
int
parse_file(char *fname, FILE *fp, keyword_t keywords, suspend_fn suspend, void *priv)
{
	char line[1024];
	char *s, *e;
	int keyword_idx = -1;
	int i, len, error;

	cur_filename = fname;
	cur_lineno = 0;

	while(fgets(line, sizeof(line), fp) != NULL) {
		++cur_lineno;

		/* skip leading whitespace */
		for (s = line; *s != '\0' && iswhitespace(*s); s++)
			;

		/* Remove trailing comment */
		if ((e = strchr(s, COMMENT_CHAR)) != NULL)
			*e = '\0';

		/* Removing trailing whitespace and newline character */
		for (e = &(s[strlen(s)-1]);
		     (e >= s) && (iswhitespace(*e) || *e == '\n');
		     e--)
			*e = '\0';

		/* Don't parse this line if it's commented out */
		if (*s == COMMENT_CHAR)
			continue;

		/* Ignore empty line */
		if (*s == '\0')
			continue;

		for (i = 0; keywords[i].keyword != NULL; i++) {
			len = strlen(keywords[i].keyword);

			if ((strncmp(keywords[i].keyword, s, len)) != 0)
				continue;

			/* Trim whitespace between command and the colon */
			for (e = &(s[len]); *e != '\0' && iswhitespace(*e); e++)
				;

			if (*e == ':') {
				keyword_idx = i;
				s = ++e;
				break;
			}
		}

		if (keyword_idx < 0) {
			syntax_error("File must start with "
			    "valid keyword");
			return -1;
		}

		/* skip leading whitespace */
		for (; *s != '\0' && iswhitespace(*s); s++)
			;

		/* Effectively empty line */
		if (*s == '\0')
			continue;

		/* Let section-specific line parser do its job */
		error = keywords[keyword_idx].lp(s, priv);
		if ((error == EAGAIN || error == -EAGAIN) && suspend != NULL)
			error = suspend(priv);

		if (error)
			return error;
	}

	return 0;
}


static
int
emit(parserinfo_t pi, void *b, size_t bufsz)
{
	uint8_t *buf = b;
	int rc = 0;

	if (bufsz == 0)
		return rc;

	if (pflag)
		print_mem(buf, bufsz, NULL);

	if (sflag)
		save_sram_file(buf, bufsz);

	if (wflag) {
		rc = sram_write(pi->sram_off, buf, bufsz);
		if (rc == 0) {
			pi->sram_off += bufsz;
			pi->sram_free_bytes -= bufsz;

			if (pi->sram_free_bytes <
			    (req_sz(REQ_TEST_VECTOR) + req_sz(REQ_END)))
				rc = EAGAIN;
		}
	}

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


static
int
suspend_emit(void *p)
{
	parserinfo_t pi = pi;
	int error;

	error = emit_end(pi);
	if (error != 0 && error != EAGAIN)
		return error;

	if ((error = run_trunner(pi)) != 0)
		return error;


	/* Emit necessary restart code (XXX: presumably nothing) */
	/* Reset SRAM index and size */
	pi->sram_off = 0;
	pi->sram_free_bytes = SRAM_SIZE;

	return 0;
}


static
void
init_parserinfo(parserinfo_t pi)
{

	memset(pi, 0, sizeof(*pi));
	pi->sram_free_bytes = SRAM_SIZE;
}


static
int
parse_vec_file(char *filename)
{
	struct parserinfo pi;
	FILE *fp;
	int rc;

	fp = fopen(filename, "r");
	if (fp == NULL) {
		logger(LOGERR, "The file %s cannot be opened: %s",
		    filename, strerror(errno));
		return -1;
	}

	init_parserinfo(&pi);
	pi.file_name = strdup(filename);

	rc = parse_file(filename, fp, tv_keywords, (wflag) ? suspend_emit : NULL, &pi);
	if (rc)
		goto out;

	rc = emit_end(&pi);
	if (rc)
		goto out;

	if (wflag) {
		rc = run_trunner(&pi);
		if (rc)
			goto out;
	}

out:
	fclose(fp);
	return rc;
}


static
int
parse_cfg_file(char *filename, globaldata_t gd)
{
	struct parserinfo pi;
	FILE *fp;
	int rc;

	fp = fopen(filename, "r");
	if (fp == NULL) {
		logger(LOGERR, "The file %s cannot be opened: %s",
		    filename, strerror(errno));
		return -1;
	}

	init_parserinfo(&pi);
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

	rc = emit_change_target(&pi, gd);
	if (rc)
		goto out;

	rc = emit_end(&pi);
	if (rc)
		goto out;

	if (wflag) {
		rc = run_trunner(&pi);
		if (rc)
			goto out;
	}

out:
	fclose(fp);
	return rc;
}


static
int
parse_team_dir(char *dirname)
{
	struct globaldata gd;
	struct dirent *entry;
	DIR *dir;
	char fname[PATH_MAX];
	int error;

	memset(&gd, 0, sizeof(gd));
	gd.team_no = -1;

	snprintf(fname, PATH_MAX, "%s/%s", dirname, "team.cfg");
	error = parse_cfg_file(fname, &gd);
	if (error) {
		logger(LOGERR, "Invalid configuration file: %s",
		    fname);
		return -1;
	}

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

		snprintf(fname, PATH_MAX, "%s/%s", dirname, entry->d_name);
		logger(LOGINFO, "Processing %s", fname);

		if ((error = parse_vec_file(fname)) != 0) {
			logger(LOGERR, "Error parsing %s", fname);
			continue;
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
