// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.3
//
// control module - Controls the sub-modules, providing internal signals
// and stores output data in registers, to be read out.

module fc_control #(
  parameter ADDR_WIDTH = 8,
            DATA_WIDTH = 32,
            NREGS = 6
)(
  input                         clock,
  input                         nreset,

  input        [ADDR_WIDTH-1:0] address,

  input                         read,
  output reg   [DATA_WIDTH-1:0] readdata,
  output reg                    readdatavalid,

  input                         write,
  input        [DATA_WIDTH-1:0] writedata,

  output                        irq,

  output       [DATA_WIDTH-1:0] cycle_count,
  output       [DATA_WIDTH-1:0] input_select,
  output logic                  busy,
  output logic                  enable,
 
  input                         done,
  input        [DATA_WIDTH-1:0] edge_count
);

  timeunit       1ns;
  timeprecision 10ps;

  logic        [DATA_WIDTH-1:0] regfile[NREGS];
  logic                         done_d1;

  parameter REG_INPUT_SEL  = 'h00;
  parameter REG_EDGECOUNT  = 'h02;
  parameter REG_CYCLECOUNT = 'h03;
  parameter REG_IRQ        = 'h04;
  parameter REG_MAGIC      = 'h05;

  // fake register
  parameter REG_ENABLE     = 'h0A;


  assign cycle_count  =  regfile[REG_CYCLECOUNT];
  assign input_select =  regfile[REG_INPUT_SEL];
  assign irq          = (regfile[REG_IRQ] != 'h0);


  integer i;

  always @(posedge clock, negedge nreset)
    if (~nreset) begin
      for (i = 0; i < NREGS; i = i+1)
        regfile[i] <= 'b0;

      // Assign default set values
      regfile[REG_MAGIC]     <= 'h0A;
    end
    else if (done && ~done_d1) begin /* Positive edge-triggered IRQ */
      regfile[REG_EDGECOUNT] <= edge_count;
      regfile[REG_IRQ][0]    <= 1'b1;
    end
    else if (write && (address < NREGS))
      regfile[address]       <= writedata;
    else if (read && (address == REG_IRQ)) /* Clear IRQ reg when read */
      regfile[REG_IRQ]       <= 'b0;


  always @(posedge clock, negedge nreset)
    if (~nreset)
      enable <= 1'b0;
    else if (write && (address == REG_ENABLE))
      enable <= writedata[0]; 
    else if (enable)
      enable <= 1'b0;


  always @(posedge clock, negedge nreset)
    if (~nreset)
      readdata <= 'b0;
    else if (read)
      if (address < NREGS)
        readdata <= regfile[address];


  always @(posedge clock, negedge nreset)
    if (~nreset)
      readdatavalid <= 1'b0;
    else
      readdatavalid <= read;


  always @(posedge clock, negedge nreset)
    if (~nreset)
      done_d1 <= 1'b0;
    else
      done_d1 <= done;


  always @(posedge clock, negedge nreset)
    if (~nreset)
      busy <= 1'b0;
    else if (enable)
      busy <= 1'b1;
    else if (done)
      busy <= 1'b0;

endmodule
