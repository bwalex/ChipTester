static
struct pll_settings {
	uint8_t m;
	uint8_t n;
	uint8_t c;
} pll_settings[] = {
	{ .m = 6,	.n = 1,	.c = 30 },
	{ .m = 25,	.n = 5,	.c = 250 },	/* 1 MHz, err: 0.0 */
	{ .m = 25,	.n = 5,	.c = 125 },	/* 2 MHz, err: 0.0 */
	{ .m = 27,	.n = 5,	.c = 90 },	/* 3 MHz, err: 0.0 */
	{ .m = 26,	.n = 5,	.c = 65 },	/* 4 MHz, err: 0.0 */
	{ .m = 25,	.n = 5,	.c = 50 },	/* 5 MHz, err: 0.0 */
	{ .m = 27,	.n = 5,	.c = 45 },	/* 6 MHz, err: 0.0 */
	{ .m = 28,	.n = 5,	.c = 40 },	/* 7 MHz, err: 0.0 */
	{ .m = 28,	.n = 5,	.c = 35 },	/* 8 MHz, err: 0.0 */
	{ .m = 27,	.n = 5,	.c = 30 },	/* 9 MHz, err: 0.0 */
	{ .m = 25,	.n = 5,	.c = 25 },	/* 10 MHz, err: 0.0 */
	{ .m = 33,	.n = 5,	.c = 30 },	/* 11 MHz, err: 0.0 */
	{ .m = 30,	.n = 5,	.c = 25 },	/* 12 MHz, err: 0.0 */
	{ .m = 26,	.n = 5,	.c = 20 },	/* 13 MHz, err: 0.0 */
	{ .m = 28,	.n = 5,	.c = 20 },	/* 14 MHz, err: 0.0 */
	{ .m = 27,	.n = 5,	.c = 18 },	/* 15 MHz, err: 0.0 */
	{ .m = 32,	.n = 5,	.c = 20 },	/* 16 MHz, err: 0.0 */
	{ .m = 34,	.n = 5,	.c = 20 },	/* 17 MHz, err: 0.0 */
	{ .m = 27,	.n = 5,	.c = 15 },	/* 18 MHz, err: 0.0 */
	{ .m = 38,	.n = 5,	.c = 20 },	/* 19 MHz, err: 0.0 */
	{ .m = 26,	.n = 5,	.c = 13 },	/* 20 MHz, err: 0.0 */
	{ .m = 42,	.n = 5,	.c = 20 },	/* 21 MHz, err: 0.0 */
	{ .m = 33,	.n = 5,	.c = 15 },	/* 22 MHz, err: 0.0 */
	{ .m = 46,	.n = 5,	.c = 20 },	/* 23 MHz, err: 0.0 */
	{ .m = 36,	.n = 5,	.c = 15 },	/* 24 MHz, err: 0.0 */
	{ .m = 25,	.n = 5,	.c = 10 },	/* 25 MHz, err: 0.0 */
	{ .m = 26,	.n = 5,	.c = 10 },	/* 26 MHz, err: 0.0 */
	{ .m = 27,	.n = 5,	.c = 10 },	/* 27 MHz, err: 0.0 */
	{ .m = 28,	.n = 5,	.c = 10 },	/* 28 MHz, err: 0.0 */
	{ .m = 29,	.n = 5,	.c = 10 },	/* 29 MHz, err: 0.0 */
	{ .m = 27,	.n = 5,	.c = 9 },	/* 30 MHz, err: 0.0 */
	{ .m = 31,	.n = 5,	.c = 10 },	/* 31 MHz, err: 0.0 */
	{ .m = 32,	.n = 5,	.c = 10 },	/* 32 MHz, err: 0.0 */
	{ .m = 33,	.n = 5,	.c = 10 },	/* 33 MHz, err: 0.0 */
	{ .m = 34,	.n = 5,	.c = 10 },	/* 34 MHz, err: 0.0 */
	{ .m = 28,	.n = 5,	.c = 8 },	/* 35 MHz, err: 0.0 */
	{ .m = 36,	.n = 5,	.c = 10 },	/* 36 MHz, err: 0.0 */
	{ .m = 37,	.n = 5,	.c = 10 },	/* 37 MHz, err: 0.0 */
	{ .m = 38,	.n = 5,	.c = 10 },	/* 38 MHz, err: 0.0 */
	{ .m = 39,	.n = 5,	.c = 10 },	/* 39 MHz, err: 0.0 */
	{ .m = 28,	.n = 5,	.c = 7 },	/* 40 MHz, err: 0.0 */
	{ .m = 41,	.n = 5,	.c = 10 },	/* 41 MHz, err: 0.0 */
	{ .m = 42,	.n = 5,	.c = 10 },	/* 42 MHz, err: 0.0 */
	{ .m = 43,	.n = 5,	.c = 10 },	/* 43 MHz, err: 0.0 */
	{ .m = 44,	.n = 5,	.c = 10 },	/* 44 MHz, err: 0.0 */
	{ .m = 27,	.n = 5,	.c = 6 },	/* 45 MHz, err: 0.0 */
	{ .m = 46,	.n = 5,	.c = 10 },	/* 46 MHz, err: 0.0 */
	{ .m = 47,	.n = 5,	.c = 10 },	/* 47 MHz, err: 0.0 */
	{ .m = 48,	.n = 5,	.c = 10 },	/* 48 MHz, err: 0.0 */
	{ .m = 49,	.n = 5,	.c = 10 },	/* 49 MHz, err: 0.0 */
	{ .m = 25,	.n = 5,	.c = 5 },	/* 50 MHz, err: 0.0 */
	{ .m = 51,	.n = 5,	.c = 10 },	/* 51 MHz, err: 0.0 */
	{ .m = 26,	.n = 5,	.c = 5 },	/* 52 MHz, err: 0.0 */
	{ .m = 53,	.n = 5,	.c = 10 },	/* 53 MHz, err: 0.0 */
	{ .m = 27,	.n = 5,	.c = 5 },	/* 54 MHz, err: 0.0 */
	{ .m = 33,	.n = 5,	.c = 6 },	/* 55 MHz, err: 0.0 */
	{ .m = 28,	.n = 5,	.c = 5 },	/* 56 MHz, err: 0.0 */
	{ .m = 57,	.n = 5,	.c = 10 },	/* 57 MHz, err: 0.0 */
	{ .m = 29,	.n = 5,	.c = 5 },	/* 58 MHz, err: 0.0 */
	{ .m = 59,	.n = 5,	.c = 10 },	/* 59 MHz, err: 0.0 */
	{ .m = 30,	.n = 5,	.c = 5 },	/* 60 MHz, err: 0.0 */
	{ .m = 55,	.n = 5,	.c = 9 },	/* 61 MHz, err: 0.11111111111111427 */
	{ .m = 31,	.n = 5,	.c = 5 },	/* 62 MHz, err: 0.0 */
	{ .m = 44,	.n = 5,	.c = 7 },	/* 63 MHz, err: 0.1428571428571459 */
	{ .m = 32,	.n = 5,	.c = 5 },	/* 64 MHz, err: 0.0 */
	{ .m = 26,	.n = 5,	.c = 4 },	/* 65 MHz, err: 0.0 */
	{ .m = 33,	.n = 5,	.c = 5 },	/* 66 MHz, err: 0.0 */
	{ .m = 47,	.n = 5,	.c = 7 },	/* 67 MHz, err: 0.1428571428571388 */
	{ .m = 34,	.n = 5,	.c = 5 },	/* 68 MHz, err: 0.0 */
	{ .m = 55,	.n = 5,	.c = 8 },	/* 69 MHz, err: 0.25 */
	{ .m = 28,	.n = 5,	.c = 4 },	/* 70 MHz, err: 0.0 */
	{ .m = 57,	.n = 5,	.c = 8 },	/* 71 MHz, err: 0.25 */
	{ .m = 36,	.n = 5,	.c = 5 },	/* 72 MHz, err: 0.0 */
	{ .m = 51,	.n = 5,	.c = 7 },	/* 73 MHz, err: 0.1428571428571388 */
	{ .m = 37,	.n = 5,	.c = 5 },	/* 74 MHz, err: 0.0 */
	{ .m = 30,	.n = 5,	.c = 4 },	/* 75 MHz, err: 0.0 */
	{ .m = 38,	.n = 5,	.c = 5 },	/* 76 MHz, err: 0.0 */
	{ .m = 54,	.n = 5,	.c = 7 },	/* 77 MHz, err: 0.1428571428571388 */
	{ .m = 39,	.n = 5,	.c = 5 },	/* 78 MHz, err: 0.0 */
	{ .m = 55,	.n = 5,	.c = 7 },	/* 79 MHz, err: 0.4285714285714306 */
	{ .m = 32,	.n = 5,	.c = 4 },	/* 80 MHz, err: 0.0 */
	{ .m = 57,	.n = 5,	.c = 7 },	/* 81 MHz, err: 0.4285714285714306 */
	{ .m = 41,	.n = 5,	.c = 5 },	/* 82 MHz, err: 0.0 */
	{ .m = 58,	.n = 5,	.c = 7 },	/* 83 MHz, err: 0.1428571428571388 */
	{ .m = 42,	.n = 5,	.c = 5 },	/* 84 MHz, err: 0.0 */
	{ .m = 34,	.n = 5,	.c = 4 },	/* 85 MHz, err: 0.0 */
	{ .m = 43,	.n = 5,	.c = 5 },	/* 86 MHz, err: 0.0 */
	{ .m = 26,	.n = 5,	.c = 3 },	/* 87 MHz, err: 0.3333333333333286 */
	{ .m = 44,	.n = 5,	.c = 5 },	/* 88 MHz, err: 0.0 */
	{ .m = 53,	.n = 5,	.c = 6 },	/* 89 MHz, err: 0.6666666666666714 */
	{ .m = 27,	.n = 5,	.c = 3 },	/* 90 MHz, err: 0.0 */
	{ .m = 55,	.n = 5,	.c = 6 },	/* 91 MHz, err: 0.6666666666666714 */
	{ .m = 46,	.n = 5,	.c = 5 },	/* 92 MHz, err: 0.0 */
	{ .m = 28,	.n = 5,	.c = 3 },	/* 93 MHz, err: 0.3333333333333286 */
	{ .m = 47,	.n = 5,	.c = 5 },	/* 94 MHz, err: 0.0 */
	{ .m = 38,	.n = 5,	.c = 4 },	/* 95 MHz, err: 0.0 */
	{ .m = 48,	.n = 5,	.c = 5 },	/* 96 MHz, err: 0.0 */
	{ .m = 29,	.n = 5,	.c = 3 },	/* 97 MHz, err: 0.3333333333333286 */
	{ .m = 49,	.n = 5,	.c = 5 },	/* 98 MHz, err: 0.0 */
	{ .m = 59,	.n = 5,	.c = 6 },	/* 99 MHz, err: 0.6666666666666714 */
	{ .m = 30,	.n = 5,	.c = 3 },	/* 100 MHz, err: 0.0 */
};
