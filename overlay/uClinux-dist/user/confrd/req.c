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



size_t
req_sz(int req)
{
	switch (req) {
	case REQ_SWITCH_TARGET:	return sizeof(change_target);
	case REQ_TEST_VECTOR:	return sizeof(test_vector);
	case REQ_SETUP_BITMASK:	return sizeof(change_bitmask);
	case REQ_SEND_DICMD:	return sizeof(send_dicmd);
	case REQ_PLLRECONFIG:   return sizeof(pll_reconfig);
	case REQ_END:		return sizeof(mem_end);
	default:
		fprintf(stderr, "Warning, unknown req type: %d\n", req);
		return 0;
	}
}


size_t
print_mem(uint8_t *buf, int sz, int *end)
{
	change_target *ct;
	change_bitmask *cb;
	test_vector *tv;
	send_dicmd *sd;
	pll_reconfig *pr;
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
			printf(", xmask=");
			bprint(tv->x_mask, sizeof(tv->x_mask));
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

		case REQ_PLLRECONFIG:
			pr = (pll_reconfig *)buf;
			printf("REQ_PLLRECONFIG:\tm=%d, n=%d, c=%d "
			   "=> frequency: %.1f MHz\n", pr->mul_factor, pr->div_factor,
			   pr->div_factor_post,
			       (100.0 * pr->mul_factor/pr->div_factor/(pr->div_factor_post*2)));
			break;

		case REQ_END:
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

