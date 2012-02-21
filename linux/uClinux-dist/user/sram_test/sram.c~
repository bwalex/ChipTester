#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>

#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "sram.h"


static int fd = -1;
static void *mem = NULL;


int
sram_open(void)
{
	if ((fd = open("/dev/mem", O_RDWR)) < 0)
		return -1;

	mem = mmap(NULL, SRAM_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED,
		   fd, SRAM_BASE);

	if (mem == MAP_FAILED) {
		close(fd);
		return -1;
	}

	return 0;
}


void
sram_close(void) {
	if (mem != NULL)
		munmap(mem, SRAM_SIZE);

	if (fd != -1)
		close(fd);

	fd = -1;
	mem = NULL;
}


int
sram_read(off_t offset, void *dst, size_t len)
{
	if (offset + len > SRAM_SIZE)
		return -1;

	memcpy(dst, ((unsigned char *)mem) + offset, len);

	return 0;
}


int
sram_write(off_t offset, void *src, size_t len)
{
	void *dst;

	if (offset + len > SRAM_SIZE)
		return -1;

	dst = ((unsigned char *)mem) + offset;
	memcpy(dst, src, len);

	return 0;
}

