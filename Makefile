LIBRARY_PATH=$(ALTERA_BASE)/quartus/linux
BIN2FLASH_PATH=$(ALTERA_BASE)/nios2eds/bin/bin2flash.jar

SOF?=hdl/de2115sys_time_limited.sof
FLASH_BASE?=0x0A000000
IMAGE?=dist/zImage
LOC?=0x0


all:
	@echo  "Targets & options: "
	@echo  "  config [SOF=<.sof file>]"
	@echo  "     configure FPGA with <.sof file>"
	@echo  "     defaults: SOF="$(SOF)
	@echo  ""
	@echo  ""
	@echo  "  flashimage [FLASH_BASE=<flash base addr> IMAGE=<bin image> LOC=<flash offset>]"
	@echo  "     write <bin image> to offset <flash offset> of the flash at <flash base addr>"
	@echo  "     defaults: FLASH_BASE="$(FLASH_BASE)
	@echo  "               IMAGE="$(IMAGE)
	@echo  "               LOC="$(LOC)
	@echo  ""
	@echo  ""
	@echo  "  download [IMAGE=<executable or binary>]"
	@echo  "     download <executable or binary> to SDRAM of the Nios2 and start its execution"
	@echo  "     defaults: IMAGE="$(IMAGE)
	@echo  ""
	@echo  ""
	@echo  "  terminal"
	@echo  "     start a nios2-terminal (JTAG UART)"


config:
	nios2-configure-sof $(SOF)

flashimage:
	java -jar $(BIN2FLASH_PATH) --location=$(LOC) --input=$(IMAGE) --output=$(IMAGE).flash
	LD_LIBRARY_PATH=$(LIBRARY_PATH) nios2-flash-programmer --mmu -b $(FLASH_BASE) $(IMAGE).flash

download:
	LD_LIBRARY_PATH=$(LIBRARY_PATH) nios2-download -g $(IMAGE)

terminal:
	LD_LIBRARY_PATH=$(LIBRARY_PATH) nios2-terminal

bootstrap:
	sh ./bootstrap.sh

submodules-clean:
	sh ./submod.sh clean

overlay: bootstrap
	sh ./patch_overlay.sh -o

patch: submodules-clean bootstrap
	sh ./patch_overlay.sh -po

.PHONY: config flashimage download terminal
.PHONY: bootstrap submodules-clean patch overlay
