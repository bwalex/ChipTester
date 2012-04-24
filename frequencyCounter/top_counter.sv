// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.2
//
// top-level module - Provides the connections between the sub-modules
// of the process and the interface to previous/next blocks of the process.

timeunit 1ns; timeprecision 10ps;

module top_counter (
  output logic irq_out,
  output logic [15:0]mem_write,
  input logic wr_enable,
  input logic [5:0]address,
  input logic [15:0]mem_read,
  input logic rd_enable,
  input logic in_signal [23:0],
  input wire Clock, nResetIn
) ;

// declaration of local signals
logic [9:0]average ;
logic [9:0]buff [7:0] ;
logic done_flag ;

shortint samples_required ;
logic [4:0]select_input ;

logic enable, nReset ;

logic mux_wave ;

logic [12:0]freq_value ;

// instantiation of the modules
mux mux_1 (mux_wave, select_input, in_signal, nReset) ;
freq_measurement freq_measurement_1 (freq_value, mux_wave, enable, Clock, nReset) ;
buffer buffer_1 (average, buff, done_flag, samples_required, freq_value, enable, mux_wave, Clock, nReset) ;
control control_1 (irq_out, samples_required, select_input, enable, nReset, mem_write, wr_enable, address, mem_read, rd_enable, done_flag, average, buff, Clock, nResetIn) ;


endmodule
