// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.3
//
// frequency counter testbench
// 

module top_counter_stim;

timeunit 1ns; timeprecision 10ps;

  parameter ADDR_WIDTH = 8,
            DATA_WIDTH = 16,
            NREGS = 5,
            NDESIGNS = 24 ;
  parameter SEL_INPUT = 'h00 ;
  parameter SEL_SAMPLES = 'h01 ;

  parameter REG_DATA = 'h02 ;

  parameter START = 'h03 ;
  parameter REG_IRQ = 'h04 ;

  logic irq ;
  
  logic [ADDR_WIDTH-1:0] address ;

  logic read ;
  logic [DATA_WIDTH-1:0] readdata ;
  logic readdatavalid ;

  logic write ;
  logic [DATA_WIDTH-1:0] writedata ;

  logic in_signal [NDESIGNS-1:0] ;
  logic Clock, nResetIn ;



integer i ;

top_counter inst_1 (
  irq,
  
  address,

  read,
  readdata,
  oreaddatavalid,

  write,
  writedata,

  in_signal,
  Clock, nResetIn
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
      for (i = 0; i < 24; i = i+1) in_signal[i] = 0 ;
      #11000
      for (i = 0; i < 24; i = i+1) in_signal[i] = 1 ;
      #10000
      for (i = 0; i < 24; i = i+1) in_signal[i] = 0 ;
      
      #10000
      for (i = 0; i < 24; i = i+1) in_signal[i] = 1 ;
      #8000
      for (i = 0; i < 24; i = i+1) in_signal[i] = 0 ;
      
      #8000
      for (i = 0; i < 24; i = i+1) in_signal[i] = 1 ;
      #11000
      for (i = 0; i < 24; i = i+1) in_signal[i] = 0 ;
    end

  initial
    begin
      #500
      nResetIn = 1 ;
      write = 1 ;
      read = 0 ;
      #500
      nResetIn = 0 ;
      #500
      nResetIn = 0 ;
      #500
      nResetIn = 1 ;
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
      #500000
      
      if (irq) begin
        #1000
      read = 1 ;
      address = REG_DATA ;
      #1000
      read = 0 ;
      end
      
      
      #10000
      $stop;
      $finish;
   end   
      


endmodule
