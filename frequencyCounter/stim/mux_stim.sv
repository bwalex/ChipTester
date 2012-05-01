// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.3
//
// multiplexer module testbench
// 

module buffer_stim;

timeunit 1ns; timeprecision 10ps;

  logic out_wave ;
  logic [7:0]select_input ;
  logic in_signal [23:0] ;
  logic nReset ;


integer i ;

mux inst_1 (
  out_wave,
  select_input,
  in_signal,
  nReset
);

    
  always
    begin
      #1000
      for (i = 0; i < 8; i = i+1) in_signal[i] = 1 ;
      #1000
      for (i = 0; i < 8; i = i+1) in_signal[i] = 0 ;
    end
    
    always
    begin
      #600
      for (i = 8; i < 16; i = i+1) in_signal[i] = 1 ;
      #600
      for (i = 8; i < 16; i = i+1) in_signal[i] = 0 ;
    end
    
    always
    begin
      #1700
      for (i = 16; i < 24; i = i+1) in_signal[i] = 1 ;
      #1700
      for (i = 16; i < 24; i = i+1) in_signal[i] = 0 ;
    end

  initial
    begin
      #500
      nReset = 1 ;
      #500
      nReset = 0 ;
      #500
      nReset = 0 ;
      #500
      nReset = 1 ;
      #1000
      select_input = 5 ;
      #1000
      #10000
      select_input = 15 ;
      #15000
      select_input = 20 ;
            
      #20000
      
      $stop;
      $finish;
   end   
      


endmodule
