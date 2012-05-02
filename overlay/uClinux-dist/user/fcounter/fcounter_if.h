void fcounter_print_magic(void);
int fcounter_enable(void);
int fcounter_wait_done(void);

int fcounter_set_cycles(uint32_t);
int fcounter_select(int);

int fcounter_get_count(uint32_t *);
int fcounter_read_count(uint32_t *);
