module dut_if #(
  parameter STF_WIDTH     = 24,
            RTF_WIDTH     = 24,
            REQ_WIDTH     = 3,
            CMD_WIDTH     = 5,
            CYCLE_RANGE   = 5,
            CMD_EXT_WIDTH = REQ_WIDTH + CMD_WIDTH,
            DIF_WIDTH     = REQ_WIDTH + CMD_WIDTH + STF_WIDTH
)(
  input                            clock,
  input                            reset_n,

  /* STIM_FIFO interface */
  input [ STF_WIDTH+CYCLE_RANGE:0] sfifo_data,
  output                           sfifo_rdreq,
  input                            sfifo_rdempty,


  /* DI_FIFO interface */
  input [ DIF_WIDTH-1:0]           dififo_data,
  output                           dififo_rdreq,
  input                            dififo_rdempty,

  /* RES_FIFO interface */
  output [ RTF_WIDTH-1:0]          rfifo_data,
  output                           rfifo_wrreq,
  input                            rfifo_wrfull,

  /* DUT interface */
  output [ STF_WIDTH-1:0]          mosi_data,
  input [ RTF_WIDTH-1:0]           miso_data
);

  parameter DICMD_SETUP_MUXES = 8'b00000001;
  parameter DICMD_TRGMASK     = 8'b00000010;

  parameter STATE_WIDTH       = 3;
  parameter IDLE              = 3'b000;
  parameter READ_CMD          = 3'b001;
  parameter DELAY             = 3'b010;
  parameter TRIG_STANDBY      = 3'b011;


  reg     [  STATE_WIDTH-1:0] state;
  reg     [  STATE_WIDTH-1:0] next_state;

  wire    [    STF_WIDTH-1:0] mosi_data_int;

  reg     [    STF_WIDTH-1:0] mux_config;

  reg                         stall_n;

  reg      [ CYCLE_RANGE-1:0] cycle_counter;
  reg      [   RTF_WIDTH-1:0] trigger_mask;

  wire                        clock_gated;

  wire    [CMD_EXT_WIDTH-1:0] cmd;
  wire                        load_mux_config;
  wire                        load_trigger_mask;


  wire    [    STF_WIDTH-1:0] test_vector;
  wire                        cycle_info;
  wire                        mode_select;
  /* post pll reconfig clock */
  wire                        post_pll_clock;

  wire                        cycle_timed;
  wire                        trigger_match;
  wire                        stall_fetch;
  wire                        stall_execute;
  wire                        stall_writeback;
  wire                        stall_execute_o;
  wire                        stall_writeback_o;
  wire                        bubble_fetch_execute;
  wire                        bubble_execute_writeback;
  wire                        mode_execute_writeback;
  wire [CYCLE_RANGE-1:0]      count_execute_writeback;
  wire [RTF_WIDTH-1:0]        result_execute_writeback;
  wire                        timeout_execute_writeback;


  dut_fetch dut_fetch(
                      // Outputs
                      .rd_req           (sfifo_rdreq),
                      .bubble_r         (bubble_fetch_execute),
                      // Inputs
                      .clock            (clock),
                      .reset_n          (reset_n),
                      .rd_empty         (sfifo_rdempty),
                      .stall            (stall_fetch)
  );


  dut_execute dut_execute(
                          // Outputs
                          .mosi_data            (mosi_data_int),
                          .stall_o              (stall_execute_o),
                          .bubble_r             (bubble_execute_writeback),
                          .mode_r               (mode_execute_writeback),
                          .timeout_r            (timeout_execute_writeback),
                          .result_r             (result_execute_writeback),
                          .cycle_count_r        (count_execute_writeback),
                          // Inputs
                          .clock                (clock),
                          .reset_n              (reset_n),
                          .trigger_mask         (trigger_mask),
                          .miso_data            (miso_data),
                          .stall                (stall_execute),
                          .bubble               (bubble_fetch_execute),
                          .rd_data              (sfifo_data)
  );


  dut_writeback dut_writeback(
                              // Outputs
                              .wr_req_r         (rfifo_wrreq),
                              .wr_data_r        (rfifo_data),
                              .stall_o          (stall_writeback_o),
                              // Inputs
                              .clock            (clock),
                              .reset_n          (reset_n),
                              .wr_full          (rfifo_wrfull),
                              .bubble           (bubble_execute_writeback),
                              .mode             (mode_execute_writeback),
                              .timeout          (timeout_execute_writeback),
                              .result           (result_execute_writeback),
                              .cycle_count      (count_execute_writeback)
  );



  assign stall_fetch    = stall_execute_o | stall_writeback_o;
  assign stall_execute  = stall_writeback_o;

  /*
   * Generate MUXes for each output to be able to switch the clock to any
   * of the outputs to the DUT.
   */
  genvar i;
  generate
    for (i = 0; i < STF_WIDTH; i = i+1) begin : OUT_MUXES
      assign mosi_data[i] = mux_config[i] ? clock_gated : mosi_data_int[i];
    end
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
   *
   * NOTE: A better solution would be to use normal register enables
   *       internally on the FPGA and a DDR I/O register (ALTDDIO)
   *       on all the output pins.
   */
  assign post_pll_clock = clock; /*switch between pll_recongfig and original clock*/

  //XXX: need some pll signal, but not a specific pll_clock, that should be the normal clock.
  assign clock_gated =  (stall_n & post_pll_clock);

  always @(negedge clock, negedge reset_n)
    if (~reset_n)
      stall_n <= 1'b1;
    else
      stall_n <= ~rfifo_wrfull;


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


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
	    trigger_mask <= 'b0;
	  else if (load_trigger_mask)
	    trigger_mask <= dififo_data[STF_WIDTH-1:0];




  assign cmd                = dififo_data[DIF_WIDTH-1 -: CMD_EXT_WIDTH];

  assign dififo_rdreq       = (state == IDLE)       && (~dififo_rdempty);
  assign load_mux_config    = (state == READ_CMD)   && (cmd == DICMD_SETUP_MUXES);
  assign load_trigger_mask  = (state == READ_CMD)   && (cmd == DICMD_TRGMASK);


  assign cycle_timed        = (cycle_counter == cycle_info);

  assign trigger_match      = miso_data & trigger_mask;

  always @(
           state
           or dififo_rdempty)
    begin
      next_state    = state;

      case (state)
        IDLE: begin
          if (~dififo_rdempty)
            next_state = READ_CMD;
        end

        READ_CMD: begin
          next_state   = IDLE;
        end
      endcase
    end

