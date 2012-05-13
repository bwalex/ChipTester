#include "sram.h"

#define LOGDEBUG		1
#define LOGINFO			2
#define LOGWARN			3
#define LOGERR			4

#define COMMENT_CHAR		'#' //Comment definition

#define MAX_INPUT_OUTPUT_SIZE	24
#define MAX_INPUT_PIN		(MAX_INPUT_OUTPUT_SIZE-1)
#define MAX_OUTPUT_PIN		(MAX_INPUT_OUTPUT_SIZE-1)
#define BITMASK_BYTES		(MAX_INPUT_OUTPUT_SIZE/8)
#define MAX_PINS		(2*MAX_INPUT_OUTPUT_SIZE)

#define DESIGN_NUMBER_MASK	0x1f

#define REQ_SWITCH_TARGET	0x00
#define REQ_TEST_VECTOR		0x01
#define REQ_SETUP_BITMASK	0x02
#define REQ_SEND_DICMD		0x03
#define REQ_PLLRECONFIG		0x06
#define REQ_END			0x07

#define DICMD_SETUP_MUXES	0x01
#define DICMD_TRGMASK           0x02

#define MD2_FAIL		0x01
#define MD2_RUN			0x80
#define MD2_TIMEOUT             0x40
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


struct test_vector {
	uint8_t metadata;
	uint8_t input_vector[3];
	uint8_t output_vector[3];
	uint8_t metadata2;
	uint8_t x_mask[3];
	uint8_t padding;
} __attribute__((__packed__));

typedef struct test_vector test_vector;
typedef struct test_vector *test_vector_t;


struct change_target {
	uint8_t metadata;
	uint8_t design_number;
	uint8_t padding[2];
	uint8_t padding2[2];
} __attribute__((__packed__));

typedef struct change_target change_target;
typedef struct change_target *change_target_t;


struct change_bitmask {
	uint8_t metadata;
	uint8_t bit_mask[3];
	uint8_t padding[2];
} __attribute__((__packed__));

typedef struct change_bitmask change_bitmask;
typedef struct change_bitmask *change_bitmask_t;


struct send_dicmd {
	uint8_t metadata;
	uint8_t payload[3];
	uint8_t padding[2];
} __attribute__((__packed__));

typedef struct send_dicmd send_dicmd;
typedef struct send_dicmd *send_dicmd_t;


struct pll_reconfig {
	uint8_t metadata;
	uint8_t mul_factor;
	uint8_t div_factor;
	uint8_t div_factor_post;
	uint8_t padding[2];
} __attribute__((__packed__));

typedef struct pll_reconfig pll_reconfig;
typedef struct pll_reconfig *pll_reconfig_t;


struct mem_end {
	uint8_t metadata;
	uint8_t unused1;
	uint8_t padding[2];
	uint8_t padding2[2];
} __attribute__((__packed__));

typedef struct mem_end mem_end;
typedef struct mem_end *mem_end_t;


typedef struct pininfo {
	pin_type_t	type;
	int		pin_no;
	int		bidx;
	int		shiftl;
} *pininfo_t;


typedef struct globaldata {
	int team_no;
	int result_id;
	char *email;
	char *base_url;
	char *academic_year;
} *globaldata_t;


typedef int (*line_parser)(char *, void *);
typedef int (*suspend_fn)(void *);


typedef struct parserinfo {
	globaldata_t gd;

	int design_result_id;

	suspend_fn suspend_fn;

	char *file_name;
	char *design_name;

	size_t sram_free_bytes;
	off_t  sram_off;

	int pll_freq;
	uint8_t pll_m;
	uint8_t pll_n;
	uint8_t pll_c;
	int seen_vectors;

	int pin_count;
	uint8_t bitmask[BITMASK_BYTES];
	uint8_t trigger_mask[BITMASK_BYTES];
	uint8_t clock_mask[BITMASK_BYTES];
	struct pininfo pins[MAX_PINS];
	uint8_t output[3*SRAM_SIZE/sizeof(test_vector)];
	int output_idx;
} *parserinfo_t;


typedef struct tv_helper {
	char *input;
	char *output;
} tv_helper, *tv_helper_t;


typedef struct keyword {
	const char	*keyword;
	line_parser	lp;
} *keyword_t;

typedef struct dotcommand {
	const char *command;
	line_parser lp;
} *dotcommand_t;



int suspend_emit(void *p);
int emit(parserinfo_t pi, void *b, size_t bufsz);
int run_trunner(parserinfo_t pi, int process);
void *stage_alloc_chunk(parserinfo_t pi, size_t sz);
int go(parserinfo_t pi, int process);
char *build_url(parserinfo_t pi, const char *req_path_fmt, ...);
int init_remote(parserinfo_t pi);
int submit_measurement_freq(parserinfo_t pi, double freq);

size_t req_sz(int req);
size_t print_mem(uint8_t *buf, int sz, int *end);
void print_req(uint8_t *buf, size_t sz, int *end);

void vlog(int loglevel, const char *fmt, va_list ap);
void logger(int loglevel, const char *fmt, ...);
void syntax_error(const char *fmt, ...);

void sbprint(char *s, uint8_t *n, size_t len);
void bprint(uint8_t *n, size_t len);
char *h_input(uint8_t *, uint8_t *, size_t);
char *h_output(uint8_t *, size_t);
char *h_expected(uint8_t *, uint8_t *, uint8_t *, size_t);
int tokenizer(char *s, char **tokens, int max_tokens);
int parse_file(char *fname, FILE *fp, keyword_t keywords, suspend_fn suspend, void *priv);
void init_parserinfo(parserinfo_t pi, globaldata_t gd);

int parse_cfg_file(char *filename, globaldata_t gd, parserinfo_t pi);

int emit_end(parserinfo_t pi);
int emit_pre_vectors(parserinfo_t pi);
int emit_change_target(parserinfo_t pi, globaldata_t gd);
int parse_vec_file(char *filename, suspend_fn sus_fn, parserinfo_t pi);
