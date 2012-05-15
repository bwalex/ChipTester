/* ah3e11 */

#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>

#include "spi_flash_model.h"

/*
Modeled instructions:

- Read JEDEC ID (0x9F)
- Read Unique ID Number (0x4B)
- Read Manufacturer / Device ID (0x90)
- Chip Erase (0xC7/ 0x60)
- Sector Erase (0x20)
- Page Program (0x02)
- Read Data (0x03)
- Write Enable (0x06)
- Write Disable (0x04)
- Write Enable for Volatile Status Register (0x50)
- Read Status Register 1 (0x05)
- Read Status Register 2 (0x35)
*/




#define READ_JEDEC_ID	0x9F
#define READ_UID	0x4B
#define READ_MDID	0x90
#define CHIP_ERASE	0xC7
#define CHIP_ERASE_2	0x60
#define SECTOR_ERASE	0x20
#define PAGE_PROGRAM	0x02
#define READ_DATA	0x03
#define WRITE_ENABLE	0x06
#define WRITE_ENABLE_VSR	0x50
#define WRITE_DISABLE	0x04
#define READ_SR_1	0x05
#define READ_SR_2	0x35

static struct {
	int BUSY;
	int WEL;
	int BP0;
	int BP1;
	int BP2;
	int TB;
	int SEC;
	int CMP;
	int SRP0;
	int SRP1;
	int SUS;
	int LB1;
	int LB2;
	int LB3;
	int QE;

	int WEVSR; /* Write Enable Volatile SR */
} status;

struct sector {
	int clear;
	int protected;
	uint8_t b[4096];
};

struct sector sectors[128*16];



#define CHECK_RXBUF()								\
	do { 									\
		if (rxbuf == NULL) {						\
			fprintf(stderr, "FLASH: rxbuf expected, but rxbuf "	\
			"== NULL\n");						\
			return -1;						\
		}								\
	} while(0)


#define CHECK_BUSY()								\
	do { 									\
		if (status.BUSY) {						\
			fprintf(stderr, "FLASH: Device is busy, ignoring "	\
				"request\n");					\
			return -1;						\
		}								\
	} while(0)


#define CHECK_TXLEN(n)								\
	do { 									\
		if (txlen != n) {						\
			fprintf(stderr, "FLASH: txbuf length mismatch "		\
				"expected %d, got %zu\n", n, txlen);		\
			return -1;						\
		}								\
	} while(0)

#define CHECK_TXLEN_MIN(n) 							\
	do { 									\
		if (txlen < n) {						\
			fprintf(stderr, "FLASH: txbuf length too short "	\
				"expected min %d, got %zu\n", n, txlen);	\
			return -1;						\
		}								\
	} while(0)

#define CHECK_TXLEN_MAX(n) 							\
	do { 									\
		if (txlen > n) {						\
			fprintf(stderr, "FLASH: txbuf length too long "		\
				"expected max %d, got %zu\n", n, txlen);	\
			return -1;						\
		}								\
	} while(0)

#define CHECK_TXADDR(a)								\
	do { 									\
		uint32_t __addr = 0;						\
		__addr |= (txbuf[1] << 16) | (txbuf[2] << 8) | txbuf[3];		\
		__addr &= 0x00FFFFFF;						\
		if (__addr != (a & 0x00FFFFFF)) {				\
			fprintf(stderr, "FLASH: expected address %x, but "	\
				"got %x ", a, __addr);				\
		}								\
	} while(0)


static
uint32_t get_addr(uint8_t *txbuf) {
	uint32_t addr = 0;

	addr |= (txbuf[1] << 16) | (txbuf[2] << 8) | txbuf[3];
	addr &= 0x00FFFFFF;

	return addr;
}


static
void
mem_clear(void) {
	int i;

	for (i = 0; i < 128*16; i++) {
		sectors[i].clear = 1;
		sectors[i].protected = 0;
		memset(sectors[i].b, 0xFF, sizeof(sectors[i].b));
	}
}


