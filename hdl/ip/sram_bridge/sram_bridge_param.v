module sram_bridge #(
  parameter ADDR_WIDTH = 20,
            DATA_WIDTH = 16,
            BE_WIDTH = DATA_WIDTH/8
)(
  input                   clock,
  input                   nreset,


  /* Avalon MM slave interface */
  input  [ADDR_WIDTH-1:0] address,
  input  [  BE_WIDTH-1:0] byteenable,

  input                   read,
  output [DATA_WIDTH-1:0] readdata,

  input                   write,
  input  [DATA_WIDTH-1:0] writedata,

  output                  waitrequest,


  /* Avalon MM master interface */
  output                  m_clock,
  output [ADDR_WIDTH-1:0] m_address,
  output [  BE_WIDTH-1:0] m_byteenable,

  output                  m_read,
  input  [DATA_WIDTH-1:0] m_readdata,

  output                  m_write,
  output [DATA_WIDTH-1:0] m_writedata,

  input                   m_waitrequest
);


  assign m_clock      = clock;
  assign m_address    = address;
  assign m_byteenable = byteenable;
  assign m_read       = read;
  assign readdata     = m_readdata;
  assign m_write      = write;
  assign m_writedata  = writedata;
  assign waitrequest  = m_waitrequest;

endmodule
