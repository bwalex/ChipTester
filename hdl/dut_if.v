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

  reg     [    STF_WIDTH-1:0] mosi_data_r;
  reg     [    RTF_WIDTH-1:0] miso_data_r;

  reg     [    STF_WIDTH-1:0] mux_config;

  reg                         sfifo_rdreq_d1;
  reg                         sfifo_rdreq_d2;
  reg                         sfifo_rdreq_d3;
  reg                         sfifo_rdreq_d4;

  reg                         stall_n;

  reg      [ CYCLE_RANGE-1:0] cycle_counter;
  reg      [   STF_WIDTH-1:0] trigger_mask;
  
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
                       

  assign test_vector = sfifo_data [STF_WIDTH+CYCLE_RANGE -: STF_WIDTH];
  assign cycle_info  = sfifo_data [CYCLE_RANGE : 1];
  assign mode_select = sfifo_data [0];

  assign sfifo_rdreq =  (~sfifo_rdempty && stall_n);
  assign rfifo_wrreq =  sfifo_rdreq_d3;
  assign rfifo_data  =  miso_data_r;

  /*
   * Generate MUXes for each output to be able to switch the clock to any
   * of the outputs to the DUT.
   */
  genvar i;
  generate
    for (i = 0; i < STF_WIDTH; i = i+1) begin : OUT_MUXES
      assign mosi_data[i] = mux_config[i] ? clock_gated : mosi_data_r[i];
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


  always @(posedge clock_gated, negedge reset_n)
    if (~reset_n)
      miso_data_r <= 'b0;
    else if (sfifo_rdreq_d2) /* XXX */
      miso_data_r <= miso_data;


  always @(posedge clock_gated, negedge reset_n)
    if (~reset_n)
      mosi_data_r <= 'b0;
    else if (sfifo_rdreq_d1)
      mosi_data_r <= test_vector;


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
		
  always @(posedge clock, negedge reset_n)
    if (~reset_n)
	   cycle_counter <= 5'b00000;
	 else if (state == IDLE)
	   cycle_counter <= 5'b00000;
	 else if (state == DELAY && cycle_counter < cycle_info)
	   cycle_counter <= cycle_counter +1;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
	   trigger_mask <= 'b0;
	 else if (load_trigger_mask)
	   trigger_mask <= dififo_data[STF_WIDTH-1:0];
		

  assign cmd              = dififo_data[DIF_WIDTH-1 -: CMD_EXT_WIDTH];

  assign dififo_rdreq     = (state == IDLE)       && (~dififo_rdempty);
  assign load_mux_config  = (state == READ_CMD)   && (cmd == DICMD_SETUP_MUXES);
  assign load_trigger_mask= (state == READ_CMD)   && (cmd == DICMD_TRGMASK);

  assign cycle_timed = (cycle_counter == cycle_info);
  
  assign trigger_match    = miso_data & trigger_mask;

  always @(
       state
    or dififo_rdempty)
  begin
    next_state    = state;
	 
    case (state)
      IDLE: begin
        if (~dififo_rdempty)
          next_state = READ_CMD;
		    else if (cycle_info > 5'b00000)
		      next_state = DELAY;
		    else if (mode_select == 1)
		      next_state = TRIG_STANDBY;
		  
      end

      READ_CMD: begin
        next_state   = IDLE;
      end
		
		  DELAY: begin
		     if (cycle_timed)
		       next_state   = READ_CMD;
		  end
		  
		  TRIG_STANDBY: begin
		     if (trigger_match)
		       next_state   = READ_CMD;
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
       bubble_r <= rd_empty;
endmodule




module dut_decode #(
  parameter STF_WIDTH   = 24,
            CYCLE_RANGE = 5,
            FIFO_WIDTH  = STF_WIDTH + CYCLE_RANGE + 1
)(
  input                        clock,
  input                        reset_n,
  input [FIFO_WIDTH-1:0]       rd_data,

  input                        stall,
  input                        bubble,
  output                       stall_o,
  output reg                   bubble_r,

  output reg                   st_mode_r,
  output reg [CYCLE_RANGE-1:0] cycle_count_r,
  output reg [STF_WIDTH-1:0]   st_data_r   
);

   assign stall_o = 0;

   
   always @(posedge clock, negedge reset_n)
     if (~reset_n)
       bubble_r <= 1'b1;
     else
       bubble_r <= bubble;

   
   always @(posedge clock, negedge reset_n)
     if (~reset_n)
       st_mode_r <= 1'b0;
     else if (~stall & ~bubble)
       st_mode_r <= rd_data[0];

   
   always @(posedge clock, negedge reset_n)
     if (~reset_n)
       cycle_count_r <= 0;
     else if (~stall & ~bubble)
       cycle_count_r <= rd_data[CYCLE_RANGE -: CYCLE_RANGE];


    always @(posedge clock, negedge reset_n)
     if (~reset_n)
       st_data_r <= 0;
     else if (~stall & ~bubble)
       st_data_r <= rd_data[STF_WIDTH+CYCLE_RANGE -: STF_WIDTH];
endmodule // dut_decode











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

  input                        stall,
  input                        bubble,
  output                       stall_o,
  output reg                   bubble_r,

  input                        st_mode,
  input [CYCLE_RANGE-1:0]      cycle_count,
  input [STF_WIDTH-1:0]        st_data,

  output reg                   mode_r,
  output reg                   timeout_r,
  output reg [RTF_WIDTH-1:0]   result_r,
  output reg [CYCLE_RANGE-1:0] cycle_count_r 
);

   wire                        trigger_match;
   wire                        counter_match;

   
   parameter STATE_WIDTH       = 2;
   parameter IDLE              = 2'b00;
   parameter WAIT_COUNT        = 2'b01;
   parameter WAIT_TRIGGER      = 2'b10;


   reg [STATE_WIDTH-1:0]       state;
   reg [STATE_WIDTH-1:0]       next_state; /* comb */


   assign counter_match   = (cycle_count_r == cycle_count);
   assign trigger_match   = ((miso_data & trigger_mask) == miso_data); /* AND'ing trigger mask */

   assign stall_o =   (next_state != IDLE);

   assign mosi_data =  st_data;

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
     else
       bubble_r <= bubble | stall_o;


   always @(posedge clock, negedge reset_n)
     if (~reset_n)
       cycle_count_r <= 0;
     else if (state == IDLE && ~stall)
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

   
   always @(posedge clock, negedge reset_n)
     if (~reset_n)
       wr_data_r <= 1'b0;
     else if (~bubble & ~wr_full)
       wr_data_r <= { result };
endmodule // dut_decode
