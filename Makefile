LIBRARY_PATH=$(ALTERA_BASE)/quartus/linux

all:
	echo "Targets: config, download, terminal"

config:
	nios2-configure-sof hdl/de2115sys_time_limited.sof

download:
	LD_LIBRARY_PATH=$(LIBRARY_PATH) nios2-download -g dist/zImage

terminal:
	LD_LIBRARY_PATH=$(LIBRARY_PATH) nios2-terminal
