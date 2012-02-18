# TCL File Generated by Component Editor 11.1sp1
# Sat Feb 18 15:52:10 GMT 2012
# DO NOT MODIFY


# +-----------------------------------
# | 
# | sram_bridge_16 "SRAM Bridge (16 bit wide)" v1.0
# | alexh 2012.02.18.15:52:10
# | 
# | 
# | /home/alex/socp-test/next/hwtest/hdl/ip/sram_bridge/sram_bridge.v
# | 
# |    ./sram_bridge.v syn, sim
# | 
# +-----------------------------------

# +-----------------------------------
# | request TCL package from ACDS 11.0
# | 
package require -exact sopc 11.0
# | 
# +-----------------------------------

# +-----------------------------------
# | module sram_bridge_16
# | 
set_module_property NAME sram_bridge_16
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR alexh
set_module_property DISPLAY_NAME "SRAM Bridge (16 bit wide)"
set_module_property TOP_LEVEL_HDL_FILE sram_bridge.v
set_module_property TOP_LEVEL_HDL_MODULE sram_bridge
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL TRUE
set_module_property STATIC_TOP_LEVEL_MODULE_NAME sram_bridge
set_module_property FIX_110_VIP_PATH false
# | 
# +-----------------------------------

# +-----------------------------------
# | files
# | 
add_file sram_bridge.v {SYNTHESIS SIMULATION}
# | 
# +-----------------------------------

# +-----------------------------------
# | parameters
# | 
add_parameter ADDR_WIDTH INTEGER 20
set_parameter_property ADDR_WIDTH DEFAULT_VALUE 20
set_parameter_property ADDR_WIDTH DISPLAY_NAME ADDR_WIDTH
set_parameter_property ADDR_WIDTH TYPE INTEGER
set_parameter_property ADDR_WIDTH UNITS None
set_parameter_property ADDR_WIDTH AFFECTS_GENERATION false
set_parameter_property ADDR_WIDTH HDL_PARAMETER true
# | 
# +-----------------------------------

# +-----------------------------------
# | display items
# | 
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point avalon_slave_0
# | 
add_interface avalon_slave_0 avalon end
set_interface_property avalon_slave_0 addressUnits WORDS
set_interface_property avalon_slave_0 associatedClock clock_sink
set_interface_property avalon_slave_0 associatedReset reset_sink
set_interface_property avalon_slave_0 bitsPerSymbol 8
set_interface_property avalon_slave_0 burstOnBurstBoundariesOnly false
set_interface_property avalon_slave_0 burstcountUnits WORDS
set_interface_property avalon_slave_0 explicitAddressSpan 0
set_interface_property avalon_slave_0 holdTime 0
set_interface_property avalon_slave_0 linewrapBursts false
set_interface_property avalon_slave_0 maximumPendingReadTransactions 0
set_interface_property avalon_slave_0 readLatency 0
set_interface_property avalon_slave_0 readWaitTime 1
set_interface_property avalon_slave_0 setupTime 0
set_interface_property avalon_slave_0 timingUnits Cycles
set_interface_property avalon_slave_0 writeWaitTime 0

set_interface_property avalon_slave_0 ENABLED true

add_interface_port avalon_slave_0 byteenable byteenable Input 2
add_interface_port avalon_slave_0 read read Input 1
add_interface_port avalon_slave_0 readdata readdata Output 16
add_interface_port avalon_slave_0 write write Input 1
add_interface_port avalon_slave_0 writedata writedata Input 16
add_interface_port avalon_slave_0 waitrequest waitrequest Output 1
add_interface_port avalon_slave_0 address address Input ADDR_WIDTH
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point clock_sink
# | 
add_interface clock_sink clock end
set_interface_property clock_sink clockRate 0

set_interface_property clock_sink ENABLED true

add_interface_port clock_sink clock clk Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point reset_sink
# | 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock_sink
set_interface_property reset_sink synchronousEdges NONE

set_interface_property reset_sink ENABLED true

add_interface_port reset_sink nreset reset_n Input 1
# | 
# +-----------------------------------

# +-----------------------------------
# | connection point avalon_mm_master_conduit
# | 
add_interface avalon_mm_master_conduit conduit end

set_interface_property avalon_mm_master_conduit ENABLED true

add_interface_port avalon_mm_master_conduit m_clock export Output 1
add_interface_port avalon_mm_master_conduit m_address export Output ADDR_WIDTH
add_interface_port avalon_mm_master_conduit m_byteenable export Output 2
add_interface_port avalon_mm_master_conduit m_readdata export Input 16
add_interface_port avalon_mm_master_conduit m_read export Output 1
add_interface_port avalon_mm_master_conduit m_write export Output 1
add_interface_port avalon_mm_master_conduit m_writedata export Output 16
add_interface_port avalon_mm_master_conduit m_waitrequest export Input 1
# | 
# +-----------------------------------
