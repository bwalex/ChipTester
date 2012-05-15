/*
 * spi.c
 *
 *  	Created on: 9 Apr 2012
 *      Author: Romel Torres
 *      Email: rt5g11@soton.ac.uk
 *
 */

#include <sys/time.h>
#include <sys/stat.h>
#include <inttypes.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <assert.h>
#include <getopt.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include "spidev.h"
#include "spi.h"
#include "spi_flash_model.h"

/*Global Variables*/
static const char *device = "";
static const char *file = NULL;
static uint8_t mode;
static uint8_t bits = 8;
static uint32_t speed = 8000000;
static uint16_t delay;
static int tflag = 0;
static int cflag = 0;
static int iflag = 0;

#define SECTOR_SIZE 4096
#define PAGE_SIZE 256

//Read instructions
#define READ_JEDEC_ID 0x9F
#define READ_UNIQUE_ID 0x4B
#define READ_DEVICE_ID 0x90
#define READ_DATA 0x03
#define READ_STATUS_REGISTER_1 0x05
#define READ_STATUS_REGISTER_2 0x35

//Erase instructions
#define CHIP_ERASE 0xC7
#define BLOCK_64_ERASE 0xD8
#define BLOCK_32_ERASE 0x52
#define SECTOR_ERASE 0x20

//Write instructions
#define WRITE_ENABLE 0x06
#define WRITE_DISABLE 0x04
#define WRITE_ENABLE_VOLATILE 0x50
#define WRITE_STATUS_REGISTER 0x01
#define PAGE_PROGRAM 0x02

//Masks
#define MANUFACTURER_ADDRESS 0x000000
#define ADDR_24_MASK 0xFF000000
#define MAX_BIT_ADDR 24
#define DUMMY_BYTES 4
#define REGISTER_BUSY 0x01

//Communication types
#define FULL_DUPLEX 0
#define WRITE 1

#define MANUFACTURER_ID 0xEF
#define DEVICE_ID 0x16
#define MEMORY_TYPE 0x40
#define CAPACITY 0x17


int spi_xfer(int fd, uint8_t* txbuf, size_t txlen, uint8_t* rxbuf, size_t rxlen, uint8_t full_duplex)
{
	//return model_spi_xfer(txbuf, txlen, rxbuf, rxlen);
	int status;
	//SPI Transfers
	struct spi_ioc_transfer xfer[2];
	struct spi_ioc_transfer write_xfer;

	memset(xfer, 0, sizeof(xfer));
	memset(&write_xfer, 0, sizeof(write_xfer));

	if (tflag) {
		/* Running in test mode, only using model */
		return model_spi_xfer(txbuf, txlen, rxbuf, rxlen);
	}

	switch (full_duplex) {
	case FULL_DUPLEX:
		xfer[0].tx_buf = (unsigned long) txbuf;
		xfer[0].len = txlen;
		//The chip select must not change between instructions.
		xfer[0].cs_change = 0;
		xfer[1].rx_buf = (unsigned long) rxbuf;
		status = ioctl(fd,SPI_IOC_MESSAGE(2), xfer);
		if(status < 0) {
			perror("SPI_IOC_MESSAGE");
			return -1;
		}
		return 0;
		break;
	case WRITE:
		if(rxbuf != NULL)
			fprintf(stderr, "Are you sure you want just a WRITE instead of a FULL communication?, ignoring rx_buf and rxlen");
		//Chip select does change at the end of the instruction
		write_xfer.tx_buf = (unsigned long) txbuf;
		write_xfer.len = txlen;
		status = ioctl(fd,SPI_IOC_MESSAGE(1), write_xfer);
		if(status < 0) {
			perror("SPI_IOC_MESSAGE");
			return -1;
		}
		return 0;
		break;
	default:
		return -1;
	}
}


int write_enable(int fd) {
	uint8_t buf;
	int status;

	buf = WRITE_ENABLE;
	//Just Write operation
	status = spi_xfer(fd, &buf, 1, NULL,0, WRITE);
	if(status < 0) {
		fprintf(stderr,"WRITE ENABLE could not be processed\n");
		return -1;
	}
	return 0;
}

