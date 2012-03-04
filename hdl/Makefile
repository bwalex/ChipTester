all:
	@echo  "Targets & options: "
	@echo  "  qsysgen"
	@echo  "     Regenerate the QSYS HDL files. This step needs to be run "
	@echo  "     at least once before compiling"
	@echo  ""
	@echo  ""
	@echo  "  compile"
	@echo  "     Recompile project. This includes Synthesis, P&R, assembling "
	@echo  "     the programming file, and running STA."


qsysgen:
	ip-generate --project-directory=./ \
		--output-directory=./linuxsys/ \
		--report-file=bsf:./linuxsys.bsf \
		--system-info=DEVICE_FAMILY="Cyclone IV E" \
		--system-info=DEVICE=auto \
		--component-file=./linuxsys.qsys

	ip-generate --project-directory=./ \
		--output-directory=./linuxsys/synthesis/ \
		--file-set=QUARTUS_SYNTH \
		--report-file=sopcinfo:./linuxsys.sopcinfo \
		--report-file=html:./linuxsys.html \
		--report-file=qip:./linuxsys/synthesis/linuxsys.qip \
		--system-info=DEVICE_FAMILY="Cyclone IV E" \
		--system-info=DEVICE=auto \
		--component-file=./linuxsys.qsys


compile:
	quartus_sh --flow compile de2115sys


clean:
	rm -f *.bak *~
	rm -rf linuxsys/
	rm -f *.rpt
