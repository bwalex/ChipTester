// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.2
//
// multiplexer module - Chooses one of the 24 input signal and forwards it
// to the frequency measurement module, according to its select_input signal.

module mux (
  output logic out_wave,
  input logic [4:0]select_input,
  input logic in_signal [23:0],
  input wire nReset
);

timeunit 1ns; timeprecision 10ps;

// multiplexer
always_comb
  if (!nReset)      // asynchronous reset
    out_wave <= 0 ;
  else unique case (select_input)
      1 : out_wave <= in_signal [1] ;
      2 : out_wave <= in_signal [2] ;
      3 : out_wave <= in_signal [3] ;
      4 : out_wave <= in_signal [4] ;
      5 : out_wave <= in_signal [5] ;
      6 : out_wave <= in_signal [6] ;
      7 : out_wave <= in_signal [7] ;
      8 : out_wave <= in_signal [8] ;
      9 : out_wave <= in_signal [9] ;
      10 : out_wave <= in_signal [10] ;
      11 : out_wave <= in_signal [11] ;
      12 : out_wave <= in_signal [12] ;
      13 : out_wave <= in_signal [13] ;
      14 : out_wave <= in_signal [14] ;
      15 : out_wave <= in_signal [15] ;
      16 : out_wave <= in_signal [16] ;
      17 : out_wave <= in_signal [17] ;
      18 : out_wave <= in_signal [18] ;
      19 : out_wave <= in_signal [19] ;
      20 : out_wave <= in_signal [20] ;
      21 : out_wave <= in_signal [21] ;
      22 : out_wave <= in_signal [22] ;
      23 : out_wave <= in_signal [23] ;
      default : out_wave <= 0 ;
    endcase
endmodule
