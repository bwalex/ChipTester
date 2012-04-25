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
  6'b001010 "START_REPLL" -color brown,
  6'b001011 "PLL_RECONFIG" -color brown,
  6'b001100 "SWITCH_TOPLL" -color brown,
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
add wave -noupdate /top/tester/test_controller/memif/mem_waitrequest
add wave -noupdate /top/tester/test_controller/memif/mem_readdataready
add wave -noupdate /top/tester/test_controller/memif/sel


add wave -noupdate -divider SFIFO
add wave -noupdate -radix unsigned /top/tester/test_controller/sfifo_inst/dcfifo_component/wrusedw
add wave -noupdate /top/tester/test_controller/sfifo_wrreq
add wave -noupdate /top/tester/test_controller/sfifo_wrfull
add wave -noupdate /top/tester/test_controller/sfifo_wrempty
add wave -noupdate -radix hexadecimal /top/tester/test_controller/sfifo_data
add wave -noupdate /top/tester/test_controller/sfifo_rdreq
add wave -noupdate /top/tester/test_controller/sfifo_rdempty
add wave -noupdate -radix hexadecimal /top/tester/test_controller/sfifo_dataq

add wave -noupdate -divider CFIFO
add wave -noupdate -radix unsigned /top/tester/test_controller/cfifo_inst/dcfifo_component/rdusedw
add wave -noupdate /top/tester/test_controller/cfifo_wrreq
add wave -noupdate /top/tester/test_controller/cfifo_wrfull
add wave -noupdate /top/tester/test_controller/cfifo_wrempty
add wave -noupdate -radix hexadecimal /top/tester/test_controller/cfifo_data
add wave -noupdate /top/tester/test_controller/cfifo_rdreq
add wave -noupdate /top/tester/test_controller/cfifo_rdempty
add wave -noupdate -radix hexadecimal /top/tester/test_controller/cfifo_dataq

add wave -noupdate -divider RFIFO
add wave -noupdate -radix unsigned /top/tester/test_controller/rfifo_inst/dcfifo_component/rdusedw
add wave -noupdate /top/tester/test_controller/rfifo_wrreq
add wave -noupdate /top/tester/test_controller/rfifo_wrfull
add wave -noupdate -radix hexadecimal /top/tester/test_controller/rfifo_data
add wave -noupdate /top/tester/test_controller/rfifo_rdreq
add wave -noupdate /top/tester/test_controller/rfifo_rdempty
add wave -noupdate -radix hexadecimal /top/tester/test_controller/rfifo_dataq

add wave -noupdate -divider DIFIFO
add wave -noupdate -radix unsigned /top/tester/test_controller/dififo_inst/dcfifo_component/wrusedw
add wave -noupdate /top/tester/test_controller/dififo_wrreq
add wave -noupdate /top/tester/test_controller/dififo_wrfull
add wave -noupdate -radix hexadecimal /top/tester/test_controller/dififo_data
add wave -noupdate /top/tester/test_controller/dififo_rdreq
add wave -noupdate /top/tester/test_controller/dififo_rdempty
add wave -noupdate -radix hexadecimal /top/tester/test_controller/dififo_dataq


add wave -noupdate -divider STIM_AVALON_MM
add wave -noupdate /top/tester/test_controller/stim_waitrequest
add wave -noupdate -radix hexadecimal /top/tester/test_controller/stim_address
add wave -noupdate /top/tester/test_controller/stim_byteenable
add wave -noupdate /top/tester/test_controller/stim_read
add wave -noupdate /top/tester/test_controller/stim_readdataready
add wave -noupdate -radix hexadecimal /top/tester/test_controller/stim_readdata

add wave -noupdate -divider STIM_CHECK_IF
add wave -noupdate -radix hexadecimal /top/tester/test_controller/sc_cmd
add wave -noupdate -radix hexadecimal /top/tester/test_controller/sc_data
add wave -noupdate /top/tester/test_controller/sc_ready

add wave -noupdate -divider STIM_TARGET_IF
add wave -noupdate -radix hexadecimal /top/tester/test_controller/stim_mod/target_sel

add wave -noupdate -divider STIM_INTERNAL
add wave -noupdate  -radix stim_states /top/tester/test_controller/stim_mod/state
add wave -noupdate  -radix stim_states /top/tester/test_controller/stim_mod/next_state
#add wave -noupdate -radix hexadecimal /top/tester/test_controller/stim_mod/address
add wave -noupdate /top/tester/test_controller/stim_mod/inc_address

add wave -noupdate -divider STIM_WAITCNT
add wave -noupdate /top/tester/test_controller/stim_mod/reset_waitcnt
add wave -noupdate -radix hexadecimal /top/tester/test_controller/stim_mod/waitcnt

add wave -noupdate -divider STIM_BUFFER
add wave -noupdate -radix hexadecimal /top/tester/test_controller/stim_mod/buffer
add wave -noupdate -radix decimal /top/tester/test_controller/stim_mod/buffer_offset
add wave -noupdate -radix decimal /top/tester/test_controller/stim_mod/words_stored
add wave -noupdate -radix decimal /top/tester/test_controller/stim_mod/reads_requested
add wave -noupdate /top/tester/test_controller/stim_mod/reset_wstored
add wave -noupdate -radix binary /top/tester/test_controller/stim_mod/req_type
add wave -noupdate -radix hexadecimal /top/tester/test_controller/stim_mod/input_vector
add wave -noupdate -radix hexadecimal /top/tester/test_controller/stim_mod/result_vector
add wave -noupdate -radix hexadecimal /top/tester/test_controller/stim_mod/output_bitmask

