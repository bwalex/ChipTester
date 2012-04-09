# Set hierarchy variables used in the Qsys-generated files
set TOP_LEVEL_NAME "top"
set SYSTEM_INSTANCE_NAME "tb"
set QSYS_SIMDIR "."  

# Source Qsys-generated script and set up alias commands used below
source $QSYS_SIMDIR/mentor/msim_setup.tcl 

# Compile device library files
dev_com
# Compile design files in correct order
com               
# Compile the additional test files
vlog -sv ../async_sram.v
vlog -sv ../../sram_arb_sync.v
vlog -sv ./top.sv
# Elaborate the top-level design
elab

# Load the waveform "do file" macro script
do ./wave.do