int write_disable(int fd) {
	uint8_t buf;
	int status;

	buf = WRITE_DISABLE;
	//Just Write operation
	status = spi_xfer(fd, &buf, 1, NULL, 0, WRITE);
	if(status < 0) {
		fprintf(stderr,"WRITE DISABLE could not be processed\n");
		return -1;
	}

	return 0;
}

int write_enable_sreg(int fd) {
	uint8_t buf;
	int status;

	buf = WRITE_ENABLE_VOLATILE;
	//Just Write operation
	status = spi_xfer(fd, &buf, 1, NULL,0, WRITE);
	if(status < 0) {
		fprintf(stderr,"WRITE ENABLE FOR VOLATILE REGISTER could not be processed\n");
		return -1;
	}
	return 0;
}

int read_sreg1(int fd, uint8_t *sreg1) {
	uint8_t buf;
	int status;
	buf = READ_STATUS_REGISTER_1;
	//FULL duplex instruction, the result of the status register 1 is stored in the pointer *sreg1
	status = spi_xfer(fd, &buf,1,sreg1,1,FULL_DUPLEX);
	if(status < 0) {
		fprintf(stderr,"READ STATUS REGISTER 1 could not be processed\n");
		return -1;
	}
	return 0;
}

int read_sreg2(int fd, uint8_t *sreg2) {
	uint8_t buf;
	int status;
	buf = READ_STATUS_REGISTER_2;
	//FULL duplex instruction, the result of the status register 2 is stored in the pointer *sreg2
	status = spi_xfer(fd, &buf,1,sreg2,1,FULL_DUPLEX);
	if(status < 0) {
		fprintf(stderr,"READ STATUS REGISTER 1 could not be processed\n");
		return -1;
	}
	return 0;
}

int wait_busy(int fd) {
	uint8_t sreg1 = 0xFF;
	do {
		if(read_sreg1(fd,&sreg1) < 0) {
			return -1;
		}
	}while((sreg1 & REGISTER_BUSY) != 0);
	return 0;
}

int write_sreg(int fd, uint8_t sreg1, uint8_t sreg2) {
	uint8_t buffer[3];
	int status;
	buffer[0] = WRITE_STATUS_REGISTER;
	buffer[1] = sreg1;
	buffer[2] = sreg2;
	if(wait_busy(fd) < 0) {
		fprintf(stderr,"WRITE STATUS REGISTER could not be processed, Busy status could not be retrieved\n");
		return -1;
	}
	status = spi_xfer(fd,buffer,3,NULL,0,WRITE);
	if(status < 0) {
		fprintf(stderr,"WRITE STATUS REGISTER could not be processed\n");
		return -1;
	}
	printf("WRITE STATUS REGISTER successful");
	return 0;
}


int chip_erase(int fd) {
	uint8_t buf;
	int status;

	if(wait_busy(fd) < 0) {
		fprintf(stderr,"CHIP ERASE could not be processed, Busy status could not be retrieved\n");
		return -1;
	}

	if(write_enable(fd) < 0) {
		fprintf(stderr,"CHIP ERASE could not be processed\n");
		return -1;
	}

	buf = CHIP_ERASE;
	status = spi_xfer(fd, &buf, 1, NULL, 0, WRITE);
	if(status < 0) {
		fprintf(stderr,"CHIP ERASE could not be processed\n");
		return -1;
	}
	if(wait_busy(fd) < 0) {
		fprintf(stderr,"CHIP ERASE could not be processed, Busy status could not be retrieved\n");
		return -1;
	}
	return 0;
}

