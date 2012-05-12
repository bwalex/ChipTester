#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <poll.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "fcounter_if.h"


#define MAJOR_NUM		0xFC
#define FCOUNTER_IOC_ENABLE	_IO(MAJOR_NUM, 0)
#define FCOUNTER_IOC_GET_COUNT	_IOR(MAJOR_NUM, 1, uint32_t)
#define FCOUNTER_IOC_GET_MAGIC	_IOR(MAJOR_NUM, 2, uint32_t)
#define FCOUNTER_IOC_SET_CYCLES	_IOW(MAJOR_NUM, 3, uint32_t)
#define FCOUNTER_IOC_SET_IPSEL	_IOW(MAJOR_NUM, 4, uint32_t)


int
fcounter_set_cycles(uint32_t cyc)
{
	int fd;
	int error;

	fd = open("/dev/fcounter0", O_RDWR);
	if (fd < 0) {
		perror("open fcounter");
		return -1;
	}

	error = ioctl(fd, FCOUNTER_IOC_SET_CYCLES, &cyc);
	if (error) {
		perror("ioctl fcounter");
		return -1;
	}

	close(fd);

	return 0;
}


int
fcounter_select(int idx)
{
	int fd;
	int error;
	uint32_t n = (uint32_t)idx;

	fd = open("/dev/fcounter0", O_RDWR);
	if (fd < 0) {
		perror("open fcounter");
		return -1;
	}

	error = ioctl(fd, FCOUNTER_IOC_SET_IPSEL, &n);
	if (error) {
		perror("ioctl fcounter");
		return -1;
	}

	close(fd);

	return 0;
}


int
fcounter_get_count(uint32_t *pcount)
{
	int fd;
	int error;
	uint32_t count;

	fd = open("/dev/fcounter0", O_RDWR);
	if (fd < 0) {
		perror("open fcounter");
		return -1;
	}

	error = ioctl(fd, FCOUNTER_IOC_GET_COUNT, &count);
	if (error) {
		perror("ioctl fcounter");
		return -1;
	}

	close(fd);

	*pcount = count;

	return 0;
}


int
fcounter_read_count(uint32_t *pcount)
{
	int fd;
	ssize_t sz;
	uint32_t count;

	fd = open("/dev/fcounter0", O_RDWR);
	if (fd < 0) {
		perror("open fcounter");
		return -1;
	}

	sz = read(fd, &count, sizeof(count));
	if (sz < 0) {
		perror("ioctl fcounter");
		return -1;
	}

	close(fd);

	*pcount = count;

	return 0;
}


void
fcounter_print_magic(void)
{
	int fd;
	int error;
	uint32_t magic;

	fd = open("/dev/fcounter0", O_RDWR);
	if (fd < 0) {
		perror("open fcounter");
		return;
	}

	error = ioctl(fd, FCOUNTER_IOC_GET_MAGIC, &magic);
	if (error) {
		perror("ioctl fcounter");
		return;
	}

	printf("fcounter magic: %#x\n", (unsigned int)magic);

	close(fd);
}


int
fcounter_enable(void)
{
	int fd;
	int error;

	fd = open("/dev/fcounter0", O_RDWR);
	if (fd < 0) {
		perror("open fcounter");
		return -1;
	}

	error = ioctl(fd, FCOUNTER_IOC_ENABLE);
	if (error) {
		perror("ioctl fcounter");
		return -1;
	}

	close(fd);

	return 0;
}


int
fcounter_wait_done(void)
{
	int fd;
	int rc;
	struct pollfd fds;

	fd = open("/dev/fcounter0", O_RDWR);
	if (fd < 0) {
		perror("open fcounter");
		return -1;
	}

	fds.fd = fd;
	fds.events = POLLIN;
	rc = poll(&fds, 1, -1);
	if (rc <= 0) {
		perror("poll fcounter");
		return -1;
	}

	close(fd);

	return 0;
}

