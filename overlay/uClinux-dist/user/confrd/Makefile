EXEC = confrd
OBJS = confrd.o sram.o trunner_if.o

CFLAGS += -DPARANOID_TTYS -DTERMCAP -DUSE_TERMIO -DKLUDGELINEMODE -D_GNU_SOURCE
LDFLAGS += -ljansson -lcurl

all: $(EXEC)

#uses non LGPL libraries
$(EXEC): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)

romfs:
	$(ROMFSINST) /bin/$(EXEC)
	$(ROMFSINST) configs /confrd_configs

clean:
	-rm -f $(EXEC) *.elf *.gdb *.o

$(OBJS): 
