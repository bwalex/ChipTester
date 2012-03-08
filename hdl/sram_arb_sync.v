module sram_arb_sync #(
  parameter ADDR_WIDTH = 20,
            DATA_WIDTH = 16,
            SEL_WIDTH  = 1,
            BE_WIDTH   = DATA_WIDTH/8
)(
  input                   clock,
  input                   reset_n,


  /* Master select */
  input  [ SEL_WIDTH-1:0] sel,


  /* SRAM interface */
  output reg [ADDR_WIDTH-1:0] sram_address,
  inout      [DATA_WIDTH-1:0] sram_data,
  output                      sram_ce_n,  /* Chip enable        */
  output reg                  sram_oe_n,  /* Output enable      */
  output reg                  sram_we_n,  /* Write enable       */
  output reg [  BE_WIDTH-1:0] sram_be_n,  /* Byte enable/select */


  /* Avalon MM slave interface for sopc */
  input      [ADDR_WIDTH-1:0] sopc_address,
  input      [  BE_WIDTH-1:0] sopc_byteenable,

  input                       sopc_read,
  output     [DATA_WIDTH-1:0] sopc_readdata,
  output                      sopc_readdataready,

  input                       sopc_write,
  input      [DATA_WIDTH-1:0] sopc_writedata,

  output                      sopc_waitrequest,


  /* Avalon MM slave interface for test runner */
  input      [ADDR_WIDTH-1:0] tr_address,
  input      [  BE_WIDTH-1:0] tr_byteenable,

  input                       tr_read,
  output     [DATA_WIDTH-1:0] tr_readdata,
  output                      tr_readdataready,

  input                       tr_write,
  input      [DATA_WIDTH-1:0] tr_writedata,

  output                      tr_waitrequest
);


  /* Internal MUX'ed (arbitrated) Avalon-MM slave signals */
  wire   [ADDR_WIDTH-1:0] address;
  wire   [  BE_WIDTH-1:0] byteenable;
  wire                    read;
  wire   [DATA_WIDTH-1:0] readdata;
  wire                    write;
  wire   [DATA_WIDTH-1:0] writedata;

  reg                     readdataready_r;
  reg    [DATA_WIDTH-1:0] readdata_r;
  reg    [DATA_WIDTH-1:0] writedata_r;
  wire   [  BE_WIDTH-1:0] sram_be_int_n;
  wire                    sram_oe_int_n;
  wire                    sram_we_int_n;


  assign address          =  (sel == 1'b0) ? sopc_address    : tr_address;
  assign byteenable       =  (sel == 1'b0) ? sopc_byteenable : tr_byteenable;
  assign writedata        =  (sel == 1'b0) ? sopc_writedata  : tr_writedata;
  assign read             =  (sel == 1'b0) ? sopc_read       : tr_read;
  assign write            =  (sel == 1'b0) ? sopc_write      : tr_write;
  assign sopc_waitrequest = ~(sel == 1'b0);
  assign tr_waitrequest   = ~(sel == 1'b1);

  assign sopc_readdataready = (sel == 1'b0) ? readdataready_r : 1'b0;
  assign tr_readdataready   = (sel == 1'b1) ? readdataready_r : 1'b0;

  assign tr_readdata      = readdata_r;
  assign sopc_readdata    = readdata_r;

  assign sram_ce_n     = 1'b0;
  assign sram_oe_int_n = (~read  || write);
  assign sram_we_int_n = (~write || read);
  assign sram_be_int_n = ~byteenable;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      sram_address <= 'b0;
    else if (read || write)
      sram_address <= address;

  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      writedata_r <= 'b0;
    else if (write)
      writedata_r <= writedata;

  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      readdata_r <= 'b0;
    else
      readdata_r <= sram_data;//readdata;

  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      readdataready_r <= 1'b0;
    else
      readdataready_r <= ~sram_oe_n;

  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      sram_be_n <= 'b1;
    else
      sram_be_n <= sram_be_int_n;

  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      sram_oe_n <= 1'b1;
    else
      sram_oe_n <= sram_oe_int_n;

  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      sram_we_n <= 1'b1;
    else
      sram_we_n <= sram_we_int_n;

  assign sram_data     = (sram_we_n) ? 'bz : writedata_r;
  //assign readdata      = sram_data;
endmodule
