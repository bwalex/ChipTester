VER = jansson-2.3

CONF_OPTS = \
	--disable-shared

include $(ROOTDIR)/tools/autotools.mk

# upstream's install targets lack dependencies on the things
# they install, so just decouple build/install steps
pre-build::
	$(MAKE) -C build-$(VER)

romfs:
	echo "Nothing required"
