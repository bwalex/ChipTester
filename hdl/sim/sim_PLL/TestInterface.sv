`timescale 1 ps / 1 ps
module TestInterface;
  	
	logic	  inclk0;
	logic   clock;
	logic   reset;
	logic   trigger;
	logic   [7:0] MultiFactor;
  logic   [7:0] DividFactor;
	logic	c0;
	logic	locked;

	logic   busy;
	logic   [8:0]  data_out;
	
	PLL_INTERFACE PI2 (.*);
	
	initial
	begin
	  clock = 0;
	  forever #5ns clock = ~clock;
	end
	
	initial
	begin
	  inclk0 = 0;
	  forever #5ns inclk0 = ~inclk0;
	end
	  
	
	initial
	begin
	  reset = 0;
	  trigger = 0;
	  MultiFactor = 8'b00000110; // 6/3 = 2
	  DividFactor = 8'b00000011;
	  
	  #6ns reset = 1;
	  #10ns reset = 0;

    #100ns trigger =1;
    #50ns trigger =0;
    #5us
    
 	  MultiFactor = 8'b00001000; // 
	  DividFactor = 8'b00001000; // 8/8 = 1
    #100ns trigger =1;
    #50ns trigger =0;
    #5us

 	  MultiFactor = 8'b00010100; // 
	  DividFactor = 8'b00000010; // 20/2 = 10
    #100ns trigger =1;
    #50ns trigger =0;
    #5us

 	  MultiFactor = 8'b00000010; // 
	  DividFactor = 8'b00010100; // 2/20 = 1/10
    #100ns trigger =1;
    #50ns trigger =0;

  end
endmodule