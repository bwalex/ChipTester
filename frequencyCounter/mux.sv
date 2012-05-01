// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.3
//
// multiplexer module - Chooses one of the 24 input signal and forwards it
// to the frequency measurement module, according to its select_input signal.

module mux #(
  parameter NDESIGNS = 24,
            DATA_WIDTH = 16
)(
  output logic out_wave,
  input logic [DATA_WIDTH-1:0]select_input,
  input logic in_signal [NDESIGNS-1:0],
  input wire nReset
);

timeunit 1ns; timeprecision 10ps;

assign out_wave = (nReset) ? in_signal[select_input] : 'b0 ;

endmodule