static
void
set_busy_timer(uint8_t cmd)
{
	struct itimerval it;
	int error;

	memset(&it, 0, sizeof(it));

	switch(cmd) {
	case PAGE_PROGRAM:
		it.it_value.tv_usec =   3000; /* 3 ms */
		break;
	case SECTOR_ERASE:
		it.it_value.tv_usec = 400000; /* 400 ms */
		break;
	case CHIP_ERASE:
		it.it_value.tv_sec  =     30; /* 30 s */
		break;
	default:
		fprintf(stderr, "set_busy_timer: unknown cmd: %#x\n",
			(unsigned int)cmd);
		return;
	}

	error = setitimer(ITIMER_REAL, &it, NULL);
	if (error) {
		perror("setitimer");
		status.BUSY = 0;
		return;
	}
}


static void
sigalrm_handler(int sig)
{
	status.BUSY = 0;
	printf("FLASH: Operation done, BUSY=0\n");
}

void
model_init(void)
{
	struct sigaction act;
	int error;

	act.sa_handler = sigalrm_handler;
	sigemptyset(&act.sa_mask);
	act.sa_flags = 0;

	error = sigaction(SIGALRM, &act, NULL);
	if (error) {
		perror("sigaction");
		exit(1);
	}

	mem_clear();
}





