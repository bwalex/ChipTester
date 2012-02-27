onerror {resume}
quietly WaveActivateNextPane {} 0

radix define stim_states {
  6'b000000 "IDLE" -color white,
  6'b000001 "READ_META" -color green,
  6'b000010 "READ_TV" -color yellow,
  6'b000011 "SWITCH_TARGET" -color blue,
  6'b000100 "SWITCH_VDD" -color blue,
  6'b000101 "WR_FIFOS" -color yellow,
  6'b000110 "SETUP_BITMASK" -color orange,
  -default binary
}

add wave -noupdate /top/start_test

add wave -noupdate -divider CLK_RESET
add wave -noupdate /top/clock
add wave -noupdate /top/reset_n

add wave -noupdate -divider MEM_IF_AVALON_MM
add wave -noupdate -radix hexadecimal /top/address
add wave -noupdate /top/byteenable
add wave -noupdate -radix hexadecimal /top/readdata

add wave -noupdate -divider STIM_AVALON_MM
add wave -noupdate /top/stim_waitrequest
add wave -noupdate -radix hexadecimal /top/stim_address
add wave -noupdate /top/stim_byteenable
add wave -noupdate /top/stim_read
add wave -noupdate -radix hexadecimal /top/stim_readdata

add wave -noupdate -divider STIM_SFIFO
add wave -noupdate /top/sfifo_wrreq
add wave -noupdate /top/sfifo_wrfull
add wave -noupdate /top/sfifo_wrempty
add wave -noupdate -radix hexadecimal /top/sfifo_data

add wave -noupdate -divider STIM_CFIFO
add wave -noupdate /top/cfifo_wrreq
add wave -noupdate /top/cfifo_wrfull
add wave -noupdate /top/cfifo_wrempty
add wave -noupdate -radix hexadecimal /top/cfifo_data

add wave -noupdate -divider STIM_CHECK_IF
add wave -noupdate -radix hexadecimal /top/sc_cmd
add wave -noupdate -radix hexadecimal /top/sc_data
add wave -noupdate /top/sc_switching

add wave -noupdate -divider STIM_TARGET_IF
add wave -noupdate -radix hexadecimal /top/stim_mod/target_sel

add wave -noupdate -divider STIM_INTERNAL
add wave -noupdate  -radix stim_states /top/stim_mod/state
add wave -noupdate  -radix stim_states /top/stim_mod/next_state
#add wave -noupdate -radix hexadecimal /top/stim_mod/address
add wave -noupdate /top/stim_mod/inc_address

add wave -noupdate -divider STIM_WAITCNT
add wave -noupdate /top/stim_mod/reset_waitcnt
add wave -noupdate -radix hexadecimal /top/stim_mod/waitcnt


add wave -noupdate -divider STIM_BUFFER
add wave -noupdate -radix hexadecimal /top/stim_mod/buffer
add wave -noupdate -radix decimal /top/stim_mod/buffer_offset
add wave -noupdate -radix decimal /top/stim_mod/words_stored
add wave -noupdate /top/stim_mod/reset_wstored
add wave -noupdate -radix binary /top/stim_mod/req_type
add wave -noupdate -radix hexadecimal /top/stim_mod/input_vector
add wave -noupdate -radix hexadecimal /top/stim_mod/result_vector
add wave -noupdate -radix hexadecimal /top/stim_mod/output_bitmask

add wave -noupdate -divider STIM_SETUP
add wave -noupdate -radix decimal /top/stim_mod/tv_len


TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 209
configure wave -valuecolwidth 166
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {200 ns}
