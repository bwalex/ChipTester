# Set hierarchy variables used in the Qsys-generated files
set TOP_LEVEL_NAME "top"
set HDL_BASE "../.."
set SIM_BASE "$HDL_BASE/sim"

proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib      ./libraries/     
ensure_lib      ./libraries/work/
vmap work       ./libraries/work/

# Compile the additional test files
vlog -sv $SIM_BASE/async_sram.v
vlog     $HDL_BASE/sram_arb_sync.v
vlog     $HDL_BASE/mem_if.v
vlog     $HDL_BASE/stim.v
vlog     $HDL_BASE/check.v
vlog     $HDL_BASE/cfifo.v
vlog     $HDL_BASE/rfifo.v
vlog     $HDL_BASE/stfifo.v
vlog     ./loopback.v
vlog -sv ./top.sv
# Elaborate the top-level design
vsim -t ps -L work -L altera_mf_ver $TOP_LEVEL_NAME

# Load the waveform "do file" macro script
do ./wave2.do

#cd Z:/altera-tmp/soc-project/ChipTester/hdl/sim2
