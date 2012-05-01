// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.3
//
// control module - Controls the sub-modules, providing internal signals
// and stores output data in registers, to be read out.

module control #(
  parameter ADDR_WIDTH = 8,
            DATA_WIDTH = 16,
            NREGS = 5
)(
  output logic irq,

  input      [ADDR_WIDTH-1:0] address,

  input                       read,
  output reg [DATA_WIDTH-1:0] readdata,
  output reg                  readdatavalid,

  input                       write,
  input      [DATA_WIDTH-1:0] writedata,

  output logic [DATA_WIDTH-1:0]samples_required,
  output logic [DATA_WIDTH-1:0]select_input,
  output logic enable, nResetOut,
  
  input logic done_flag,
  input logic [DATA_WIDTH-1:0]out_value,
  input logic Clock, nReset
);

timeunit 1ns; timeprecision 10ps;

parameter SEL_INPUT = 'h00 ;
parameter SEL_SAMPLES = 'h01 ;
parameter REG_DATA = 'h02 ;
parameter START = 'h03 ;
parameter REG_IRQ = 'h04 ;
parameter IRQ_TR = 0;

logic [15:0]i ;
logic [DATA_WIDTH-1:0] regfile [NREGS];

assign samples_required = (regfile[SEL_SAMPLES]);
assign select_input = (regfile[SEL_INPUT]);
assign regfile[REG_DATA] = done_flag ? out_value : regfile[REG_DATA] ;
assign irq = (regfile[REG_IRQ] != 'h0);


always_ff @(posedge Clock, negedge nReset)
  if (!nReset) begin
    for (i = 0; i < NREGS; i = i+1)
        regfile[i] <= 'b0;
    end
  else if (done_flag)                    /* Positive edge-triggered IRQ */
      regfile[REG_IRQ][IRQ_TR] <= 'b1;
  else if (write && (address < NREGS))
      regfile[address] <= writedata;
  else if (read && (address == REG_DATA)) /* Clear IRQ reg when data is read */
    begin
      regfile[REG_IRQ] <= 'b0;
      regfile[REG_DATA] <= 'b0;
    end


always @(posedge Clock, negedge nReset)
  if (!nReset)
    enable <= 'b0;
  else if (write && (address == START))
    enable <= 'b1; 
  else if (done_flag)
    enable <= 1'b0;


always @(posedge Clock, negedge nReset)
  if (!nReset)
    readdata <= 'b0;
  else if (read)
    if (address == REG_DATA) readdata <= regfile[address];


always_ff @(posedge Clock, negedge nReset)
  if (!nReset) nResetOut <= 0 ;
  else begin
    if (regfile[REG_IRQ] != 'h0) nResetOut <= 0 ;
    else nResetOut <= 1 ;
  end


always @(posedge Clock, negedge nReset)
  if (!nReset)
    readdatavalid <= 1'b0;
  else
    readdatavalid <= read;

endmodule
