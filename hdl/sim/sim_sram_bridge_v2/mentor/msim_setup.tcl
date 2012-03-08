
# (C) 2001-2012 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and 
# other software and tools, and its AMPP partner logic functions, and 
# any output files any of the foregoing (including device programming 
# or simulation files), and any associated documentation or information 
# are expressly subject to the terms and conditions of the Altera 
# Program License Subscription Agreement, Altera MegaCore Function 
# License Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by Altera 
# or its authorized distributors. Please refer to the applicable 
# agreement for further details.

# ----------------------------------------
# Auto-generated simulation script

# ----------------------------------------
# Initialize the variable
if ![info exists SYSTEM_INSTANCE_NAME] { 
  set SYSTEM_INSTANCE_NAME ""
} elseif { ![ string match "" $SYSTEM_INSTANCE_NAME ] } { 
  set SYSTEM_INSTANCE_NAME "/$SYSTEM_INSTANCE_NAME"
} 

if ![info exists TOP_LEVEL_NAME] { 
  set TOP_LEVEL_NAME "sram_bridge_bfm"
} elseif { ![ string match "" $TOP_LEVEL_NAME ] } { 
  set TOP_LEVEL_NAME "$TOP_LEVEL_NAME"
} 

if ![info exists QSYS_SIMDIR] { 
  set QSYS_SIMDIR "./../"
} elseif { ![ string match "" $QSYS_SIMDIR ] } { 
  set QSYS_SIMDIR "$QSYS_SIMDIR"
} 


# ----------------------------------------
# Copy ROM/RAM files to simulation directory

# ----------------------------------------
# Create compilation libraries
proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib      ./libraries/     
ensure_lib      ./libraries/work/
vmap       work ./libraries/work/
if { ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] } {
  ensure_lib                  ./libraries/altera_ver/      
  vmap       altera_ver       ./libraries/altera_ver/      
  ensure_lib                  ./libraries/lpm_ver/         
  vmap       lpm_ver          ./libraries/lpm_ver/         
  ensure_lib                  ./libraries/sgate_ver/       
  vmap       sgate_ver        ./libraries/sgate_ver/       
  ensure_lib                  ./libraries/altera_mf_ver/   
  vmap       altera_mf_ver    ./libraries/altera_mf_ver/   
  ensure_lib                  ./libraries/altera_lnsim_ver/
  vmap       altera_lnsim_ver ./libraries/altera_lnsim_ver/
  ensure_lib                  ./libraries/cycloneive_ver/  
  vmap       cycloneive_ver   ./libraries/cycloneive_ver/  
}
ensure_lib                                                            ./libraries/sram_bridge_bfm_rst_controller/                            
vmap       sram_bridge_bfm_rst_controller                             ./libraries/sram_bridge_bfm_rst_controller/                            
ensure_lib                                                            ./libraries/sram_bridge_bfm_sram_bridge_16_0_avalon_slave_0_translator/
vmap       sram_bridge_bfm_sram_bridge_16_0_avalon_slave_0_translator ./libraries/sram_bridge_bfm_sram_bridge_16_0_avalon_slave_0_translator/
ensure_lib                                                            ./libraries/sram_bridge_bfm_mm_master_bfm_0_m0_translator/             
vmap       sram_bridge_bfm_mm_master_bfm_0_m0_translator              ./libraries/sram_bridge_bfm_mm_master_bfm_0_m0_translator/             
ensure_lib                                                            ./libraries/sram_bridge_bfm_sram_bridge_16_0/                          
vmap       sram_bridge_bfm_sram_bridge_16_0                           ./libraries/sram_bridge_bfm_sram_bridge_16_0/                          
ensure_lib                                                            ./libraries/sram_bridge_bfm_mm_master_bfm_0/                           
vmap       sram_bridge_bfm_mm_master_bfm_0                            ./libraries/sram_bridge_bfm_mm_master_bfm_0/                           

