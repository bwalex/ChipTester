module dut_if #(
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

  /* DUT interface */
  output     [ STF_WIDTH-1:0] mosi_data;
  input      [ RTF_WIDTH-1:0] miso_data;
);

  reg        [ STF_WIDTH-1:0] mosi_data_r;
  reg        [ RTF_WIDTH-1:0] miso_data_r;

  reg                         sfifo_rdreq_d1;
  reg                         sfifo_rdreq_d2;
  reg                         sfifo_rdreq_d3;
  reg                         sfifo_rdreq_d4;

  reg                         stall;
  wire                        clock_gated;

  
  assign mosi_data   =  mosi_data_r;

  assign sfifo_rdreq =  (~sfifo_rdempty && ~stall);
  assign rfifo_wrreq =  sfifo_rdreq_d4;
  assign rfifo_data  =  miso_data_r;


  /*
   * Clock gating as advised by Altera: single two-input AND gate with
   * ungated clock input and control signal.
   * The control signal is registered with a falling edge sensitive FF,
   * with same clock as the one to be gated.
   *
   * Gating is applied when the result FIFO is full, so we don't lose
   * any results.
   *
   * The gated clock is also the one applied to the DUT/CUT.
   */
  assign clock_gated =  (stall & clock);

  always @(negedge clock, negedge reset_n)
    if (~reset_n)
      stall <= 1'b0;
    else
      stall <= rfifo_wrfull;


  always @(posedge clock_gated, negedge reset_n)
    if (~reset_n)
      miso_data_r <= 'b0;
    else if (sfifo_rdreq_d3)
      miso_data_r = miso_data;


  always @(posedge clock_gated, negedge reset_n)
    if (~reset_n)
      mosi_data_r <= 'b0;
    else if (sfifo_rdreq_d1)
      mosi_data_r <= sfifo_data;


  always @(posedge clock_gated, negedge reset_n)
    if (~reset_n) begin
      sfifo_rdreq_d1 <= 1'b0;
      sfifo_rdreq_d2 <= 1'b0;
      sfifo_rdreq_d3 <= 1'b0;
      sfifo_rdreq_d4 <= 1'b0;
    end
    else begin
      sfifo_rdreq_d1 <= sfifo_rdreq;
      sfifo_rdreq_d2 <= sfifo_rdreq_d1;
      sfifo_rdreq_d3 <= sfifo_rdreq_d2;
      sfifo_rdreq_d4 <= sfifo_rdreq_d3;
    end

endmodule