int
model_spi_xfer(uint8_t *txbuf, size_t txlen, uint8_t *rxbuf, size_t rxlen)
{
	uint32_t addr, off, sec;

	if (txbuf == NULL) {
		fprintf(stderr, "FLASH: txbuf == NULL!\n");
		return -1;
	}

	CHECK_TXLEN_MIN(1);

	switch (*txbuf) {
	case READ_JEDEC_ID:
		CHECK_TXLEN(1);
		CHECK_RXBUF();
		CHECK_BUSY();
		rxbuf[0] = 0xEF;
		rxbuf[1] = 0x40;
		rxbuf[2] = 0x17;
		break;


	case READ_UID:
		CHECK_TXLEN(5);
		CHECK_RXBUF();
		CHECK_BUSY();
		rxbuf[0] = 0xAA;
		rxbuf[1] = 0xBB;
		rxbuf[2] = 0xCC;
		rxbuf[3] = 0xDD;
		break;


	case READ_MDID:
		CHECK_TXLEN(4);
		CHECK_RXBUF();
		CHECK_TXADDR(0);
		CHECK_BUSY();
		rxbuf[0] = 0xEF;
		rxbuf[1] = 0x16;
		break;


	case READ_SR_1:
		CHECK_TXLEN(1);
		CHECK_RXBUF();
		while (rxlen-- > 0) {
			*rxbuf++ =
				((status.SRP0 & 0x01) << 7) |
				((status.SEC  & 0x01) << 6) |
				((status.TB   & 0x01) << 5) |
				((status.BP2  & 0x01) << 4) |
				((status.BP1  & 0x01) << 3) |
				((status.BP0  & 0x01) << 2) |
				((status.WEL  & 0x01) << 1) |
				((status.BUSY & 0x01) << 0) ;
		}
		break;


	case READ_SR_2:
		CHECK_TXLEN(1);
		CHECK_RXBUF();
		while (rxlen-- > 0) {
			*rxbuf++ =
				((status.SUS  & 0x01) << 7) |
				((status.CMP  & 0x01) << 6) |
				((status.LB3  & 0x01) << 5) |
				((status.LB2  & 0x01) << 4) |
				((status.LB1  & 0x01) << 3) |
				((0           & 0x01) << 2) |
				((status.QE   & 0x01) << 1) |
				((status.SRP1 & 0x01) << 0) ;
		}
		break;


	case CHIP_ERASE:
	case CHIP_ERASE_2:
		CHECK_TXLEN(1);
		CHECK_BUSY();
		if (!status.WEL) {
			fprintf(stderr, "FLASH: Chip Erase failed!\n");
			fprintf(stderr, "FLASH: Write Enable must occur before Chip "
				"Erase\n");
			return -1;
		} else {
			printf("FLASH: Chip Erase successful\n");
			mem_clear();
			status.BUSY = 1;
			set_busy_timer(CHIP_ERASE);
		}
		break;


	case WRITE_ENABLE:
		CHECK_TXLEN(1);
		CHECK_BUSY();
		printf("FLASH: Write Enable successful\n");
		status.WEL = 1;
		break;


	case WRITE_ENABLE_VSR:
		CHECK_TXLEN(1);
		CHECK_BUSY();
		printf("FLASH: Write Enable for Volatile Status Register successful\n");
		status.WEVSR = 1;
		break;


	case WRITE_DISABLE:
		CHECK_TXLEN(1);
		CHECK_BUSY();
		printf("FLASH: Write Disable successful\n");
		status.WEL = 0;
		break;


	case SECTOR_ERASE:
		CHECK_TXLEN(4);
		CHECK_BUSY();
		sec = get_addr(txbuf)/4096; /* XXX: is this really a *sector* address, or an address */
		if (!status.WEL) {
			fprintf(stderr, "FLASH: Sector Erase (sector = %#x) failed!\n",
				sec);
			fprintf(stderr, "FLASH: Write Enable must occur before Sector "
				"Erase\n");
			return -1;
		} else if (sec >= 128*16) {
			fprintf(stderr, "FLASH: Sector Erase (sector = %#x) failed!\n",
				sec);
			fprintf(stderr, "FLASH: Sector %#x does not exist!", sec);
			return -1;
		} else if (sectors[sec].protected) {
			fprintf(stderr, "FLASH: Sector Erase (sector = %#x) failed!\n",
				sec);
			fprintf(stderr, "FLASH: Sector %#x is protected!", sec);
			return -1;
		} else {
			printf("FLASH: Sector Erase (sector = %#x) successful!\n",
				sec);
			sectors[sec].clear = 1;
			memset(sectors[sec].b, 0xFF, sizeof(sectors[sec].b));
			status.BUSY=1;
			set_busy_timer(SECTOR_ERASE);
		}
		break;


	case PAGE_PROGRAM:
		CHECK_TXLEN_MIN(5);
		CHECK_TXLEN_MAX(260);
		CHECK_BUSY();
		addr = get_addr(txbuf);
		txlen -= 4;
		txbuf += 4;
		if (!status.WEL) {
			fprintf(stderr, "FLASH: Page Program (addr = %#x) failed!\n",
				addr);
			fprintf(stderr, "FLASH: Write Enable must occur before Page "
				"Program\n");
			return -1;
		} else if (addr >= 128*16*4096) {
			fprintf(stderr, "FLASH: Page Program (addr = %#x) failed!\n",
				addr);
			fprintf(stderr, "FLASH: Address %#x does not exist!", addr);
			return -1;
		} else {
			if (addr%256+txlen > 256) {
				fprintf(stderr, "FLASH: Page Program (addr = %#x) failed!\n",
					addr);
				fprintf(stderr, "FLASH: Page Program cannot cross page "
					"boundaries\n");
				return -1;
			} else {
				sec = addr/4096;
				sectors[sec].clear = 0;
				while (txlen-- > 0) {
					off = addr++%4096;
					if (sectors[sec].b[off] != 0xFF) {
						fprintf(stderr, "FLASH: Page Program "
							"failed, addr %#x was "
							"not previously erased\n",
							addr-1);
						return -1;
					}
					sectors[sec].b[off] = *txbuf++;
				}
				printf("FLASH: Page program (addr = %#x) successful!\n",
				addr);
				status.BUSY = 1;
				set_busy_timer(PAGE_PROGRAM);
			}
		}
		break;


	case READ_DATA:
		CHECK_TXLEN(4);
		CHECK_RXBUF();
		CHECK_BUSY();
		addr = get_addr(txbuf);
		if (addr+rxlen >= 128*16*4096) {
			fprintf(stderr, "FLASH: Read Data (addr = %#x) failed!\n",
				addr);
			fprintf(stderr, "FLASH: Address %#x out of bounds!", addr);
			return -1;
		} else {
			while (rxlen-- > 0) {
				sec = addr/4096;
				off = addr%4096;
				*rxbuf++ = sectors[sec].b[off];
				++addr;
			}
		}
		break;

	default:
		printf("FLASH: unknown command: %#x\n", (unsigned int)*txbuf);
	}

	return 0;
}

