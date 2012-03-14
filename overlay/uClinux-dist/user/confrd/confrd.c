#include <sys/types.h>
#include <stdio.h>
#include <limits.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>
#include <getopt.h>
#include "sram.h"
#include "trunner_if.h"


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

#define MD2_FAIL		0x01
#define MD2_RUN			0x80


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


typedef struct parserinfo {
	int pin_count;
	uint8_t bitmask[BITMASK_BYTES];

	struct pininfo pins[MAX_PINS];
} *parserinfo_t;


typedef int (*line_parser)(char *, parserinfo_t, void *, size_t);


typedef struct keyword {
	const char	*keyword;
	line_parser	lp;
} *keyword_t;


static int parse_line_design(char *, parserinfo_t, void *, size_t);
static int parse_line_pindef(char *, parserinfo_t, void *, size_t);
static int parse_line_vectors(char *, parserinfo_t, void *, size_t);
static int parse_line_clock(char *, parserinfo_t, void *, size_t);



struct keyword keywords[] = {
	{ .keyword = "design"	, .lp = parse_line_design  },
	{ .keyword = "pindef"	, .lp = parse_line_pindef  },
	{ .keyword = "vectors"	, .lp = parse_line_vectors },
	{ .keyword = "clock"	, .lp = parse_line_clock   },
	{ .keyword = NULL	, .lp = NULL }
};

