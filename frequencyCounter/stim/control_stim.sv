// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.3
//
// control module testbench
// 

module control_stim;

timeunit 1ns; timeprecision 10ps;

  parameter ADDR_WIDTH = 8,
            DATA_WIDTH = 16,
            NREGS = 5 ;
            
  parameter SEL_INPUT = 'h00 ;
  parameter SEL_SAMPLES = 'h01 ;

  parameter REG_DATA = 'h02 ;

  parameter START = 'h03 ;
  parameter REG_IRQ = 'h04 ;


  logic irq ;
  
  logic      [ADDR_WIDTH-1:0] address ;

  logic                       read ;
  logic [DATA_WIDTH-1:0] readdata ;
  logic                  readdatavalid ;

  logic                       write ;
  logic      [DATA_WIDTH-1:0] writedata ;

  logic [DATA_WIDTH-1:0]samples_required ;
  logic [DATA_WIDTH-1:0]select_input ;
  logic enable, nResetOut ;
 
  logic done_flag ;
  logic [DATA_WIDTH-1:0]out_value ;
  logic Clock, nReset ;
  
  integer i ;

control inst_1 (
  irq,
  
  address,

  read,
  readdata,
  readdatavalid,

  write,
  writedata,

  samples_required,
  select_input,
  enable, nResetOut,
 
  done_flag,
  out_value ,
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
      write = 1 ;
      address = SEL_INPUT ;
      writedata = 15 ;
      #1000
      address = SEL_SAMPLES ;
      writedata = 16 ;
      #1000
      address = START ;
      writedata = 8 ;
      #1000
      write = 0 ;
      #2000
      done_flag = 1 ;
      out_value = 20 ;
      
      #5000
      read = 1 ;
      address = REG_DATA ;
      #1000
      done_flag = 0 ;
      #1000
      read = 0 ;
      
      #10000
      
      $stop;
      $finish;
   end   
      


endmodule
