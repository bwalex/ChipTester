module loopback #(
  parameter STF_WIDTH  = 24,
            RTF_WIDTH  = 24
)(
  input                       clock,
  input                       reset_n,

  /* STIM_FIFO interface */
  input      [ STF_WIDTH-1:0] sfifo_data,
  output                      sfifo_rdreq,
  input                       sfifo_rdempty,
  
  /* RES_FIFO interface */
  output     [ RTF_WIDTH-1:0] rfifo_data,
  output                      rfifo_wrreq,
  input                       rfifo_wrfull
);

  reg        [ RTF_WIDTH-1:0] data;
  reg                         sfifo_rdreq_d1;
  reg                         sfifo_rdreq_d2;


  assign sfifo_rdreq = ~sfifo_rdempty;
  assign rfifo_wrreq =  sfifo_rdreq_d2;
  assign rfifo_data  =  data;

  always @(posedge clock, negedge reset_n)
    if (~reset_n) begin
      sfifo_rdreq_d1 <= 1'b0;
      sfifo_rdreq_d2 <= 1'b0;
    end
    else begin
      sfifo_rdreq_d1 <= sfifo_rdreq;
      sfifo_rdreq_d2 <= sfifo_rdreq_d1;
    end


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      data <= 'b0;
    else if (sfifo_rdreq)
      data <= sfifo_data;

endmodule
