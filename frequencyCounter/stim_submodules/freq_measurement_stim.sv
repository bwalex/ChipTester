// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.2
//
// frequency measurement module testbench
// 

module freq_measurement_stim;

timeunit 1ns; timeprecision 10ps;

logic in_signal, enable, Clock, nReset ;

integer i ;

freq_measurement inst_1 (
  measure,
  in_signal, enable, Clock, nReset
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
        in_signal = 1 ;
      #10000
        in_signal = 0 ;
      
      #10000
        in_signal = 1 ;
      #8000
        in_signal = 0 ;
      
      #8000
        in_signal = 1 ;
      #11000
        in_signal = 0 ;
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
      enable = 1 ;
      #4000
      enable = 0 ;
      #1000
      enable = 1 ;
            
      #1000000
      
      $stop;
      $finish;
   end   
      


endmodule
