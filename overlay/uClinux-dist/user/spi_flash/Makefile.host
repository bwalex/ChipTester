WARNFLAGS= -Wsystem-headers -Wall -W -Wno-unused-parameter \
	-Wstrict-prototypes -Wmissing-prototypes -Wpointer-arith \
	-Wold-style-definition -Wreturn-type -Wwrite-strings \
	-Wswitch -Wshadow -Wcast-align -Wchar-subscripts \
	-Winline -Wnested-externs

CFLAGS= -g3 -O0 $(WARNFLAGS)
CC?= gcc

all:
	$(CC) $(CFLAGS) spi_flash_model.c spi.c -o spi_flash

clean:
	rm -f spi_flash *.o

