// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.2
//
// frequency counter testbench
// 

module top_counter_stim;

timeunit 1ns; timeprecision 10ps;

logic in_signal[23:0] ;
logic [15:0]mem_write ;
logic wr_enable ;
logic [5:0]address ;
logic [15:0]mem_read ;
logic rd_enable ;
logic Clock, nReset ;
//logic [15:0]out_buff [7:0] ;

integer i ;

top_counter inst_1 (
  irq_out,
  mem_write,
  wr_enable,
  address,
  mem_read,
  rd_enable,
  in_signal,
  Clock, nReset
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
      nReset = 1 ;
      wr_enable = 0 ;
      rd_enable = 0 ;
      #500
      nReset = 0 ;
      #500
      nReset = 0 ;
      #500
      nReset = 1 ;
      #1000
      rd_enable = 1 ;
      address = 6'b100001 ;
      mem_read = 'b10 ;
      #1000
      address = 6'b100010 ;
      mem_read = 'b10000 ;
      #1000
      address = 6'b101111 ;
      mem_read = 'b1000 ;
      #1000
      rd_enable = 0 ;
      
      
            #500000
      
      if (irq_out) begin
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
      end
      
      #10000
      

      
      $stop;
      $finish;
   end   
      


endmodule
