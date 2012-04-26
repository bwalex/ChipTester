/*
 * spi.h
 *
 *  	Created on: 9 Apr 2012
 *      Author: Romel Torres
 *      Email: rt5g11@soton.ac.uk
 */

#ifndef SPI_H_
#define SPI_H_

/*Write data structure*/
typedef struct  {
	uint8_t cmd;
	uint32_t addr;
}write_data_cmd;

/*Read jedec ID structure*/
typedef struct {
	uint8_t manufacturer_id;
	uint8_t memory_type;
	uint8_t capacity;
}read_jedec_id;

/*Manafacturer ID*/
typedef struct {
	uint8_t manufacturer_id;
	uint8_t device_id;
}manufacturer_read;

/*It handles the spi transfer*/
int spi_xfer(int fd, uint8_t* txbuf, size_t txlen, uint8_t* rxbuf, size_t rxlen, uint8_t full_duplex);
/*WRITE_ENABLE 0x06 Instruction, fd = open(device, O_RDWR);*/
int write_enable(int fd);
/*WRITE_DISABLE 0x04 Instruction, fd = open(device, O_RDWR);*/
int write_disable(int fd);
/*WRITE_ENABLE_VOLATILE 0x50, fd = open(device, O_RDWR);*/
int write_enable_sreg(int fd);
/*READ_STATUS_REGISTER_1 0x05 Instruction, *serg1 is a byte pointer to store the data*/
int read_sreg1(int fd, uint8_t *sreg1);
/*READ_STATUS_REGISTER_2 0x35 Instruction,*sreg2 is a byte pointer to store the data*/
int read_sreg2(int fd, uint8_t *sreg2); 
/*It waits until the busy flag is cleared in the flash*/
int wait_busy(int fd);
/*WRITE_STATUS_REGISTER 0x01 Instruction, fd, sreg1 value to the status register 1, sreg2 value to the status register 2*/
int write_sreg(int fd, uint8_t sreg1, uint8_t sreg2);
/*CHIP_ERASE 0xC7 Instruction, fd = open(device, O_RDWR);*/
int chip_erase(int fd);
/*READ_DATA 0x03 it receives the address to read (which cannot be bigger than 24 bits), the size to read and a byte pointer to where the data will be stored*/
int read_data(int fd, uint32_t addr, size_t len, uint8_t *buffer);
/*READ_JEDEC_ID 0x9F, pointer to the structure jedec id to store the data*/
int read_jedecID(int fd, read_jedec_id *jedec_data);
/*READ_UNIQUE_ID 0x4B, pointer to a 64bit number where the device id will be stored*/
int read_unique_id(int fd, uint64_t *unique_id);
/*READ_DEVICE_ID 0x90, pointer to the structure manufacturer_read where the data will be stored*/
int read_manufacturer_id(int fd, manufacturer_read *mf_data);
/*PAGE_PROGRAM 0x02, address which cannot be bigger than 24bits, pointer to the data to write and the length to write.*/
int page_program(int fd, uint32_t addr, uint8_t *data, size_t len);
/*BLOCK_64_ERASE 0xD8 Instruction, address to erase 64KB onwards*/
int block_64_eraser(int fd, uint32_t addr);
/*BLOCK_32_ERASE 0x52 Instruction, address to erase 32KB onwards*/
int block_32_eraser(int fd, uint32_t addr);
/**SECTOR_ERASE 0x20 Instruction, adress to erase a sector/
int sector_eraser(int fd, uint32_t addr);
/*Function to test the memory. It returns -1 if the memory ID wasn't read properly.*/
int test_memory(int fd);


#endif /* SPI_H_ */
