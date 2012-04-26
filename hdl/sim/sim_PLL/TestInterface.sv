`timescale 1 ps / 1 ps
module TestInterface;
  parameter	FILELOCATION_AND_NAME = "G:/Archive/New folder/quartus/PLL.mif" ;
  parameter FILENAME = "PLL.mif";
	logic	  inclk0;
	logic   clock;
	logic   reset_n;
	logic   trigger;
	logic   [15:0]PLL_DATA;
	logic   [7:0] MultiFactor;
  logic   [7:0] DividFactor;
	logic	c0;
	logic	locked;

	logic   busy;
	logic   [8:0]  data_out;
	logic	stable_reconfig;
	
	PLL_INTERFACE #(
	.FILELOCATION_AND_NAME       (FILELOCATION_AND_NAME),
	.FILENAME					 (FILENAME)
	)PI2 (.*);
	
	assign PLL_DATA [15:8] = MultiFactor;
	assign PLL_DATA [ 7:0] = DividFactor;
	
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
	  reset_n = 1;
	  trigger = 0;
	  MultiFactor = 8'b00000110; // 6/3 = 2
	  DividFactor = 8'b00000011;
	  
	  #6ns reset_n = 0;
	  #10ns reset_n = 1;

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