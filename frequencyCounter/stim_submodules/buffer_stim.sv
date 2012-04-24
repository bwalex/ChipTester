// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.2
//
// buffer module testbench
// 

module buffer_stim;

timeunit 1ns; timeprecision 10ps;

  logic [9:0]average ;
  logic [9:0]buff [7:0] ;
  logic done_flag ;
  shortint samples_required ;
  logic [12:0]current_freq ;
  logic enable, in_wave, Clock, nReset ;


integer i ;

buffer inst_1 (
  average,
  buff,
  done_flag,
  samples_required,
  current_freq,
  enable, in_wave, Clock, nReset
);


  always
    begin
           Clock = 0;
      #250 Clock = 1;
      #500 Clock = 0;
      #250 Clock = 0;
    end
 
  always
    begin
      #11000
        in_wave = 1 ;
        current_freq = 20 ;
      #10000
        in_wave = 0 ;
      
      #10000
        in_wave = 1 ;
        current_freq = 18 ;
      #8000
        in_wave = 0 ;
      
      #8000
        in_wave = 1 ;
        current_freq = 22 ;
      #11000
        in_wave = 0 ;
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
      samples_required = 10 ;
      #1000
      enable = 1 ;
            
      #1000000
      
      $stop;
      $finish;
   end   
      


endmodule
