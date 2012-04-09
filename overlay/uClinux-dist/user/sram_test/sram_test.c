#include <sys/types.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "sram.h"

int main(int argc, char *argv[])
{
	off_t offset;
	uint16_t ored;
	uint16_t val;
	int i;
	int n;
	int stepsz;
	int write;
	int error;

	if (argc < 4) {
		fprintf(stderr, "Usage: sram <r/w> <n> <stepsz> [orv]\n");
		exit(1);
	}

	if (argc == 5)
		ored = (int16_t)strtol(argv[4], NULL, 16);
	else
		ored = 0;

	n = atoi(argv[2]);
	stepsz = atoi(argv[3]);

	if (*argv[1] == 'w') {
		write = 1;
		printf("Write mode enabled \n");
	} else {
		write = 0;
		printf("Read mode enabled \n");
	}

	if ((error = sram_open())) {
		perror("sram_open");
		exit(1);
	}

	printf("SRAM opened!\n");
	sleep(1);

	for (i = 0; i < n; i++) {
		offset = i * (stepsz <<1);

		if (write) {
			val = (uint16_t)((i<<1) | ored);
			if ((error = sram_write(offset, &val, sizeof(val)))) {
				fprintf(stderr, "Error during sram_write\n");
				exit(1);
			}
		} else {
			if ((error = sram_read(offset, &val, sizeof(val)))) {
				fprintf(stderr, "Error during sram_read\n");
				exit(1);
			}
			printf("@%#lx: %hx\n", (unsigned long)offset, val);
		}
		sleep(1);
	}

	sleep(1);

	sram_close();

	return 0;
}