# ----------------------------------------
# Compile device library files
alias dev_com {
  echo "\[exec\] dev_com"
  if { ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] } {
    vlog     "/opt/altera/11.1sp1/quartus/eda/sim_lib/altera_primitives.v" -work altera_ver      
    vlog     "/opt/altera/11.1sp1/quartus/eda/sim_lib/220model.v"          -work lpm_ver         
    vlog     "/opt/altera/11.1sp1/quartus/eda/sim_lib/sgate.v"             -work sgate_ver       
    vlog     "/opt/altera/11.1sp1/quartus/eda/sim_lib/altera_mf.v"         -work altera_mf_ver   
    vlog -sv "/opt/altera/11.1sp1/quartus/eda/sim_lib/altera_lnsim.sv"     -work altera_lnsim_ver
    vlog     "/opt/altera/11.1sp1/quartus/eda/sim_lib/cycloneive_atoms.v"  -work cycloneive_ver  
  }
}

# ----------------------------------------
# Compile the design files in correct order
alias com {
  echo "\[exec\] com"
  vlog     "$QSYS_SIMDIR/submodules/altera_reset_controller.v"          -work work
  vlog -sv "$QSYS_SIMDIR/submodules/altera_avalon_clock_source.sv"      -work work
  vlog -sv "$QSYS_SIMDIR/submodules/altera_avalon_reset_source.sv"      -work work
  vlog     "$QSYS_SIMDIR/submodules/altera_reset_synchronizer.v"        -work work
  vlog -sv "$QSYS_SIMDIR/submodules/altera_merlin_slave_translator.sv"  -work work
  vlog -sv "$QSYS_SIMDIR/submodules/altera_merlin_master_translator.sv" -work work
  vlog     "$QSYS_SIMDIR/submodules/sram_bridge.v"                      -work work
  vlog -sv "$QSYS_SIMDIR/submodules/verbosity_pkg.sv"                   -work work
  vlog -sv "$QSYS_SIMDIR/submodules/avalon_mm_pkg.sv"                   -work work
  vlog -sv "$QSYS_SIMDIR/submodules/altera_avalon_mm_master_bfm.sv"     -work work
  vlog     "$QSYS_SIMDIR/sram_bridge_bfm.v"                                                                                             
}

# ----------------------------------------
# Elaborate top level design
alias elab {
  echo "\[exec\] elab"
  vsim -t ps -L work -L sram_tb_bfm_reset_source_0 -L sram_tb_bfm_clock_source_0 -L sram_bridge_bfm_sram_bridge_16_0_avalon_slave_0_translator -L sram_bridge_bfm_mm_master_bfm_0_m0_translator -L sram_bridge_bfm_sram_bridge_16_0 -L sram_bridge_bfm_mm_master_bfm_0 -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver $TOP_LEVEL_NAME
}

# ----------------------------------------
# Elaborate the top level design with novopt option
alias elab_debug {
  echo "\[exec\] elab_debug"
  vsim -novopt -t ps -L work -L sram_tb_bfm_reset_source_0 -L sram_tb_bfm_clock_source_0 -L sram_bridge_bfm_sram_bridge_16_0_avalon_slave_0_translator -L sram_bridge_bfm_mm_master_bfm_0_m0_translator -L sram_bridge_bfm_sram_bridge_16_0 -L sram_bridge_bfm_mm_master_bfm_0 -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver $TOP_LEVEL_NAME
}

# ----------------------------------------
# Compile all the design files and elaborate the top level design
alias ld "
  dev_com
  com
  elab
"

# ----------------------------------------
# Compile all the design files and elaborate the top level design with -novopt
alias ld_debug "
  dev_com
  com
  elab_debug
"

# ----------------------------------------
# Print out user commmand line aliases
alias h {
  echo "List Of Command Line Aliases"
  echo
  echo "dev_com                       -- Compile device library files"
  echo
  echo "com                           -- Compile the design files in correct order"
  echo
  echo "elab                          -- Elaborate top level design"
  echo
  echo "elab_debug                    -- Elaborate the top level design with novopt option"
  echo
  echo "ld                            -- Compile all the design files and elaborate the top level design"
  echo
  echo "ld_debug                      -- Compile all the design files and elaborate the top level design with -novopt"
  echo
  echo 
  echo
  echo "List Of Variables"
  echo
  echo "TOP_LEVEL_NAME                -- Top level module name."
  echo
  echo "SYSTEM_INSTANCE_NAME          -- Instantiated system module name inside top level module."
  echo
  echo "QSYS_SIMDIR                   -- Qsys base simulation directory."
}
h
