#!/bin/sh

URL_PATH="/about"
WORK_DIR="/tmp/vconfig"

# GPIO pins used for configuration
PIN_NSTATUS="/sys/class/gpio/gpio245/value"
PIN_CONF_DONE="/sys/class/gpio/gpio244/value"
PIN_NCE="/sys/class/gpio/gpio243/value"
PIN_NCONFIG="/sys/class/gpio/gpio246/value"
SPI_DEV="/dev/spidev32765.0"

TARGET_FILE="${WORK_DIR}/config.data"


mkdir -p $WORK_DIR || exit 1
rm -rf $WORK_DIR/*


if [ ! -f "$1/vconfig.cfg" ]; then
	echo "Nothing to do"
	exit 0
fi

# Source config passed in
#  - should give us $BASE_URL
. "$1/vconfig.cfg"


URI="$BASE_URL$URL_PATH"

echo "Downloading from: $URI"
wget -qO $TARGET_FILE $URI
if [ "$?" != "0" ]; then
	echo "Error (or no file) while trying to download"
	exit 22
fi

unzip -l $TARGET_FILE
if [ "$?" = "0" ]; then
	unzip -o $TARGET_FILE -d $WORK_DIR || exit 1
else
	MODIFIER="INVALID"

	tar tf $TARGET_FILE

	if [ "$?" = "0" ]; then
		MODIFIER=""
	fi

	tar tzf $TARGET_FILE

	if [ "$?" = "0" ]; then
		MODIFIER="z"
	fi

	tar tjf $TARGET_FILE

	if [ "$?" = "0" ]; then
		MODIFIER="j"
	fi

	tar taf $TARGET_FILE

	if [ "$?" = "0" ]; then
		MODIFIER="a"
	fi

	if [ "$MODIFIER" = "INVALID" ]; then
		exit 2
	fi

	tar x${MODIFIER}f $TARGET_FILE -C $WORK_DIR || exit 3
fi

confrd -p $WORK_DIR
if [ "$?" != "0" ]; then
	echo "Configuration doesn't pass sanity check"
	exit 5
fi

# Hold Chip Enable low
echo 0 > $PIN_NCE

# Tie nCONFIG low - FPGA will lose configuration, enter reset
# and tri-state all its I/O pins. Transitioning high triggers
# reconfiguration.
echo 0 > $PIN_NCONFIG

# To be on the safe side, we wait a couple of seconds
sleep 2

FLASH_LOG=`spi_flash -D $SPI_DEV $WORK_DIR/fpga.rbf`
if [ "$?" != "0" ]; then
	echo "Writing to SPI flash failed"
	exit 10
fi

# Configuration has been written; we are good to go. Trigger
# FPGA reconfiguration by transitioning nCONFIG high.
echo 1 > $PIN_NCONFIG

# To be on the safe side, we wait a couple of seconds
sleep 10

# By now the FPGA is either configured, or in an error state
# Check whether it's the latter by looking at the nSTATUS pin
FPGA_OK=`cat $PIN_NSTATUS`
if [ "$FPGA_OK" = "0" ]; then
	echo "FPGA is unhappy."
	exit 12
fi

# We are all set now; the slave FPGA is configured, so we can
# start the proper testing. confrd handles the rest from here.
confrd -vw $WORK_DIR
