// freq_counter_stim.sv - frequency counter testbench
// ELEC6027 VLSI design project - pp5g11
// digital frequency counter testbench
// 
// vf1.0

module freq_counter_stim;

timeunit 1ns; timeprecision 10ps;

logic in_wave, Clock, nReset ;
logic [15:0]out_buff [7:0] ;

freq_counter inst_1 ( out_freq, out_buff, in_wave, Clock, nReset );


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
      #10000
      in_wave = 0 ;
      
      #10000
      in_wave = 1 ;
      #8000
      in_wave = 0 ;
      
      #8000
      in_wave = 1 ;
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
      
      #1000000
      
      $stop;
      $finish;
   end   
      


endmodule