add wave -noupdate -divider STIM_SETUP
add wave -noupdate -radix decimal /top/tester/test_controller/stim_mod/tv_len

add wave -noupdate -divider CHECK_INTERNAL
add wave -noupdate  -radix check_states /top/tester/test_controller/check_mod/state
add wave -noupdate  -radix check_states /top/tester/test_controller/check_mod/next_state
add wave -noupdate -radix hexadecimal /top/tester/test_controller/check_mod/address
add wave -noupdate /top/tester/test_controller/check_mod/inc_address
add wave -noupdate -radix hexadecimal /top/tester/test_controller/check_mod/result_bitmask

add wave -noupdate -divider CHECK_BUFFER
add wave -noupdate /top/tester/test_controller/check_mod/check_fail
add wave -noupdate -radix hexadecimal /top/tester/test_controller/check_mod/result_vector
add wave -noupdate -radix hexadecimal /top/tester/test_controller/check_mod/c_result_vector
add wave -noupdate -radix hexadecimal /top/tester/test_controller/check_mod/meta_info
add wave -noupdate -radix decimal /top/tester/test_controller/check_mod/words_stored


add wave -noupdate -divider CHECK_AVALON_MM
add wave -noupdate /top/tester/test_controller/check_waitrequest
add wave -noupdate -radix hexadecimal /top/tester/test_controller/check_address
add wave -noupdate /top/tester/test_controller/check_byteenable
add wave -noupdate /top/tester/test_controller/check_write
add wave -noupdate -radix hexadecimal /top/tester/test_controller/check_writedata

add wave -noupdate -divider STIM_PLL_RECONFIG
add wave -noupdate /top/tester/clock
add wave -noupdate /top/tester/test_controller/fifo_clock
add wave -noupdate -radix unsigned /top/tester/pll_if/MultiFactor
add wave -noupdate -radix unsigned /top/tester/pll_if/DividFactor
add wave -noupdate -radix hexadecimal /top/tester/test_controller/stim_mod/pll_data
add wave -noupdate /top/tester/test_controller/stim_mod/pll_reset
add wave -noupdate /top/tester/test_controller/stim_mod/pll_trigger
add wave -noupdate /top/tester/test_controller/stim_mod/pll_locked
add wave -noupdate /top/tester/test_controller/stim_mod/pll_stable


add wave -noupdate -divider DUT_IF
add wave -noupdate /top/tester/dut_if/clock
add wave -noupdate /top/tester/dut_if/stall_n
add wave -noupdate /top/tester/dut_if/clock_gated
add wave -noupdate -radix hexadecimal /top/tester/dut_if/mosi_data
add wave -noupdate -radix hexadecimal /top/tester/dut_if/miso_data
add wave -noupdate /top/tester/dut_if/rfifo_wrreq;
add wave -noupdate /top/tester/dut_if/sfifo_rdempty;
add wave -noupdate /top/tester/dut_if/sfifo_data;
add wave -noupdate /top/tester/dut_if/sfifo_rdreq;


radix define dut_execute_states {
  2'b00 "IDLE" -color white,
  2'b01 "WAIT_COUNT" -color yellow,
  2'b10 "WAIT_TRIGGER" -color orange,
  -default binary
}


add wave -noupdate -divider DUT_IF_PIPELINE
add wave -noupdate /top/tester/dut_if/clock
add wave -noupdate /top/tester/dut_if/stall_fetch
add wave -noupdate /top/tester/dut_if/stall_execute
add wave -noupdate /top/tester/dut_if/stall_execute_o
add wave -noupdate /top/tester/dut_if/stall_writeback_o
add wave -noupdate /top/tester/dut_if/bubble_fetch_execute
add wave -noupdate /top/tester/dut_if/bubble_execute_writeback
add wave -noupdate -divider
add wave -noupdate /top/tester/dut_if/dut_fetch/rd_req
add wave -noupdate -divider
add wave -noupdate /top/tester/dut_if/dut_execute/trigger_match
add wave -noupdate /top/tester/dut_if/dut_execute/counter_match
add wave -noupdate -radix dut_execute_states /top/tester/dut_if/dut_execute/state
add wave -noupdate -radix dut_execute_states /top/tester/dut_if/dut_execute/next_state
add wave -noupdate -divider
add wave -noupdate /top/tester/dut_if/dut_execute/st_mode
add wave -noupdate -radix unsigned /top/tester/dut_if/dut_execute/cycle_count
add wave -noupdate -radix hexadecimal /top/tester/dut_if/dut_execute/st_data
add wave -noupdate -radix unsigned /top/tester/dut_if/dut_execute/cycle_count_int
add wave -noupdate -radix unsigned /top/tester/dut_if/dut_execute/cycle_count_r
add wave -noupdate -divider
add wave -noupdate /top/tester/dut_if/dut_writeback/wr_req_r
add wave -noupdate -radix hexadecimal /top/tester/dut_if/dut_writeback/wr_data_r


add wave -noupdate -divider
add wave -noupdate /top/tester/dut_if/mode_execute_writeback
add wave -noupdate -radix unsigned /top/tester/dut_if/count_execute_writeback
add wave -noupdate -radix hexadecimal /top/tester/dut_if/result_execute_writeback
add wave -noupdate /top/tester/dut_if/timeout_execute_writeback







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
