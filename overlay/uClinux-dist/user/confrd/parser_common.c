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
#include "sram.h"

extern char *cur_filename;
extern int cur_lineno;


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


void
bprint(uint8_t *n, size_t len)
{
	sbprint(NULL, n, len);
}


/* XXX: tons of common code here that can be factored out */
char *
h_input(uint8_t *n, uint8_t *c, size_t len)
{
	static char buf[64];
	uint8_t mask;
	size_t i;
	char *s = buf;

	for (i = 0; i < len; i++) {
		mask = 1 << (8*sizeof(*n) - 1);
		do {
			*s++ = (c[i] & mask) ? 'C' :
				((n[i] & mask) ? '1' : '0');
			mask >>= 1;
		} while (mask != 0);
	}

	if (s)
		*s = '\0';

	return buf;
}


char *
h_output(uint8_t *b, size_t sz)
{
	static char buf[64];

	printf("DEBUG: h_output, b=%p, sz=%ju\n", b, sz);
	sbprint(buf, b, sz);
	printf("DEBUG: h_output post sbprint\n");
	return buf;
}

char *
h_expected(uint8_t *n, uint8_t *x, uint8_t *x2, size_t len)
{
	static char buf[64];
	uint8_t mask;
	size_t i;
	char *s = buf;

	for (i = 0; i < len; i++) {
		mask = 1 << (8*sizeof(*n) - 1);
		do {
			*s++ = ((x[i] | ~x2[i]) & mask) ? 'X' :
				((n[i] & mask) ? '1' : '0');
			mask >>= 1;
		} while (mask != 0);
	}

	if (s)
		*s = '\0';

	return buf;
}


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

again:
		/* Let section-specific line parser do its job */
		error = keywords[keyword_idx].lp(s, priv);
		if ((error == EAGAIN || error == -EAGAIN) && suspend != NULL) {
			if ((error = suspend(priv)) == 0)
				goto again;
		}

		if (error)
			return error;
	}

	return 0;
}


void
init_parserinfo(parserinfo_t pi, globaldata_t gd)
{

	memset(pi, 0, sizeof(*pi));
	pi->pll_m = pll_settings[0].m;
	pi->pll_n = pll_settings[0].n;
	pi->pll_c = pll_settings[0].c;
	pi->sram_free_bytes = SRAM_SIZE;
	pi->gd = gd;
}

