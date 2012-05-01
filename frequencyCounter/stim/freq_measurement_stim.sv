// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.3
//
// frequency measurement module testbench
// 

module freq_measurement_stim;

timeunit 1ns; timeprecision 10ps;

logic [15:0]out_value ;
logic done_flag ;
logic [7:0]samples_required ;
logic in_wave ;
logic enable, Clock, nReset ;

integer i ;

freq_measurement inst_1 (
  out_value ,
  done_flag ,
  samples_required ,
  in_wave ,
  enable, Clock, nReset ,
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
      #10000
        in_wave = 1 ;
      #10000
        in_wave = 0 ;
    end

  initial
    begin
      #500
      nReset = 1 ;
      samples_required = 22 ;
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
