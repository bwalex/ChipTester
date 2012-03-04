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

#define DICMD_SETUP_MUXES	0x01

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


typedef struct change_target {
	uint8_t metadata;
	uint8_t design_number;
	uint8_t padding[2];
} change_target;


typedef struct change_bitmask {
	uint8_t metadata;
	uint8_t bit_mask[3];
} change_bitmask;


typedef struct send_dicmd {
	uint8_t metadata;
	uint8_t payload[3];
} send_dicmd;


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
	{ .keyword = "clock"    , .lp = parse_line_clock   },
	{ .keyword = NULL	, .lp = NULL }
};

int sflag = 0;
char *sram_file = NULL;


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
void
print_mem(uint8_t *buf, int sz)
{
	change_target *ct;
	change_bitmask *cb;
	test_vector *tv;
	send_dicmd *sd;
	uint8_t *metadatap;

	while (sz > 0) {
		metadatap = buf;

		switch (*metadatap >> 5) {
		case REQ_SWITCH_TARGET:
			ct = (change_target *)buf;
			sz -= sizeof(*ct);
			buf += sizeof(*ct);
			printf("REQ_SWITCH_TARGET:\ttarget=%d\n", (int)ct->design_number);
			break;

		case REQ_SETUP_BITMASK:
			cb = (change_bitmask *)buf;
			sz -= sizeof(*cb);
			buf += sizeof(*cb);
			printf("REQ_SETUP_BITMASK:\tbitmask=");
			bprint(cb->bit_mask, sizeof(cb->bit_mask));
			putchar('\n');
			break;

		case REQ_TEST_VECTOR:
			tv = (test_vector *)buf;
			sz -= sizeof(*tv);
			buf += sizeof(*tv);
			printf("REQ_TEST_VECTOR:\tiv=");
			bprint(tv->input_vector, sizeof(tv->input_vector));
			printf(", ov=");
			bprint(tv->output_vector, sizeof(tv->output_vector));
			printf(", metadata2=%#x\n", (unsigned int)tv->metadata2);
			break;

		case REQ_SEND_DICMD:
			sd = (send_dicmd *)buf;
			sz -= sizeof(*sd);
			buf += sizeof(*sd);
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

		default:
			printf("INVALID REQUEST TYPE: %#x\n",
			    (unsigned int)(*metadatap >> 5));
			return;
		}
	}
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
parse_file(FILE *fp)
{
	uint8_t buf[128];
	struct parserinfo pi;
	char line[1024];
	char *s, *e;
	int keyword_idx = -1;
	int i, len, ssz;

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

		print_mem(buf, ssz);
		if (sflag)
			save_sram_file(buf, ssz);
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
	int c;


	while ((c = getopt (argc, argv, "s:")) != -1) {
		switch (c) {
		case 's':
			sflag = 1;
			sram_file = optarg;
			/* Delete old file if present, since we'll be appending */
			unlink(sram_file);
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

	closedir(mydir);
	return 0;
}