int read_data(int fd, uint32_t addr, size_t len, uint8_t *buffer) {

	int status;
	//Error Handling
	if((ADDR_24_MASK & addr) != 0) {
		fprintf(stderr,"The specified address 0x%X is too big, the maximum address allowed is 0x00FFFFFF\n", addr);
		return -1;
	}
	else if(ADDR_24_MASK & (addr + len*8)) {
		fprintf(stderr,"The amount of bytes %d to read exceeds the size of the memory\n",(int) len);
		return -1;
	}

	buffer[0] = (uint8_t) READ_DATA;
	buffer[1] = (uint8_t) (addr >> 16);
	buffer[2] = (uint8_t) (addr >> 8);
	buffer[3] = (uint8_t) (addr) ;
	/*If it's busy wait until it is free*/
	if(wait_busy(fd) < 0) {
		fprintf(stderr,"READ DATA could not be processed\n");
		return -1;
	}
	status = spi_xfer(fd, buffer,4,buffer,len,FULL_DUPLEX);
	if(status < 0) {
		perror("SPI_IOC_MESSAGE");
		fprintf(stderr,"READ DATA could not be processed\n");
		return -1;
	}
	return 0;
}

int read_jedecID(int fd, read_jedec_id *jedec_data) {
	uint8_t buffer[4];
	int status;
	memset((void *)buffer, 0, sizeof buffer);

	//Set instruction
	buffer[0] = READ_JEDEC_ID;
	/*If it's busy wait until it is free*/
	if(wait_busy(fd) < 0) {
		fprintf(stderr,"READ JEDEC ID could not be processed\n");
		return -1;
	}
	status = spi_xfer(fd, buffer,1,buffer,3,FULL_DUPLEX);
	if(status < 0) {
		fprintf(stderr,"READ JEDEC ID could not be processed\n");
		return -1;
	}
	jedec_data->manufacturer_id = buffer[0];
	jedec_data->memory_type = buffer[1];
	jedec_data->capacity = buffer[2];
	return 0;
}

int read_unique_id(int fd, uint64_t *unique_id) {
	//64 bit long plus 5bytes of instructions.
	uint8_t buffer[8];
	int status;

	buffer[0] = READ_UNIQUE_ID;
	/*If it's busy wait until it is free*/
	if(wait_busy(fd) < 0) {
		fprintf(stderr,"READ UNIQUE ID could not be processed\n");
		return -1;
	}
	status = spi_xfer(fd, buffer,DUMMY_BYTES + 1, (uint8_t *)unique_id,8,FULL_DUPLEX);
	if(status < 0) {
		fprintf(stderr,"READ UNIQUE ID could not be processed\n");
		return -1;
	}
	return 0;
}

int read_manufacturer_id(int fd, manufacturer_read *mf_data) {
	uint8_t buffer[4];
	int status;
	memset((void *)buffer, 0, sizeof buffer);
	buffer[0] = READ_DEVICE_ID;
	/*If it's busy wait until it is free*/
	if(wait_busy(fd) < 0) {
		fprintf(stderr,"MANUFACTURER ID could not be processed\n");
		return -1;
	}
	//The address is 00000h so that's why we use 4 in the xpi_fer
	status = spi_xfer(fd, buffer,4,buffer,2,FULL_DUPLEX);
	if(status < 0) {
		fprintf(stderr,"MANUFACTURER ID could not be processed\n");
		return -1;
	}
	mf_data->manufacturer_id = buffer[0];
	mf_data->device_id = buffer[1];
	return 0;
}


int page_program(int fd, uint32_t addr, uint8_t * data, size_t len) {
	uint8_t buffer[sizeof(addr) + len];
	int status;
	if((ADDR_24_MASK & addr) != 0) {
		fprintf(stderr,"The specified address 0x%X is too big, the maximum address allowed is 0x00FFFFFF\n", addr);
		free(buffer);
		return -1;
	}
	else if(ADDR_24_MASK & (addr + len*8)) {
		fprintf(stderr,"The amount of bytes %d to page exceeds the size of the memory\n",(int) len);
		free(buffer);
		return -1;
	}
	memcpy(buffer + sizeof(addr), data, len);
	buffer[0] = PAGE_PROGRAM;
	buffer[1] = (uint8_t) (addr >> 16);
	buffer[2] = (uint8_t) (addr >> 8);
	buffer[3] = (uint8_t) (addr);
	if(wait_busy(fd) < 0) {
		fprintf(stderr,"PAGE PROGRAM could not be processed, could not obtain device busy flag\n");
		free(buffer);
		return -1;
	}
	if(write_enable(fd) < 0) {
		fprintf(stderr,"PAGE PROGRAM could not write enable\n");
		free(buffer);
		return -1;
	}

	status = spi_xfer(fd, buffer,sizeof(buffer),NULL,0, WRITE);
	if(status < 0) {
		fprintf(stderr,"PAGE PROGRAM could not be processed\n");
		free(buffer);
		return -1;
	}
	if(wait_busy(fd) < 0) {
		fprintf(stderr,"PAGE PROGRAM could not be processed\n");
		free(buffer);
		return -1;
	}
	return 0;
}

