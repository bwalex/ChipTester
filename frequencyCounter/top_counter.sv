// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.3
//
// top-level module - Provides the connections between the sub-modules
// of the process and the interface to previous/next blocks of the process.

timeunit 1ns; timeprecision 10ps;

module top_counter #(
  parameter ADDR_WIDTH = 8,
            DATA_WIDTH = 16,
            NREGS = 5,
            NDESIGNS = 24
)(
  output logic irq,
  
  input      [ADDR_WIDTH-1:0] address,

  input                       read,
  output reg [DATA_WIDTH-1:0] readdata,
  output reg                  readdatavalid,

  input                       write,
  input      [DATA_WIDTH-1:0] writedata,

  input logic in_signal [NDESIGNS-1:0],
  input wire Clock, nResetIn
) ;

// declaration of local signals
logic [DATA_WIDTH-1:0]out_value ;
logic done_flag ;

logic [DATA_WIDTH-1:0]samples_required ;
logic [DATA_WIDTH-1:0]select_input ;

logic enable, nReset ;

logic mux_wave ;

// instantiation of the modules
mux mux_1 (mux_wave, select_input, in_signal, nReset) ;
freq_measurement freq_measurement_1 (out_value, done_flag, samples_required, mux_wave, enable, Clock, nReset) ;
control control_1 (irq, address, read, readdata, readdatavalid, write, writedata, samples_required, select_input, enable, nReset, done_flag, out_value, Clock, nResetIn) ;


endmodule
