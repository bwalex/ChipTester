#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <poll.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include "trunner_if.h"

#define MAJOR_NUM               0xFE
#define TRUNNER_IOC_ENABLE      _IO(MAJOR_NUM, 0)
#define TRUNNER_IOC_GET_DONE    _IOR(MAJOR_NUM, 1, uint8_t)
#define TRUNNER_IOC_GET_MAGIC   _IOR(MAJOR_NUM, 2, uint8_t)

void
trunner_print_magic(void)
{
	int fd;
	int error;
	uint8_t magic;

	fd = open("/dev/trunner0", O_RDWR);
	if (fd < 0) {
		perror("open trunner");
		return;
	}

	error = ioctl(fd, TRUNNER_IOC_GET_MAGIC, &magic);
	if (error) {
		perror("ioctl trunner");
		return;
	}

	printf("trunner magic: %#x\n", (unsigned int)magic);

	close(fd);
}


int
trunner_enable(void)
{
	int fd;
	int error;

	fd = open("/dev/trunner0", O_RDWR);
	if (fd < 0) {
		perror("open trunner");
		return -1;
	}

	error = ioctl(fd, TRUNNER_IOC_ENABLE);
	if (error) {
		perror("ioctl trunner");
		return -1;
	}

	close(fd);

	return 0;
}


int
trunner_wait_done(void)
{
	int fd;
	int rc;
	struct pollfd fds;

	fd = open("/dev/trunner0", O_RDWR);
	if (fd < 0) {
		perror("open trunner");
		return -1;
	}

	fds.fd = fd;
	fds.events = POLLIN;
	rc = poll(&fds, 1, -1);
	if (rc <= 0) {
		perror("poll trunner");
		return -1;
	}

	close(fd);

	return 0;
}