int block_64_eraser(int fd, uint32_t addr) {
	uint8_t buffer[4];
	int status;

	if(write_enable(fd) < 0) {
		fprintf(stderr,"BLOCK 64 ERASE could not be processed\n");
		return -1;
	}
	buffer[0] = (uint8_t) BLOCK_64_ERASE;
	buffer[1] = (uint8_t) (addr >> 16);
	buffer[2] = (uint8_t) (addr >> 8);
	buffer[3] = (uint8_t) (addr);

	//Error Handling
	if((ADDR_24_MASK & addr) != 0) {
		fprintf(stderr,"The specified address 0x%X is too big, the maximum address allowed is 0x00FFFFFF\n", addr);
		return -1;
	}
	status = spi_xfer(fd, buffer,4,NULL,0,WRITE);
	if(status < 0) {
		fprintf(stderr,"BLOCK 64 ERASE could not be processed\n");
		return -1;
	}
	if(wait_busy(fd) < 0) {
		fprintf(stderr,"BLOCK 64 ERASE could not be processed\n");
		return -1;
	}
	return 0;
}

int block_32_eraser(int fd, uint32_t addr) {
	uint8_t buffer[4];
	int status;

	if(write_enable(fd) < 0) {
		fprintf(stderr,"BLOCK 32 ERASE could not be processed\n");
		return -1;
	}
	//Error Handling
	if((ADDR_24_MASK & addr) != 0) {
		fprintf(stderr,"The specified address 0x%X is too big, the maximum address allowed is 0x00FFFFFF\n", addr);
		return -1;
	}
	buffer[0] = (uint8_t) BLOCK_32_ERASE;
	buffer[1] = (uint8_t) (addr >> 16);
	buffer[2] = (uint8_t) (addr >> 8);
	buffer[3] = (uint8_t) (addr);
	status = spi_xfer(fd, buffer, 4, NULL, 0, WRITE);
	if(status < 0) {
		fprintf(stderr,"BLOCK 32 ERASE could not be processed\n");
		return -1;
	}
	if(wait_busy(fd) < 0) {
		fprintf(stderr,"BLOC 32 ERASE could not be processed\n");
		return -1;
	}
	return 0;
}

int sector_eraser(int fd, uint32_t addr) {
	uint8_t buffer[4];
	int status;

	//Error Handling
	if(write_enable(fd) < 0) {
		fprintf(stderr,"SECTOR ERASE could not be processed\n");
		return -1;
	}

	if((ADDR_24_MASK & addr) != 0) {
		fprintf(stderr,"The specified address 0x%X is too big, the maximum address allowed is 0x00FFFFFF\n", addr);
		return -1;
	}
	buffer[0] = (uint8_t) SECTOR_ERASE;
	buffer[1] = (uint8_t) (addr >> 16);
	buffer[2] = (uint8_t) (addr >> 8);
	buffer[3] = (uint8_t) (addr);
	status = spi_xfer(fd, buffer, 4, NULL, 0, WRITE);
	if(status < 0) {
		fprintf(stderr,"SECTOR ERASE could not be processed\n");
		return -1;
	}
	if(wait_busy(fd) < 0) {
		fprintf(stderr,"SECTOR ERASE could not be processed\n");
		return -1;
	}
	return 0;
}

