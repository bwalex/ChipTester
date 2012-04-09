#define SRAM_BASE	0x0c000000
#define SRAM_SIZE	0x00200000

int sram_open(void);
int sram_read(off_t offset, void *dst, size_t len);
int sram_write(off_t offset, void *src, size_t len);
void sram_close(void);
