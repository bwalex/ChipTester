module dut_if #(
  parameter STF_WIDTH     = 24,
            RTF_WIDTH     = 24,
            REQ_WIDTH     = 3,
            CMD_WIDTH     = 5,
            CMD_EXT_WIDTH = REQ_WIDTH + CMD_WIDTH
            DIF_WIDTH     = REQ_WIDTH + CMD_WIDTH + STF_WIDTH
)(
  input                       clock,
  input                       reset_n,

  /* STIM_FIFO interface */
  input      [ STF_WIDTH-1:0] sfifo_data,
  output                      sfifo_rdreq,
  input                       sfifo_rdempty,

  /* DI_FIFO interface */
  input      [ DIF_WIDTH-1:0] dififo_data,
  output                      dififo_rdreq,
  input                       dififo_rdempty,
  
  /* RES_FIFO interface */
  output     [ RTF_WIDTH-1:0] rfifo_data,
  output                      rfifo_wrreq,
  input                       rfifo_wrfull,

  /* DUT interface */
  output     [ STF_WIDTH-1:0] mosi_data,
  input      [ RTF_WIDTH-1:0] miso_data
);

  parameter DICMD_SETUP_MUXES = 8'b00000001;

  parameter STATE_WIDTH       = 3;
  parameter IDLE              = 3'b000;
  parameter READ_CMD          = 3'b001;

  reg     [  STATE_WIDTH-1:0] state;
  reg     [  STATE_WIDTH-1:0] next_state;

  reg     [    STF_WIDTH-1:0] mosi_data_r;
  reg     [    RTF_WIDTH-1:0] miso_data_r;

  reg     [    STF_WIDTH-1:0] mux_config;

  reg                         sfifo_rdreq_d1;
  reg                         sfifo_rdreq_d2;
  reg                         sfifo_rdreq_d3;
  reg                         sfifo_rdreq_d4;

  reg                         stall_n;
  wire                        clock_gated;

  wire    [CMD_EXT_WIDTH-1:0] cmd;
  wire                        load_mux_config;


  assign sfifo_rdreq =  (~sfifo_rdempty && stall_n);
  assign rfifo_wrreq =  sfifo_rdreq_d3;
  assign rfifo_data  =  miso_data_r;

  /*
   * Generate MUXes for each output to be able to switch the clock to any
   * of the outputs to the DUT.
   */
  genvar i;
  generate
    for (i = 0; i < STF_WIDTH; i = i+1)
      assign mosi_data[i] = mux_config[i] ? clock_gated : mosi_data_r[i];
  endgenerate


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
  assign clock_gated =  (stall_n & clock);

  always @(negedge clock, negedge reset_n)
    if (~reset_n)
      stall_n <= 1'b1;
    else
      stall_n <= ~rfifo_wrfull;


  always @(posedge clock_gated, negedge reset_n)
    if (~reset_n)
      miso_data_r <= 'b0;
    else if (sfifo_rdreq_d2) /* XXX */
      miso_data_r <= miso_data;


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


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      mux_config <= 'b0;
    else if (load_mux_config)
      mux_config <= dififo_data[STF_WIDTH-1:0];


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      state <= IDLE;
    else
      state <= next_state;


  assign cmd              = dififo_data[DIF_WIDTH-1 -: CMD_EXT_WIDTH];

  assign dififo_rdreq     = (state == IDLE)       && (~dififo_rdempty);
  assign load_mux_config  = (state == READ_CMD)   && (cmd == DICMD_SETUP_MUXES);


  always @(
       state
    or dififo_rdempty)
  begin
    next_state    = state;

    case (state)
      IDLE: begin
        if (~dififo_rdempty) begin
          next_state = READ_CMD;
        end
      end

      READ_CMD: begin
        next_state   = IDLE;
      end
    endcase
  end

endmodule