int test_memory(int fd) {
	read_jedec_id *rd = malloc(sizeof(*rd));
	int result;
	result = read_jedecID(0,rd);
	if(result < 0) {
		printf("Read_jedec didn't work\n");
		free(rd);
		return -1;
	}
	else {
		if(rd->manufacturer_id != MANUFACTURER_ID) {
			fprintf(stderr,"Manufacturer ID expected = %x, Manufacturer ID received %x\n",MANUFACTURER_ID,rd->manufacturer_id);
			free(rd);
			return -1;
		}
		if(rd->capacity != CAPACITY || rd->memory_type != MEMORY_TYPE) {
			fprintf(stderr,"ID Expected = %x%x, ID Received %x%x\n",MEMORY_TYPE,CAPACITY,rd->memory_type, rd->capacity);
			free(rd);
			return -1;
		}
	}
	printf("Memory Tested OK!\n");
	free(rd);
	return 0;
}

static void print_usage(const char *prog)
{
	printf("Usage: %s [-DsbdlHOLC3] <file to program>\n", prog);
	puts("  -D --device   device to use (default /dev/spidev1.1)\n"
	                "  -c            chip erase instead of individual sectors\n"
	                "  -i            print information about flash and exit\n"
			"  -s --speed    max speed (Hz)\n"
			"  -d --delay    delay (usec)\n"
			"  -b --bpw      bits per word \n"
			"  -l --loop     loopback\n"
			"  -H --cpha     clock phase\n"
			"  -O --cpol     clock polarity\n"
			"  -L --lsb      least significant bit first\n"
			"  -C --cs-high  chip select active high\n"
			"  -3 --3wire    SI/SO signals shared\n");
	exit(1);
}


static
int
prog_flash_from_file(int spi_fd, int erase_sectors, const char *file_in)
{
	struct stat sb;
	uint8_t buf[SECTOR_SIZE];
	char *path;
	int error;
	int fd;
	size_t file_sz;
	ssize_t ssz;
	uint32_t flash_addr = 0;
	uint32_t int_off;

	path = realpath(file_in, NULL);
	if (path == NULL)
		return -1;

	error = stat(path, &sb);
	if (error)
		return error;

	file_sz = (size_t)sb.st_size;

	fd = open(path, O_RDONLY);
	if (fd < 0)
		return -1;

	while (file_sz > 0) {
		memset(buf, 0, SECTOR_SIZE);
		ssz = read(fd, buf, SECTOR_SIZE);
		if (ssz < 0)
			return -1;

		/* XXX: need LSB first <-> MSB first translation for FPGA?? */


		if (erase_sectors) {
			error = sector_eraser(spi_fd, flash_addr);
			if (error)
				return -1;
		}

		int_off = 0;
		do {
			assert(((flash_addr + int_off) & 0x00FFFF00) == (flash_addr + int_off));
			error = page_program(spi_fd, flash_addr + int_off,
			    &buf[int_off], PAGE_SIZE);
			if (error)
				return -1;

			int_off += PAGE_SIZE;
		} while (int_off != SECTOR_SIZE);
		flash_addr += SECTOR_SIZE;
	}

	close(fd);
	return 0;
}


static void parse_opts(int argc, char *argv[])
{
	const char *prog_name = argv[0];

	while (1) {
		static const struct option lopts[] = {
				{ "device",  1, 0, 'D' },
				{ "speed",   1, 0, 's' },
				{ "delay",   1, 0, 'd' },
				{ "bpw",     1, 0, 'b' },
				{ "loop",    0, 0, 'l' },
				{ "cpha",    0, 0, 'H' },
				{ "cpol",    0, 0, 'O' },
				{ "lsb",     0, 0, 'L' },
				{ "cs-high", 0, 0, 'C' },
				{ "3wire",   0, 0, '3' },
				{ "no-cs",   0, 0, 'N' },
				{ "ready",   0, 0, 'R' },
				{ NULL, 0, 0, 0 },
		};
		int c;

		c = getopt_long(argc, argv, "D:ics:d:b:ltHOLC3NR", lopts, NULL);

		if (c == -1)
			break;
		switch (c) {
		case 'D':
		device = optarg;
		break;
		case 'c':
			cflag = 1;
			break;
		case 'i':
			iflag = 1;
			break;
		case 's':
			speed = atoi(optarg);
			break;
		case 'd':
			delay = atoi(optarg);
			break;
		case 'b':
			bits = atoi(optarg);
			break;
		case 'l':
			mode |= SPI_LOOP;
			break;
		case 't':
			tflag = 1;
			break;
		case 'H':
			mode |= SPI_CPHA;
			break;
		case 'O':
			mode |= SPI_CPOL;
			break;
		case 'L':
			mode |= SPI_LSB_FIRST;
			break;
		case 'C':
			mode |= SPI_CS_HIGH;
			break;
		case '3':
			mode |= SPI_3WIRE;
			break;
		case 'N':
			mode |= SPI_NO_CS;
			break;
		case 'R':
			mode |= SPI_READY;
			break;
		default:
			print_usage(prog_name);
			break;
		}
	}

	argc -= optind;
	argv += optind;

	if (argc < 1 && !iflag)
		print_usage(prog_name);

	file = argv[0];
}

