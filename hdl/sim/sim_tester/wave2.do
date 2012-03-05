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
  6'b000111 "SEND_DICMD" -color orange,
  6'b001000 "WR_DIFIFO" -color orange,
  6'b001001 "END" -color white,
  -default binary
}

radix define check_states {
  6'b000000 "IDLE" -color white,
  6'b000001 "RD_FIFOS" -color yellow,
  6'b000010 "CMP_AND_MASK" -color yellow,
  6'b000011 "COMPRESS" -color orange,
  6'b000100 "WRITEBACK" -color green,
  6'b000110 "SETUP_BITMASK" -color blue,
  -default binary
}

add wave -noupdate /top/start_test

add wave -noupdate -divider CLK_RESET
add wave -noupdate /top/clock
add wave -noupdate /top/clock_10
add wave -noupdate /top/reset_n

add wave -noupdate -divider SRAM_ARB
add wave -noupdate -radix hexadecimal /top/arb/address
add wave -noupdate  /top/arb/read
add wave -noupdate  /top/arb/write
add wave -noupdate -radix hexadecimal /top/arb/writedata

add wave -noupdate -radix hexadecimal /top/arb/sram_address
add wave -noupdate -radix hexadecimal /top/arb/sram_data
add wave -noupdate -radix hexadecimal /top/arb/readdata
add wave -noupdate -radix hexadecimal /top/arb/writedata_r
add wave -noupdate  /top/arb/sram_oe_n
add wave -noupdate  /top/arb/sram_we_n
add wave -noupdate  /top/arb/sram_be_n





add wave -noupdate -divider MEM_IF_AVALON_MM
add wave -noupdate -radix hexadecimal /top/address
add wave -noupdate /top/byteenable
add wave -noupdate /top/write
add wave -noupdate -radix hexadecimal /top/writedata
add wave -noupdate /top/read
add wave -noupdate -radix hexadecimal /top/readdata
add wave -noupdate /top/memif/mem_waitrequest
add wave -noupdate /top/memif/mem_readdataready
add wave -noupdate /top/memif/sel


add wave -noupdate -divider SFIFO
add wave -noupdate /top/sfifo_wrreq
add wave -noupdate /top/sfifo_wrfull
add wave -noupdate /top/sfifo_wrempty
add wave -noupdate -radix hexadecimal /top/sfifo_data
add wave -noupdate /top/sfifo_rdreq
add wave -noupdate /top/sfifo_rdempty
add wave -noupdate -radix hexadecimal /top/sfifo_dataq

add wave -noupdate -divider CFIFO
add wave -noupdate /top/cfifo_wrreq
add wave -noupdate /top/cfifo_wrfull
add wave -noupdate /top/cfifo_wrempty
add wave -noupdate -radix hexadecimal /top/cfifo_data
add wave -noupdate /top/cfifo_rdreq
add wave -noupdate /top/cfifo_rdempty
add wave -noupdate -radix hexadecimal /top/cfifo_dataq

add wave -noupdate -divider RFIFO
add wave -noupdate /top/rfifo_wrreq
add wave -noupdate /top/rfifo_wrfull
add wave -noupdate -radix hexadecimal /top/rfifo_data
add wave -noupdate /top/rfifo_rdreq
add wave -noupdate /top/rfifo_rdempty
add wave -noupdate -radix hexadecimal /top/rfifo_dataq

add wave -noupdate -divider DIFIFO
add wave -noupdate /top/dififo_wrreq
add wave -noupdate /top/dififo_wrfull
add wave -noupdate -radix hexadecimal /top/dififo_data
add wave -noupdate /top/dififo_rdreq
add wave -noupdate /top/dififo_rdempty
add wave -noupdate -radix hexadecimal /top/dififo_dataq


add wave -noupdate -divider STIM_AVALON_MM
add wave -noupdate /top/stim_waitrequest
add wave -noupdate -radix hexadecimal /top/stim_address
add wave -noupdate /top/stim_byteenable
add wave -noupdate /top/stim_read
add wave -noupdate /top/stim_readdataready
add wave -noupdate -radix hexadecimal /top/stim_readdata

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
add wave -noupdate -radix decimal /top/stim_mod/reads_requested
add wave -noupdate /top/stim_mod/reset_wstored
add wave -noupdate -radix binary /top/stim_mod/req_type
add wave -noupdate -radix hexadecimal /top/stim_mod/input_vector
add wave -noupdate -radix hexadecimal /top/stim_mod/result_vector
add wave -noupdate -radix hexadecimal /top/stim_mod/output_bitmask

add wave -noupdate -divider STIM_SETUP
add wave -noupdate -radix decimal /top/stim_mod/tv_len

add wave -noupdate -divider CHECK_INTERNAL
add wave -noupdate  -radix check_states /top/check_mod/state
add wave -noupdate  -radix check_states /top/check_mod/next_state
add wave -noupdate -radix hexadecimal /top/check_mod/address
add wave -noupdate /top/check_mod/inc_address
add wave -noupdate -radix hexadecimal /top/check_mod/result_bitmask

add wave -noupdate -divider CHECK_BUFFER
add wave -noupdate /top/check_mod/check_fail
add wave -noupdate -radix hexadecimal /top/check_mod/result_vector
add wave -noupdate -radix hexadecimal /top/check_mod/c_result_vector
add wave -noupdate -radix hexadecimal /top/check_mod/meta_info
add wave -noupdate -radix decimal /top/check_mod/words_stored


add wave -noupdate -divider CHECK_AVALON_MM
add wave -noupdate /top/check_waitrequest
add wave -noupdate -radix hexadecimal /top/check_address
add wave -noupdate /top/check_byteenable
add wave -noupdate /top/check_write
add wave -noupdate -radix hexadecimal /top/check_writedata


add wave -noupdate -divider DUT_IF
add wave -noupdate /top/dut_if/clock
add wave -noupdate /top/dut_if/stall_n
add wave -noupdate /top/dut_if/clock_gated
add wave -noupdate -radix hexadecimal /top/dut_if/mosi_data
add wave -noupdate -radix hexadecimal /top/dut_if/mosi_data_r
add wave -noupdate -radix hexadecimal /top/dut_if/miso_data
add wave -noupdate -radix hexadecimal /top/dut_if/miso_data_r
add wave -noupdate /top/dut_if/rfifo_wrreq;
add wave -noupdate /top/dut_if/sfifo_rdempty;
add wave -noupdate /top/dut_if/sfifo_data;
add wave -noupdate /top/dut_if/sfifo_rdreq;
add wave -noupdate /top/dut_if/sfifo_rdreq_d1;
add wave -noupdate /top/dut_if/sfifo_rdreq_d2;
add wave -noupdate /top/dut_if/sfifo_rdreq_d3;




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
