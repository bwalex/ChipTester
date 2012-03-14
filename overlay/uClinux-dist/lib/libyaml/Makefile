VER = yaml-0.1.4

#CONF_OPTS = \
	--disable-shared

include $(ROOTDIR)/tools/autotools.mk

# upstream's install targets lack dependencies on the things
# they install, so just decouple build/install steps
pre-build::
	$(MAKE) -C build-$(VER)

romfs:
	$(ROMFSINST) -d -e CONFIG_FMT_USE_FDPIC_ELF $(STAGEDIR)/usr/lib/libyaml-0.so.2.0.2 /usr/lib/
