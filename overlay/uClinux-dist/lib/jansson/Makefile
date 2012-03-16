VER = jansson-2.3

#CONF_OPTS = \
	--disable-shared

include $(ROOTDIR)/tools/autotools.mk

# upstream's install targets lack dependencies on the things
# they install, so just decouple build/install steps
pre-build::
	$(MAKE) -C build-$(VER)

romfs:
	$(ROMFSINST) -d -e CONFIG_FMT_USE_FDPIC_ELF $(STAGEDIR)/usr/lib/libjansson.so.4.3.0 /usr/lib/
	$(ROMFSINST) -d -e CONFIG_FMT_USE_FDPIC_ELF -l /usr/lib/libjansson.so.4.3.0 /usr/lib/libjansson.so.4
