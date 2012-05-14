#
#	Makefile -- Build instructions for Altera/nios2
#

.EXPORT_ALL_VARIABLES:
include $(LINUX_CONFIG)
include $(CONFIG_CONFIG)

ROMFS_DIRS-y = bin etc etc/dhcpc home lib mnt proc sys usr var root home tmp etc/config var/run var/lib/misc media
ETC_FILES-y = \
	filesystems group issue mdev.conf mime.types modprobe.conf motd \
	passwd profile rc TZ nsswitch.conf crontabs
WEB_FILES-y =

ETC_FILES-$(CONFIG_NET) += hosts host.conf protocols services
ETC_FILES-$(CONFIG_USER_INETD_INETD) += inetd.conf
ETC_FILES-$(CONFIG_USER_BUSYBOX_INETD) += inetd.conf

ROMFS_DIRS-$(CONFIG_USER_BUSYBOX_FTPD) += home/ftpd
ROMFS_DIRS-$(CONFIG_USER_BUSYBOX_TFTPD) += home/tftpboot
ROMFS_DIRS-$(CONFIG_USER_BUSYBOX_HTTPD) += home/httpd home/httpd/cgi-bin
WEB_FILES-$(CONFIG_USER_BUSYBOX_HTTPD) += index.html favicon.ico
ROMFS_DIRS-$(CONFIG_USER_BOA_SRC_BOA) += home/httpd home/httpd/cgi-bin etc/boa var/log/boa
ETC_FILES-$(CONFIG_USER_BOA_SRC_BOA) += boa.conf
WEB_FILES-$(CONFIG_USER_BOA_SRC_BOA) += boa.conf index.html favicon.ico

MKFS_JFFS2_FLAGS = -l -p -e 128

all::

romfs.post:: romfs.shared.libs

romfs::
	mkdir -p $(ROMFSDIR)
	cd $(ROMFSDIR) && mkdir -p $(ROMFS_DIRS-y)
	chmod 1777 $(ROMFSDIR)/tmp
	$(ROMFSINST) -s bin /sbin

	$(ROMFSINST) /etc/inittab

	$(ROMFSINST) -s /proc/mounts /etc/mtab

	$(ROMFSINST) -p 0755 ../common/automount.sh /etc/automount.sh

	set -e ; \
	for f in $(ETC_FILES-y) ; do \
		$(ROMFSINST) ../common/$$f /etc/$$f ; \
	done ; \
	for f in $(WEB_FILES-y) ; do \
		$(ROMFSINST) ../common/$$f /home/httpd/$$f ; \
	done

	$(ROMFSINST) -e CONFIG_USER_BUSYBOX_FTPD \
		-a "21 stream tcp nowait root ftpd ftpd -w /home/ftpd" /etc/inetd.conf
	$(ROMFSINST) -e CONFIG_USER_BUSYBOX_TELNETD \
		-a "23 stream tcp nowait root telnetd telnetd -i" /etc/inetd.conf
	$(ROMFSINST) -e CONFIG_USER_BUSYBOX_TFTPD \
		-a "69 dgram  udp nowait root tftpd tftpd -c /home/tftpboot" /etc/inetd.conf
	$(ROMFSINST) -e CONFIG_USER_BUSYBOX_HTTPD \
		-a "80 stream tcp nowait root httpd httpd -i -h /home/httpd" /etc/inetd.conf

	echo "$(VERSIONSTR) -- `date`" > $(ROMFSDIR)/etc/version
ifeq ($(CONFIG_BLACKFIN_INSTALL_UCLINUX_CONFIG),y)
	gzip -9c $(ROOTDIR)/config/.config > $(ROMFSDIR)/root/uclinux-config.gz
	gzip -9c $(ROOTDIR)/.config > $(ROMFSDIR)/root/vendor-board-config.gz
endif

ifeq ($(CONFIG_USER_DEV_DYNAMIC),y)
DEVICE_TABLE = device_table-min.txt
else
ifeq ($(CONFIG_USER_BUSYBOX_MDEV),y)
$(warning )
$(warning You have busybox's mdev enabled.  The static device tree will be)
$(warning overridden during boot by a tmpfs in /dev.)
$(warning )
endif
DEVICE_TABLE = device_table.txt
endif

# these targets can be found in Altera/vendor.mak
image::
	mkdir -p $(IMAGEDIR)
	rm -rf $(IMAGEDIR)/*

	$(MAKE) image.rootfs.all
	$(MAKE) image.kernel.all
	$(MAKE) image.uimage.all
	$(MAKE) image.zimage.all

clean::

.PHONY: all clean image romfs

include ../../$(CONFIG_VENDOR)/vendor.mak
