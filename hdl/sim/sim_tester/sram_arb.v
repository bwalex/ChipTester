// XXX: revise Avalon MM standard to see if stuff is held stable long enough
module sram_arb #(
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
  output [ADDR_WIDTH-1:0] sram_address,
  inout  [DATA_WIDTH-1:0] sram_data,
  output                  sram_ce_n,  /* Chip enable        */
  output                  sram_oe_n,  /* Output enable      */
  output                  sram_we_n,  /* Write enable       */
  output [  BE_WIDTH-1:0] sram_be_n,  /* Byte enable/select */


  /* Avalon MM slave interface for sopc */
  input  [ADDR_WIDTH-1:0] sopc_address,
  input  [  BE_WIDTH-1:0] sopc_byteenable,

  input                   sopc_read,
  output [DATA_WIDTH-1:0] sopc_readdata,

  input                   sopc_write,
  input  [DATA_WIDTH-1:0] sopc_writedata,

  output                  sopc_waitrequest,


  /* Avalon MM slave interface for test runner */
  input  [ADDR_WIDTH-1:0] tr_address,
  input  [  BE_WIDTH-1:0] tr_byteenable,

  input                   tr_read,
  output [DATA_WIDTH-1:0] tr_readdata,

  input                   tr_write,
  input  [DATA_WIDTH-1:0] tr_writedata,

  output                  tr_waitrequest
);


  /* Internal MUX'ed (arbitrated) Avalon-MM slave signals */
  wire   [ADDR_WIDTH-1:0] address;
  wire   [  BE_WIDTH-1:0] byteenable;
  wire                    read;
  wire   [DATA_WIDTH-1:0] readdata;
  wire                    write;
  wire   [DATA_WIDTH-1:0] writedata;



  assign address          =  (sel == 1'b0) ? sopc_address    : tr_address;
  assign byteenable       =  (sel == 1'b0) ? sopc_byteenable : tr_byteenable;
  assign writedata        =  (sel == 1'b0) ? sopc_writedata  : tr_writedata;
  assign read             =  (sel == 1'b0) ? sopc_read       : tr_read;
  assign write            =  (sel == 1'b0) ? sopc_write      : tr_write;
  assign sopc_waitrequest = ~(sel == 1'b0);
  assign tr_waitrequest   = ~(sel == 1'b1);


  assign sopc_readdata    = readdata;
  assign tr_readdata      = readdata;


  assign sram_ce_n     = 1'b0;
  assign sram_oe_n     = (~read  || write);
  assign sram_we_n     = (~write || read);
  assign sram_be_n     = ~byteenable;


  assign sram_address  = address;
  assign sram_data     = (write && ~read ) ? writedata : 'bz;
  assign readdata      = sram_data;
endmodule
