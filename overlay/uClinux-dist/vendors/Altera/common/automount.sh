#!/bin/sh

MOUNT_BASE=/media

case "$ACTION" in
	add|"")
		mkdir -p "${MOUNT_BASE}/${MDEV}" || exit 1
		/sbin/mount -t auto $MDEV "${MOUNT_BASE}/${MDEV}" || exit 1
		if [ -f "${MOUNT_BASE}/${MDEV}/chiptester" ]; then
			# This is an sdcard for the ChipTester, so run confrd
			/bin/confrd -w "${MOUNT_BASE}/${MDEV}"
		fi
		;;

	remove)
		killall -9 confrd 2> /dev/null
		/sbin/umount2 "${MOUNT_BASE}/${MDEV}"
		;;
esac
