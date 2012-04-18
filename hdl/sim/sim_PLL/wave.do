onerror {resume}
quietly WaveActivateNextPane {} 0

radix define repll_ctr_states {
  4'b0000 "IDLE" -color white,
  4'b0001 "RESET_PLL" -color green,
  4'b0010 "RESET_REC" -color yellow,
  4'b0011 "SET_TYPE_M" -color blue,
  4'b0100 "SET_PARAM_HM" -color blue,
  4'b0101 "SET_PARAM_LM" -color yellow,
  4'b0110 "WRITE_HM" -color orange,
  4'b0111 "WRITE_LM" -color orange,
  4'b1000 "INTERVAL" -color orange,
  4'b1001 "SET_TYPE_C" -color white,
  4'b1010 "SET_PARAM_HC" -color white,
  4'b1011 "SET_PARAM_LC" -color white,
  4'b1100 "WRITE_HC" -color white,
  4'b1101 "WRITE_LC" -color white,
  4'b1110 "RECONFIG" -color white,
  4'b1111 "BUSY" -color white,
  -default binary
}

add wave -noupdate /TestInterface/inclk0
add wave -noupdate /TestInterface/clock
add wave -noupdate /TestInterface/reset_n
add wave -noupdate /TestInterface/trigger
add wave -noupdate -radix hexadecimal /TestInterface/MultiFactor
add wave -noupdate -radix hexadecimal /TestInterface/DividFactor
add wave -noupdate -radix hexadecimal /TestInterface/PLL_DATA
add wave -noupdate /TestInterface/c0
add wave -noupdate /TestInterface/locked
add wave -noupdate /TestInterface/busy
add wave -noupdate -radix hexadecimal /TestInterface/data_out

add wave -noupdate -divider REPLL_CONTROL_INTERNAL
add wave -noupdate /TestInterface/PI2/ctr2/clock_ctr
add wave -noupdate /TestInterface/PI2/ctr2/sys_reset
add wave -noupdate /TestInterface/PI2/ctr2/trigger
add wave -noupdate /TestInterface/PI2/ctr2/busy_ctr
add wave -noupdate -radix hexadecimal /TestInterface/PI2/ctr2/MultiFactor
add wave -noupdate -radix hexadecimal /TestInterface/PI2/ctr2/DividFactor
add wave -noupdate -radix decimal /TestInterface/PI2/ctr2/counter_param_ctr
add wave -noupdate -radix decimal /TestInterface/PI2/ctr2/counter_type_ctr
add wave -noupdate -radix repll_ctr_states /TestInterface/PI2/ctr2/state
add wave -noupdate -radix repll_ctr_states /TestInterface/PI2/ctr2/next_state
add wave -noupdate -radix decimal /TestInterface/PI2/ctr2/counter_5
add wave -noupdate -radix decimal /TestInterface/PI2/ctr2/counter_10
add wave -noupdate /TestInterface/PI2/ctr2/Delay_5
add wave -noupdate /TestInterface/PI2/ctr2/Delay_10
add wave -noupdate /TestInterface/PI2/ctr2/timed_5
add wave -noupdate /TestInterface/PI2/ctr2/timed_10
add wave -noupdate /TestInterface/PI2/ctr2/reset_ctr
add wave -noupdate /TestInterface/PI2/ctr2/pll_areset_in_ctr
add wave -noupdate /TestInterface/PI2/ctr2/write_param_ctr
add wave -noupdate /TestInterface/PI2/ctr2/reconfig_ctr
add wave -noupdate /TestInterface/PI2/ctr2/pll_pfdena
add wave -noupdate /TestInterface/PI2/ctr2/pll_read_param
add wave -noupdate -radix hexadecimal /TestInterface/PI2/ctr2/config_data_in

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 279
configure wave -valuecolwidth 103
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {809 ps}
