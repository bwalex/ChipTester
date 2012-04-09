#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>

#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

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
	uint16_t *src;
	uint16_t *dst16;

	if (offset + len > SRAM_SIZE)
		return -1;

	dst16 = dst;

	src = ((uint16_t *)mem) + offset/2;
	for (; len > 0; len -= 2)
		*dst16++ = htons(*src++);

	return 0;
}


int
sram_write(off_t offset, void *src, size_t len)
{
	uint16_t *dst;
	uint16_t *src16;

	if (offset + len > SRAM_SIZE)
		return -1;

	src16 = src;

	dst = ((uint16_t *)mem) + offset/2;
	for (; len > 0; len -= 2)
		*dst++ = ntohs(*src16++);

	return 0;
}

