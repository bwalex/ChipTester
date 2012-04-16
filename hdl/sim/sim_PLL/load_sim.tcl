# Set hierarchy variables used in the Qsys-generated files
set TOP_LEVEL_NAME "TestInterface"
set HDL_BASE "../.."
set SIM_BASE "$HDL_BASE/sim"

proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib      ./libraries/     
ensure_lib      ./libraries/work/
vmap work       ./libraries/work/

# Compile the additional test files
vlog     $HDL_BASE/PLL.v
vlog     $HDL_BASE/REPLL.v
vlog -sv ./REPLL_CONTROL.sv
vlog -sv $HDL_BASE/PLL_INTERFACE.sv
vlog -sv ./TestInterface.sv
# Elaborate the top-level design
vsim -t ps -L work -L altera_mf_ver -L 220model_ver -L altera_lnsim_ver -L altera_ver -L cycloneive_ver $TOP_LEVEL_NAME

# Load the waveform "do file" macro script
#do ./wave2.do
