all:
	echo "Targets: sim"

sim:
	qhsim -do "source load_sim.tcl"

clean:
	rm -f vsim.wlf transcript
	rm -rf libraries

realclean: clean
	rm -f *~ *.bak
	rm -f modelsim.ini
