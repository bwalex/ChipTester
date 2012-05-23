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
	bash ./bootstrap.sh

submodules-clean:
	bash ./submod.sh clean

overlay: bootstrap
	bash ./patch_overlay.sh -o

patch: submodules-clean bootstrap
	bash ./patch_overlay.sh -po

read-uboot-cfg:
	LD_LIBRARY_PATH=$(LIBRARY_PATH) nios2-flash-programmer -M -b 0x0A000000 -B 0x00040000+0x00010000 -R dist/custom-uboot.cfg

prepare-dist:
	cp u-boot/u-boot.bin dist/u-boot.bin
	cp uClinux-dist/images/vmImage dist/vmImage
	cp uClinux-dist/images/zImage dist/zImage
	cp uClinux-dist/images/rootfs.jffs2 dist/rootfs.jffs2

prime-sof:
	java -jar sof2flash.jar --epcs --input=$(SOF) --output=dist/sys.sof.flash

prime-dist:
	java -jar $(BIN2FLASH_PATH) --input=dist/rootfs.jffs2 --output=dist/rootfs.jffs2.flash --location=0x00200000
	java -jar $(BIN2FLASH_PATH) --input=dist/u-boot.bin --output=dist/u-boot.bin.flash --location=0x00000000
	java -jar $(BIN2FLASH_PATH) --input=dist/vmImage --output=dist/vmImage.flash --location=0x00050000

deploy-dist: prime-dist
	LD_LIBRARY_PATH=$(LIBRARY_PATH) nios2-flash-programmer -M -b $(FLASH_BASE) -P dist/u-boot.bin.flash
	LD_LIBRARY_PATH=$(LIBRARY_PATH) nios2-flash-programmer -M -b $(FLASH_BASE) -P dist/vmImage.flash
	LD_LIBRARY_PATH=$(LIBRARY_PATH) nios2-flash-programmer -M -b $(FLASH_BASE) -P dist/rootfs.jffs2.flash
	LD_LIBRARY_PATH=$(LIBRARY_PATH) nios2-flash-programmer -M -b $(FLASH_BASE) -P -g dist/uboot.cfg


.PHONY: config flashimage download terminal
.PHONY: bootstrap submodules-clean patch overlay
.PHONY: read-uboot-cfg prime-dist deploy-dist prepare-dist
