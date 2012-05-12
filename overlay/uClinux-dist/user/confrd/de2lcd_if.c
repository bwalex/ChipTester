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
#include "de2lcd_if.h"

#define MAJOR_NUM               0xFD
#define DE2LCD_IOC_CLEAR	_IO(MAJOR_NUM, 0)
#define DE2LCD_IOC_CURSOR_ON	_IO(MAJOR_NUM, 1)
#define DE2LCD_IOC_CURSOR_OFF	_IO(MAJOR_NUM, 2)
#define DE2LCD_IOC_SET_SHL	_IOW(MAJOR_NUM, 3, int)
#define DE2LCD_IOC_TEST		_IO(MAJOR_NUM, 4)


#define CURSOR_TOPLEFT	0x00
#define CURSOR_BOTLEFT	0x40



int
de2lcd_clear(void)
{
	int fd;
	int error;

	fd = open("/dev/de2lcd0", O_RDWR);
	if (fd < 0) {
		perror("open de2lcd");
		return -1;
	}

	error = ioctl(fd, DE2LCD_IOC_CLEAR);
	if (error) {
		perror("ioctl de2lcd");
		return -1;
	}

	close(fd);

	return 0;
}

int
de2lcd_cursor_on(void)
{
	int fd;
	int error;

	fd = open("/dev/de2lcd0", O_RDWR);
	if (fd < 0) {
		perror("open de2lcd");
		return -1;
	}

	error = ioctl(fd, DE2LCD_IOC_CURSOR_ON);
	if (error) {
		perror("ioctl de2lcd");
		return -1;
	}

	close(fd);

	return 0;
}

int
de2lcd_test(void)
{
	int fd;
	int error;

	fd = open("/dev/de2lcd0", O_RDWR);
	if (fd < 0) {
		perror("open de2lcd");
		return -1;
	}

	error = ioctl(fd, DE2LCD_IOC_TEST);
	if (error) {
		perror("ioctl de2lcd");
		return -1;
	}

	close(fd);

	return 0;
}

int
de2lcd_write(char *str)
{
	int fd;
	ssize_t s;

	fd = open("/dev/de2lcd0", O_RDWR);
	if (fd < 0) {
		perror("open de2lcd");
		return -1;
	}

	s = write(fd, str, strlen(str));
	if (s < 0) {
		perror("write de2lcd");
		return -1;
	}

	close(fd);

	return 0;
}

int
de2lcd_cursor_off(void)
{
	int fd;
	int error;

	fd = open("/dev/de2lcd0", O_RDWR);
	if (fd < 0) {
		perror("open de2lcd");
		return -1;
	}

	error = ioctl(fd, DE2LCD_IOC_CURSOR_OFF);
	if (error) {
		perror("ioctl de2lcd");
		return -1;
	}

	close(fd);

	return 0;
}

int
de2lcd_set_shl(int ms)
{
	int fd;
	int error;

	if (ms < 0)
		return -1;

	fd = open("/dev/de2lcd0", O_RDWR);
	if (fd < 0) {
		perror("open de2lcd");
		return -1;
	}

	error = ioctl(fd, DE2LCD_IOC_SET_SHL, &ms);
	if (error) {
		perror("ioctl de2lcd");
		return -1;
	}

	close(fd);

	return 0;
}

