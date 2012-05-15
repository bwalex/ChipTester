EXEC = rlog
OBJS = rlog.o http_json.o

CFLAGS += -DPARANOID_TTYS -DTERMCAP -DUSE_TERMIO -DKLUDGELINEMODE -D_GNU_SOURCE
LDFLAGS += -ljansson -lcurl

all: $(EXEC)

#uses non LGPL libraries
$(EXEC): $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS) $(LDLIBS)

romfs:
	$(ROMFSINST) /sbin/$(EXEC)

clean:
	-rm -f $(EXEC) *.elf *.gdb *.o

$(OBJS): 
