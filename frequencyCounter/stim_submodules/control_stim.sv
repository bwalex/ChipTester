// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.2
//
// control module testbench
// 

module control_stim;

timeunit 1ns; timeprecision 10ps;

  logic irq_out ;
  shortint samples_required ;
  logic [4:0]select_input ;
  logic enable ;
  
  logic [15:0]mem_write ;
  logic wr_enable ;
  logic [5:0]address ;
  logic [15:0]mem_read ;
  logic rd_enable ;
  
  logic done_flag ;
  logic [9:0]average ;
  logic [9:0]buff [7:0] ;
  logic Clock, nReset ;
  
  integer i ;

control inst_1 (
  irq_out,
  samples_required,
  select_input,
  enable, 
  
  mem_write,
  wr_enable,
  address,
  mem_read,
  rd_enable,
  
  done_flag,
  average,
  buff,
  Clock, nReset
);


  always
    begin
           Clock = 0;
      #250 Clock = 1;
      #500 Clock = 0;
      #250 Clock = 0;
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
      rd_enable = 1 ;
      address = 6'b100001 ;
      mem_read = 11'b00000000010 ;
      #1000
      address = 6'b100010 ;
      mem_read = 11'b00000010000 ;
      #1000
      address = 6'b101111 ;
      mem_read = 11'b00000001000 ;
      #10000
      rd_enable = 0 ;
      done_flag = 1 ;
      average = 20 ;
      buff[7] = 21 ;
      buff[6] = 22 ;
      buff[5] = 19 ;
      buff[4] = 22 ;
      buff[3] = 21 ;
      buff[2] = 20 ;
      buff[1] = 20 ;
      buff[0] = 21 ;
      
      #5000
      done_flag = 0 ;
      #1000
      average = 0 ;
      buff[7] = 0 ;
      buff[6] = 0 ;
      buff[5] = 0 ;
      buff[4] = 0 ;
      buff[3] = 0 ;
      buff[2] = 0 ;
      buff[1] = 0 ;
      buff[0] = 0 ;
      
      #1000
      wr_enable = 1 ;
      address = 6'b010001 ;
      #1000
      address = 6'b010010 ;
      #1000
      address = 6'b010011 ;
      #1000
      address = 6'b010100 ;
      #1000
      address = 6'b010101 ;
      #1000
      address = 6'b010110 ;
      #1000
      address = 6'b010111 ;
      #1000
      address = 6'b011000 ;
      #1000
      address = 6'b011001 ;
      wr_enable = 0 ;
      
      #10000
      
      $stop;
      $finish;
   end   
      


endmodule
