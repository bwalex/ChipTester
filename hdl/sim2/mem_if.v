module mem_if #(
  parameter ADDR_WIDTH = 20,
            DATA_WIDTH = 16,
            BE_WIDTH   = DATA_WIDTH/8
)(
  input                   clock,
  input                   reset_n,


  /* Avalon MM master interface to sram_arb */
  output [ADDR_WIDTH-1:0] mem_address,
  output [  BE_WIDTH-1:0] mem_byteenable,

  output                  mem_read,
  input  [DATA_WIDTH-1:0] mem_readdata,

  output                  mem_write,
  output [DATA_WIDTH-1:0] mem_writedata,

  input                   mem_waitrequest,


  /* Avalon MM slave interface for stim */
  input  [ADDR_WIDTH-1:0] stim_address,
  input  [  BE_WIDTH-1:0] stim_byteenable,

  input                   stim_read,
  output [DATA_WIDTH-1:0] stim_readdata,

  output                  stim_waitrequest,


  /* Avalon MM slave interface for check */
  input  [ADDR_WIDTH-1:0] check_address,
  input  [  BE_WIDTH-1:0] check_byteenable,

  input                   check_write,
  input  [DATA_WIDTH-1:0] check_writedata,

  output                  check_waitrequest
);


  reg                     last_slave;
  wire                    sel;
  
  
  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      last_slave <= 1'b0;
    else
      last_slave <= sel;

  /*
   * Currently simply static priority read before write. Can be changed to a
	* round-robin style arbitration later on with help of the last_slave reg.
	*/
  assign sel               = (stim_read) ? 1'b0 : 1'b1;

  assign stim_waitrequest  = (mem_waitrequest || (sel == 1'b1));
  assign check_waitrequest = (mem_waitrequest || (sel == 1'b0));

		
  assign mem_address       =  (sel == 1'b0) ? stim_address    : check_address;
  assign mem_byteenable    =  (sel == 1'b0) ? stim_byteenable : check_byteenable;
  assign mem_writedata     =  check_writedata;
  assign stim_readdata     =  mem_readdata;
  assign mem_read          =  (sel == 1'b0) ? stim_read       : 1'b0;
  assign mem_write         =  (sel == 1'b0) ? 1'b0            : check_write;

endmodule
