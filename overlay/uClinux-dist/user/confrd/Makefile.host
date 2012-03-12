WARNFLAGS= -Wsystem-headers -Wall -W -Wno-unused-parameter \
	-Wstrict-prototypes -Wmissing-prototypes -Wpointer-arith \
	-Wold-style-definition -Wreturn-type -Wwrite-strings \
	-Wswitch -Wshadow -Wcast-align -Wchar-subscripts \
	-Winline -Wnested-externs

CFLAGS= -g3 -O0 $(WARNFLAGS)
CC?= gcc

all:
	$(CC) $(CFLAGS) confrd.c trunner_if.c sram.c -o confrd

clean:
	rm -f confrd

realclean: clean
	rm -f *~ *.bak
