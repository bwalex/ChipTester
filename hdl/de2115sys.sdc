#**************************************************************
# This .sdc file is created by Terasic Tool.
# Users are recommended to modify this file to match users logic.
#**************************************************************

#**************************************************************
# Create Clock
#**************************************************************
create_clock -period 20 [get_ports clock_50]
create_clock -period 20 [get_ports clock2_50]
create_clock -period 20 [get_ports clock3_50]
create_clock -period 8 -name "ENET0_RX_CLK" [get_ports ENET0_RX_CLK]
create_clock -period 8 -name "ENET0_TX_CLK" [get_ports ENET0_TX_CLK]


#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks


set_output_delay -clock "u0|altpll_0|sd1|pll7|clk[0]" -min 0.1 [get_ports {SRAM_ADDR*}]
set_output_delay -clock "u0|altpll_0|sd1|pll7|clk[0]" -max 0.1 [get_ports {SRAM_ADDR*}]

set_output_delay -clock "u0|altpll_0|sd1|pll7|clk[0]" -max 0.1 [get_ports {SRAM_BE_N[0]}]
set_output_delay -clock "u0|altpll_0|sd1|pll7|clk[0]" -max 0.1 [get_ports {SRAM_BE_N[1]}]

set_output_delay -clock "u0|altpll_0|sd1|pll7|clk[0]" -max 0.1 [get_ports {SRAM_WE_N}]
set_output_delay -clock "u0|altpll_0|sd1|pll7|clk[0]" -max 0.1 [get_ports {SRAM_OE_N}]


set_input_delay -clock "u0|altpll_0|sd1|pll7|clk[0]" -min 2 [get_ports {SRAM_DQ*}]
set_input_delay -clock "u0|altpll_0|sd1|pll7|clk[0]" -max 2 [get_ports {SRAM_DQ*}]

#**************************************************************
# Set Clock Latency
#**************************************************************
set_input_delay  -clock "ENET0_RX_CLK"  -min 2 [get_ports ENET0_RX_CLK]



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************



