#include <sys/types.h>
#include <stdio.h>
#include <limits.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <assert.h>
#include <unistd.h>
#include <dirent.h>
#include <errno.h>


#define COMMENT_CHAR		'#' //Comment definition
//#define INPUT_PIN		'A' //Input pin definition
//#define OUTPUT_PIN		'Q' //Output pin definition

#define MAX_INPUT_OUTPUT_SIZE	24
#define MAX_INPUT_PIN		(MAX_INPUT_OUTPUT_SIZE-1)
#define MAX_OUTPUT_PIN		(MAX_INPUT_OUTPUT_SIZE-1)
#define BITMASK_BYTES		MAX_INPUT_OUTPUT_SIZE
#define MAX_PINS		(2*MAX_INPUT_OUTPUT_SIZE)

#define DESIGN_NUMBER_MASK 	0x1f

#define REQ_SWITCH_TARGET	0x00
#define REQ_TEST_VECTOR		0x01
#define REQ_SETUP_BITMASK	0x02

#define REQ_TYPE(r)		((r & 0x07) << 5)

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
} change_target;


typedef struct change_bitmask {
	uint8_t metadata;
	uint8_t bit_mask[3];
} change_bitmask;


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



struct keyword keywords[] = {
	{ .keyword = "design"	, .lp = parse_line_design  },
	{ .keyword = "pindef"	, .lp = parse_line_pindef  },
	{ .keyword = "vectors"	, .lp = parse_line_vectors },
	{ .keyword = NULL	, .lp = NULL }
};


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

		if (pi->pins[n].type == INPUT_PIN)
			tv->input_vector[pi->pins[n].bidx] |=
			    (*s - '0') << pi->pins[n].shiftl;
		else
			tv->output_vector[pi->pins[n].bidx] |=
			    (*s - '0') << pi->pins[n].shiftl;

		++n;

		++s;
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

	if ((ntoks = tokenizer(s, pins, MAX_PINS)) == -1) {
		fprintf(stderr, "Syntax error: maximum number of pins "
		    "exceeded\n");
		return -1;
	}

	for (i = 0; i < ntoks; i++) {
		/* XXX: Use shorter named local variables, only assign to the pininfo, etc, in the end */
		type =
		    (pins[i][0] == INPUT_PIN) ? INPUT_PIN : OUTPUT_PIN;

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

		bidx = 2 /* XXX, magical constant */ - pin_no / 8;
		shiftl = pin_no % 8;

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


void
print_struct(void *buf, int sz)
{
	change_target *ct;
	change_bitmask *cb;
	test_vector *tv;
	uint8_t *metadatap;
	
	metadatap = buf;

	while (sz > 0) {
		switch (*metadatap >> 5) {
		case REQ_SWITCH_TARGET:
			ct = buf;
			sz -= sizeof(*ct);
			printf("REQ_SWITCH_TARGET: target=%d\n", (int)ct->design_number);
			break;

		case REQ_SETUP_BITMASK:
			cb = buf;
			sz -= sizeof(*cb);
			printf("REQ_SETUP_BITMASK: bitmask=");
			bprint(cb->bit_mask, sizeof(cb->bit_mask));
			putchar('\n');
			break;

		case REQ_TEST_VECTOR:
			tv = buf;
			sz -= sizeof(*tv);
			printf("REQ_TEST_VECTOR: iv=");
			bprint(tv->input_vector, sizeof(tv->input_vector));
			printf(", ov=");
			bprint(tv->output_vector, sizeof(tv->output_vector));
			printf(", metadata2=%#x\n", (unsigned int)tv->metadata2);
			break;

		default:
			printf("INVALID REQUEST TYPE: %#x\n",
			    (unsigned int)(*metadatap >> 5));
			return;
		}
	}
}



static
int
parse_file(FILE *fp)
{
	uint8_t buf[128];
	struct parserinfo pi;
	char line[1024];
	char *s, *e;
	keyword_t kwp;
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

		ssz = keywords[keyword_idx].lp(s, &pi, buf, sizeof(buf));
		if (ssz < 0)
			return -1;

		print_struct(buf, ssz);
	}
}


int
main(int argc, char *argv[])
{
	FILE *fp;
	DIR *mydir;
	char *rpath;
	char fname[PATH_MAX];

	if (argc < 2) {
		fprintf(stderr, "Need one argument\n");
		exit(1);
	}

	rpath = realpath(argv[1], NULL);
	mydir = opendir(rpath);
	/* XXX: Check for opendir error */
	
	struct dirent *entry = NULL;

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