int wflag = 0;
int sflag = 0;
char *sram_file = NULL;


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
bprint(uint8_t *n, size_t len)
{
	uint8_t mask;
	size_t i;

	for (i = 0; i < len; i++) {
		mask = 1 << (8*sizeof(*n) - 1);
		do {
			putchar((n[i] & mask) ? '1' : '0');
			mask >>= 1;
		} while (mask != 0);
	}
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
parse_line_vectors(char *s, parserinfo_t pi, void *buf, size_t bufsz)
{
	test_vector *tv;
	int n = 0;

	assert(sizeof(*tv) <= bufsz);
	tv = buf;
	memset(tv, 0, sizeof(*tv));

	while (*s != '\0') {
		if (*s != '0' && *s != '1') {
			fprintf(stderr, "Syntax error: Vector contains invalid "
			    "character: %c\n", *s);
			return -1;
		}

		if (n >= pi->pin_count) {
			fprintf(stderr, "Syntax error: Vector contains too "
			    "many pins\n");
			return -1;
		}

		/*
		 * Set the correct pin according to the pin info assembled
		 * earlier when parsing the pindef.
		 */
		if (pi->pins[n].type == INPUT_PIN)
			tv->input_vector[pi->pins[n].bidx] |=
			    (*s - '0') << pi->pins[n].shiftl;
		else
			tv->output_vector[pi->pins[n].bidx] |=
			    (*s - '0') << pi->pins[n].shiftl;

		++n;

		++s;

		/* Skip all whitespace and commas after each bit */
		for (; *s != '\0' && (iswhitespace(*s) || *s == ','); s++)
			;
	}

	if (n < pi->pin_count) {
		fprintf(stderr, "Syntax error: Vector contains too few "
		    "pins\n");
		return -1;
	}

	tv->metadata = REQ_TYPE(REQ_TEST_VECTOR);

	return (int)sizeof(*tv);
}


static
int
parse_line_pindef(char *s, parserinfo_t pi, void *buf, size_t bufsz)
{
	change_bitmask *cb;
	pin_type_t type;
	char *pins[MAX_PINS];
	char *e;
	int pin_no, bidx, shiftl;
	int ntoks, i;

	assert(sizeof(*cb) <= bufsz);
	cb = buf;
	memset(cb, 0, sizeof(*cb));

	cb->metadata = REQ_TYPE(REQ_SETUP_BITMASK);

	pi->pin_count = 0;
	memset(pi->bitmask, 0, sizeof(pi->bitmask));

	/* Tokenize pindef, tokens being separated by whitespace or comma */
	if ((ntoks = tokenizer(s, pins, MAX_PINS)) == -1) {
		fprintf(stderr, "Syntax error: maximum number of pins "
		    "exceeded\n");
		return -1;
	}

	for (i = 0; i < ntoks; i++) {
		/* Determine pin type by first character of pin */
		type = (pins[i][0] == INPUT_PIN) ? INPUT_PIN : OUTPUT_PIN;

		/* Pin number follows the pin type character */
		pin_no = strtol(&(pins[i][1]), &e, 10);
		if (*e != '\0') {
			fprintf(stderr, "Syntax error: pin number must consist "
			    "of only decimal digits\n");
			return -1;
		}

		if (pin_no > ((type == INPUT_PIN) ? MAX_INPUT_PIN : MAX_OUTPUT_PIN)) {
			fprintf(stderr, "Syntax error: pin number %d is out "
			    "of range\n", pin_no);
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

	memcpy(cb->bit_mask, pi->bitmask, sizeof(cb->bit_mask));
	return (int)sizeof(*cb);
}


/*
 * XXX: can add additional error checking to see whether clock: and pindef:
 *      overlap.
 */

/*
 * XXX: can change all the fprintf(stderr, "Syntax error"...) to be a separate
 *      function that will also print the current line number.
 */
static
int
parse_line_clock(char *s, parserinfo_t pi, void *buf, size_t bufsz)
{
	send_dicmd *sd;
	pin_type_t type;
	char *pins[MAX_PINS];
	char *e;
	int pin_no, bidx, shiftl;
	int ntoks, i;

	assert(sizeof(*sd) <= bufsz);
	sd = buf;
	memset(sd, 0, sizeof(*sd));

	sd->metadata = REQ_TYPE(REQ_SEND_DICMD) | DICMD(DICMD_SETUP_MUXES);

	/* Tokenize pindef, tokens being separated by whitespace or comma */
	if ((ntoks = tokenizer(s, pins, MAX_INPUT_OUTPUT_SIZE)) == -1) {
		fprintf(stderr, "Syntax error: maximum number of pins "
		    "exceeded\n");
		return -1;
	}

	for (i = 0; i < ntoks; i++) {
		/* Determine pin type by first character of pin */
		type = (pins[i][0] == INPUT_PIN) ? INPUT_PIN : OUTPUT_PIN;
		if (type == OUTPUT_PIN) {
			fprintf(stderr, "Syntax error: clock signals need to be "
			    "connected to input pins, not output pins\n");
			return -1;
		}

		/* Pin number follows the pin type character */
		pin_no = strtol(&(pins[i][1]), &e, 10);
		if (*e != '\0') {
			fprintf(stderr, "Syntax error: pin number must consist "
			    "of only decimal digits\n");
			return -1;
		}

		if (pin_no > MAX_INPUT_PIN) {
			fprintf(stderr, "Syntax error: pin number %d is out "
			    "of range\n", pin_no);
		}

		/* Find byte index as well as bit within that byte index */
		bidx = 2 /* XXX, magical constant */ - pin_no / 8;
		shiftl = pin_no % 8;

		sd->payload[bidx] |= (1 << shiftl);
	}

	return (int)sizeof(*sd);
}


static
int
parse_line_design(char *s, parserinfo_t pi, void *buf, size_t bufsz)
{
	change_target *ct;
	char *e;

	assert(sizeof(*ct) <= bufsz);
	ct = buf;
	memset(ct, 0, sizeof(*ct));

	ct->metadata = REQ_TYPE(REQ_SWITCH_TARGET);

	ct->design_number = (int)strtol(s, &e, 10);
	if (s == e || *e != '\0') {
		fprintf(stderr, "Syntax error: design number must contain only "
		    "decimal digits\n");
		return -1;
	}

	ct->design_number &= DESIGN_NUMBER_MASK;
	return (int)sizeof(*ct);
}


static
int
generate_end(parserinfo_t pi, void *buf, size_t bufsz)
{
	mem_end *me;
	assert(sizeof(*me) <= bufsz);
	me = buf;
	memset(me, 0, sizeof(*me));

	me->metadata = REQ_TYPE(REQ_END);

	return (int)sizeof(*me);
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
			printf(", metadata2=%c %c\n",
			    (tv->metadata2 & MD2_RUN)  ? 'R' : ' ',
			    (tv->metadata2 & MD2_FAIL) ? 'F' : ' ');
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
parse_file(FILE *fp)
{
	uint8_t buf[128];
	struct parserinfo pi;
	char line[1024];
	char *s, *e;
	int keyword_idx = -1;
	int i, len, ssz;
	off_t mem_off = 0;

	memset(&pi, 0, sizeof(pi));

	while(fgets(line, sizeof(line), fp) != NULL) {
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
			fprintf(stderr, "Syntax error: File must start with "
			    "valid keyword\n");
			return -1;
		}

		/* skip leading whitespace */
		for (; *s != '\0' && iswhitespace(*s); s++)
			;

		/* Effectively empty line */
		if (*s == '\0')
			continue;

		/* Let section-specific line parser do its job */
		ssz = keywords[keyword_idx].lp(s, &pi, buf, sizeof(buf));
		if (ssz < 0)
			return -1;

		print_mem(buf, ssz, NULL);
		if (sflag)
			save_sram_file(buf, ssz);
		if (wflag)
			sram_write(mem_off, buf, (size_t)ssz);

		mem_off += ssz;
	}

	ssz = generate_end(&pi, buf, sizeof(buf));
	if (ssz > 0) {
		print_mem(buf, ssz, NULL);
		if (sflag)
			save_sram_file(buf, ssz);
		if (wflag)
			sram_write(mem_off, buf, (size_t)ssz);

		mem_off += ssz;
	}

	if (wflag) {
		trunner_enable();
		trunner_wait_done();
		print_sram_results();
	}

	return 0;
}


static
void
usage(int exitval)
{
	fprintf(stderr,
		"Usage: confrd [options] <configuration directory>\n"
		"Valid options are:\n"
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
	FILE *fp;
	DIR *mydir;
	char *rpath;
	char fname[PATH_MAX];
	int c, error;


	while ((c = getopt (argc, argv, "s:wh?")) != -1) {
		switch (c) {
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

	rpath = realpath(argv[0], NULL);
	mydir = opendir(rpath);
	if (mydir == NULL) {
		perror("opendir");
		exit(1);
	}

	if (wflag) {
		trunner_print_magic();

		error = sram_open();
		if (error) {
			perror("sram_open");
			exit(1);
		}
	}

	while((entry = readdir(mydir))) {
		if (entry->d_type != DT_REG) {
			fprintf(stderr, "Skipping non-regular entry %s/%s\n",
			    rpath, entry->d_name);
			continue;
		}

		snprintf(fname, PATH_MAX, "%s/%s", rpath, entry->d_name);
		printf("Processing %s\n", fname);

		//Pointer for opening the file
		fp = fopen(fname, "r");
		if (fp == NULL) {
			fprintf(stderr, "The file %s cannot be opened: %s\n",
			    fname, strerror(errno));
			continue;
		}

		parse_file(fp);
		fclose(fp);
	}

	if (wflag)
		sram_close();

	closedir(mydir);
	return 0;
}
