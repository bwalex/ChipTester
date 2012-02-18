#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>

#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
	size_t map_len;
	off_t map_off;
	int fd;
	int16_t *mem, *p;
	int i;
	int write;

	if (argc < 4) {
		fprintf(stderr, "Usage: sram <hex base addr> <hex len>\n");
		exit(1);
	}

	printf("open /dev/mem\n");

	if ((fd = open("/dev/mem", O_RDWR)) < 0) {
		perror("open /dev/mem");
		exit(1);
	}

	if (*argv[1] == 'w') {
		write = 1;
		printf("Write mode enabled \n");
	} else {
		write = 0;
		printf("Read mode enabled \n");
	}

	map_off = (off_t)strtol(argv[2], NULL, 16);
	map_len = (size_t)strtol(argv[3], NULL, 16);

	printf("mmap %#x (%zu)\n", (unsigned long)map_off, map_len);

	mem = mmap(NULL, map_len, PROT_READ | PROT_WRITE , MAP_SHARED,
		   fd, map_off);

	if ((void *)mem == MAP_FAILED) {
		fprintf(stderr, "mmap %#x (%zu)\n", (unsigned long)map_off, map_len);
		perror("mmap");
		exit(1);
	}

	p = mem;
	printf("Memory mapped!\n");
	sleep(1);
	for (i = 0; i < 16; i++) {
		printf("loop: %d\n", i);
		if (write)
			*p++ = i;
		else
			printf("@%#x: %x\n", (unsigned long)map_off + i*2, *p++);
	}

	sleep(1);

	munmap((void *)mem, map_len);
	close(fd);

	return 0;
}
