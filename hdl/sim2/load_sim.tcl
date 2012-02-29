# Set hierarchy variables used in the Qsys-generated files
set TOP_LEVEL_NAME "top"

proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib      ./libraries/     
ensure_lib      ./libraries/work/
vmap work       ./libraries/work/

# Compile the additional test files
vlog -sv ./async_sram.v
vlog     ./sram_arb_sync.v
vlog     ./mem_if.v
vlog     ./stim.v
vlog     ./check.v
vlog     ./cfifo.v
vlog     ./rfifo.v
vlog     ./stfifo.v
vlog     ./loopback.v
vlog -sv ./top.sv
# Elaborate the top-level design
vsim -t ps -L work -L altera_mf_ver $TOP_LEVEL_NAME

# Load the waveform "do file" macro script
do ./wave2.do

#cd Z:/altera-tmp/soc-project/ChipTester/hdl/sim2