int main(int argc, char *argv[]) {
       	read_jedec_id jid;
       	manufacturer_read mid;
	uint64_t uid;

	int ret = 0;
	int fd = -1;

	parse_opts(argc, argv);

	if (!tflag) {
		fd = open(device, O_RDWR);
		if (fd < 0) {
			perror("can't open device");
			exit(1);
		}

		//spi mode

		ret = ioctl(fd, SPI_IOC_WR_MODE, &mode);
		if (ret == -1) {
			perror("can't set spi mode");
			exit(1);
		}
		ret = ioctl(fd, SPI_IOC_RD_MODE, &mode);
		if (ret == -1) {
			perror("can't get spi mode");
			exit(1);
		}

		//bits per word

		ret = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits);
		if (ret == -1) {
			perror("can't set bits per word");
			exit(1);
		}
		ret = ioctl(fd, SPI_IOC_RD_BITS_PER_WORD, &bits);
		if (ret == -1) {
			perror("can't get bits per word");
			exit(1);
		}

#if 0
		//max speed hz

		ret = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
		if (ret == -1) {
			perror("can't set max speed hz");
			exit(1);
		}

		ret = ioctl(fd, SPI_IOC_RD_MAX_SPEED_HZ, &speed);
		if (ret == -1) {
			perror("can't get max speed hz");
			exit(1);
		}
#endif

		printf("spi mode: %d\n", mode);
		printf("bits per word: %d\n", bits);
#if 0
		printf("max speed: %d Hz (%d KHz)\n", speed, speed/1000);
#endif
	} else {
		printf("Running in test mode - "
		       "only interacting with model\n");
		model_init();
	}

	if (iflag) {
		ret = read_manufacturer_id(fd, &mid);
		if (ret)
			exit(1);
		ret = read_jedecID(fd, &jid);
		if (ret)
			exit(1);
		ret = read_unique_id(fd, &uid);
		if (ret)
			exit(1);

		printf("Manufacturer ID:\t%#x\n", mid.manufacturer_id);
		printf("Device ID:\t\t%#x\n", mid.device_id);
		printf("Unique ID:\t\t0x%"PRIx64"\n", uid);
		printf("\nJEDEC Information:\n");
		printf("-------------------\n");
		printf("Manufacturer ID:\t%#x\n", jid.manufacturer_id);
		printf("Memory Type:\t\t%#x\n", jid.memory_type);
		printf("Capacity:\t\t%#x\n", jid.capacity);
		exit(0);
		/* NOT REACHED */
	}

	/*
	 * Run the memory "test" but don't do anything if
	 * it fails. Odds are it's because it has a different
	 * capacity.
	 */
	test_memory(fd);


	if (cflag) {
		/* Erase flash so we can write to it */
		ret = chip_erase(fd);
		if (ret != 0)
			exit(1);
	}

	ret = prog_flash_from_file(fd, !cflag, file);
	if (ret != 0) {
		fprintf(stderr, "Flash programming failed\n");
		exit(1);
	}

	if (!tflag)
		close(fd);

	return ret;
}

