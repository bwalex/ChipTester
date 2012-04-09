module sram_bridge #(
  parameter ADDR_WIDTH = 20
)(
  input                   clock,
  input                   nreset,


  /* Avalon MM slave interface */
  input  [ADDR_WIDTH-1:0] address,
  input  [           1:0] byteenable,

  input                   read,
  output [          15:0] readdata,
  output                  readdataready,

  input                   write,
  input  [          15:0] writedata,

  output                  waitrequest,


  /* Avalon MM master interface */
  output                  m_clock,
  output [ADDR_WIDTH-1:0] m_address,
  output [           1:0] m_byteenable,

  output                  m_read,
  input  [          15:0] m_readdata,
  input                   m_readdataready,

  output                  m_write,
  output [          15:0] m_writedata,

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
  assign readdataready = m_readdataready;

endmodule