endmodule










module dut_fetch(
  input      clock,
  input      reset_n,
  input      rd_empty,
  output     rd_req,

  /* Pipeline signals */
  input      stall,
  output reg bubble_r
);

   assign rd_req = (~rd_empty & ~stall);

   always @(posedge clock, negedge reset_n)
     if (~reset_n)
       bubble_r <= 1'b1;
     else
       bubble_r <= ~rd_req; //rd_req;
endmodule



module dut_execute #(
  parameter STF_WIDTH   = 24,
            RTF_WIDTH   = 24,
            CYCLE_RANGE = 5,
            FIFO_WIDTH  = STF_WIDTH + CYCLE_RANGE + 1
)(
  input                        clock,
  input                        reset_n,
  input [RTF_WIDTH-1:0]        trigger_mask,
  input [RTF_WIDTH-1:0]        miso_data,
  output [STF_WIDTH-1:0]       mosi_data,
  input [FIFO_WIDTH-1:0]       rd_data,

  input                        stall,
  input                        bubble,
  output                       stall_o,
  output reg                   bubble_r,

  output reg                   mode_r,
  output reg                   timeout_r,
  output reg [RTF_WIDTH-1:0]   result_r,
  output reg [CYCLE_RANGE-1:0] cycle_count_r
);

  wire                         trigger_match;
  wire                         counter_match;

  wire                         st_mode;
  wire [CYCLE_RANGE-1:0]       cycle_count;
  wire [STF_WIDTH-1:0]         st_data;
  

  
  parameter STATE_WIDTH       = 2;
  parameter IDLE              = 2'b00;
  parameter WAIT_COUNT        = 2'b01;
  parameter WAIT_TRIGGER      = 2'b10;


  reg [STATE_WIDTH-1:0]        state;
  reg [STATE_WIDTH-1:0]        next_state; /* comb */


  assign st_mode        = rd_data[0];
  assign cycle_count    = rd_data[CYCLE_RANGE -: CYCLE_RANGE];
  assign st_data        = rd_data[STF_WIDTH+CYCLE_RANGE -: STF_WIDTH];
  
  
  assign counter_match  = (cycle_count_r == cycle_count);
  assign trigger_match  = ((miso_data & trigger_mask) == miso_data); /* AND'ing trigger mask */

  assign stall_o        = (next_state != IDLE);

  assign mosi_data      = st_data;

  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      state <= IDLE;
    else if (~stall)
      state <= next_state;

  always @(
           state,
           st_mode,
           cycle_count,
           trigger_match,
           counter_match
           ) begin

    next_state = state;

    case (state)
      IDLE: begin
        if (st_mode == 1'b0 && cycle_count != 0)
          next_state = WAIT_COUNT;
        else if (st_mode == 1'b1 && cycle_count > 0 && ~trigger_match)
          next_state = WAIT_TRIGGER;
      end

      WAIT_COUNT: begin
        if (counter_match)
          next_state = IDLE;
      end

      WAIT_TRIGGER: begin
        if (counter_match /* timeout */ || trigger_match)
          next_state = IDLE;
      end
    endcase
  end // always @ (...


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      bubble_r <= 1'b1;
    else if (~stall)
      bubble_r <= bubble | stall_o;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      cycle_count_r <= 0;
    else if (next_state == IDLE && ~stall)
      cycle_count_r <= 0;
    else if (~stall)
      cycle_count_r <= cycle_count_r + 1;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      timeout_r <= 1'b0;
    else if (~stall)
      timeout_r <= counter_match;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      result_r <= 0;
    else if (~stall)
      result_r <= miso_data;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      mode_r <= 1'b0;
    else if (~stall)
      mode_r <= st_mode;
endmodule






module dut_writeback #(
  parameter RTF_WIDTH   = 24,
            CYCLE_RANGE = 5,
            FIFO_WIDTH  = RTF_WIDTH
            //FIFO_WIDTH  = RTF_WIDTH + CYCLE_RANGE + 1
)(
  input                       clock,
  input                       reset_n,
  input                       wr_full,
  output reg                  wr_req_r,
  output reg [FIFO_WIDTH-1:0] wr_data_r,

  input                       bubble,
  output                      stall_o,

  input                       mode,
  input                       timeout,
  input [RTF_WIDTH-1:0]       result,
  input [CYCLE_RANGE-1:0]     cycle_count
);

  assign stall_o = wr_full;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      wr_req_r <= 1'b0;
    else if (~bubble & ~wr_full)
      wr_req_r <= 1'b1;
    else
      wr_req_r <= 1'b0;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      wr_data_r <= 1'b0;
    else if (~bubble & ~wr_full)
      wr_data_r <= { result };
endmodule // dut_writeback
