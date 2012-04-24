// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.2
//
// control module - Controls the sub-modules, providing internal signals
// and stores output data in registers, to be read out.

module control (
  output logic irq_out,
  output shortint samples_required,
  output logic [4:0]select_input,
  output logic enable, nResetOut,

  output logic [15:0]mem_write,
  input logic wr_enable,
  input logic [5:0]address,
  input logic [15:0]mem_read,
  input logic rd_enable,
  
  input logic done_flag,
  input logic [9:0]average,
  input logic [9:0]buff [7:0],
  input logic Clock, nReset
);

timeunit 1ns; timeprecision 10ps;

parameter READ_INPUT = 'b100001 ;
parameter READ_SAMPLES = 'b100010 ;

parameter START = 'b101111 ;

parameter REQ_AVG = 'b010001 ;
parameter REQ_BUF0 = 'b010010 ;
parameter REQ_BUF1 = 'b010011 ;
parameter REQ_BUF2 = 'b010100 ;
parameter REQ_BUF3 = 'b010101 ;
parameter REQ_BUF4 = 'b010110 ;
parameter REQ_BUF5 = 'b010111 ;
parameter REQ_BUF6 = 'b011000 ;
parameter REQ_BUF7 = 'b011001 ;

logic [9:0]register_avg ;
logic [9:0]register_buff [7:0] ;

shortint count, i ;

always_ff @(posedge Clock, negedge nReset)
  if (!nReset) begin
    samples_required <= 0 ;
    select_input <= 0 ;
    enable <= 0 ;
    mem_write <= 0 ;
    irq_out <= 0 ;
    nResetOut <= 0 ;
  end
  else begin
  if (done_flag) begin
    irq_out <= 1 ;
    enable <= 0 ;
  end
  if (rd_enable) case (address)
      READ_INPUT : select_input <= mem_read[4:0] ;
      READ_SAMPLES : samples_required <= mem_read[9:0] ;
      START : enable <= 1 ;
    endcase
  if (wr_enable) begin
    case (address)
      REQ_AVG : mem_write <= register_avg ;
      REQ_BUF0 : mem_write <= register_buff[0] ;
      REQ_BUF1 : mem_write <= register_buff[1] ;
      REQ_BUF2 : mem_write <= register_buff[2] ;
      REQ_BUF3 : mem_write <= register_buff[3] ;
      REQ_BUF4 : mem_write <= register_buff[4] ;
      REQ_BUF5 : mem_write <= register_buff[5] ;
      REQ_BUF6 : mem_write <= register_buff[6] ;
      REQ_BUF7 : mem_write <= register_buff[7] ;
    endcase
    irq_out <= 0 ;
    end
  if (irq_out) nResetOut <= 0 ;
  else nResetOut <= 1 ;
  end
    
    
always_comb
  if (!nReset) begin
    register_avg <= 0 ;
    for (i = 0; i < 8; i = i+1) register_buff[i] <= 0 ;
  end
  else if (done_flag) begin
    register_avg <= average ;
    register_buff <= buff ;
  end

endmodule
