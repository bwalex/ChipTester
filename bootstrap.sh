#!/bin/sh

cwd=$(pwd)

awk '{ sub(/CONFIG_DTB_SOURCE=.*/,"CONFIG_DTB_SOURCE=\"'$cwd'/hdl/linuxsys.dts\"");  print }' overlay/uClinux-dist/linux-2.6.x/.config > .tmp.config
mv .tmp.config overlay/uClinux-dist/linux-2.6.x/.config

