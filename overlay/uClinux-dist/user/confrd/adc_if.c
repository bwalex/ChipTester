#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <poll.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include "adc_if.h"


#define MAJOR_NUM		0xFB
#define ADC_IOC_ENABLE		_IO(MAJOR_NUM, 0)
#define ADC_IOC_GET_DONE	_IOR(MAJOR_NUM, 1, uint8_t)
#define ADC_IOC_GET_MAGIC	_IOR(MAJOR_NUM, 2, uint8_t)

void
adc_print_magic(void)
{
	int fd;
	int error;
	uint8_t magic;

	fd = open("/dev/adc0", O_RDWR);
	if (fd < 0) {
		perror("open adc");
		return;
	}

	error = ioctl(fd, ADC_IOC_GET_MAGIC, &magic);
	if (error) {
		perror("ioctl adc");
		return;
	}

	printf("adc magic: %#x\n", (unsigned int)magic);

	close(fd);
}


int
adc_enable(void)
{
	int fd;
	int error;

	fd = open("/dev/adc0", O_RDWR);
	if (fd < 0) {
		perror("open adc");
		return -1;
	}

	error = ioctl(fd, ADC_IOC_ENABLE);
	if (error) {
		perror("ioctl adc");
		return -1;
	}

	close(fd);

	return 0;
}


int
adc_wait_done(void)
{
	int fd;
	int rc;
	struct pollfd fds;

	fd = open("/dev/adc0", O_RDWR);
	if (fd < 0) {
		perror("open adc");
		return -1;
	}

	fds.fd = fd;
	fds.events = POLLIN;
	rc = poll(&fds, 1, -1);
	if (rc <= 0) {
		perror("poll adc");
		return -1;
	}

	close(fd);

	return 0;
}
