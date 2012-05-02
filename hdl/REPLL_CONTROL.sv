/*
 * The PLL's frequency can be configured using 3 different parameters:
 *   N, which is the divider in the feedback path; f_ref = f_in/N
 *   M, which is the multiplier in the forward path; f_vco = f_ref * M
 *   C, which is the post-divider; f_out = f_vco / C
 *
 * The most important consideration here is that the VCO range of the
 * Cyclone IV PLLs is limited to 600 MHz - 1.3 GHz. So a choice of M and N
 * that reduces f_vco to under 600 MHz will cause the PLL not to lock.
 *
 * The Quartus software actually seems to have a different idea about the
 * lower range of f_vco; it goes down to 307 MHz by manual settings and
 * 400 MHz using automatic settings.
 *
 * So the only real way of achieving the desired frequencies at run time
 * is by varying the post-divider C, which is split up into high and low
 * counts (which in theory would allow to change the duty cycle).
 *
 * Changing only the post-divider has the added advantage that the loop
 * won't lose lock (in theory).
 */
module REPLL_CONTROL(
  input             sys_reset,
  input             clock_ctr,
  input             trigger,
  input             busy_ctr,
  input      [7:0]  pll_m,
  input      [7:0]  pll_n,
  input      [7:0]  pll_c,
  output reg [2:0]  counter_param_ctr,
  output reg [3:0]  counter_type_ctr,
  output reg        reset_ctr,
  output reg        pll_areset_in_ctr,
  output            write_param_ctr,
  output reg        reconfig_ctr,
  output reg        pll_pfdena,
  output reg        pll_read_param,
  output reg [8:0]  config_data_in,
  output            idle_state
);

  parameter Idle         = 4'b0000;
  parameter SetM         = 4'b0001;
  parameter SetN         = 4'b0010;
  parameter SetC0H       = 4'b0100;
  parameter SetC0L       = 4'b0101;
  parameter Reconfig     = 4'b1000;
  parameter Busy         = 4'b1111;
  parameter ResetPLL     = 4'b1100;
  parameter ResetCTR     = 4'b1110;

  reg [7:0] config_data_in_int;
  reg [2:0] counter_param_ctr_int;
  reg [3:0] counter_type_ctr_int;
  reg       write_param_ctr_int;
  reg       write_param_ctr_d0;
  reg       write_param_ctr_d1;
  wire      busy;

  reg [3:0] state;
  reg [3:0] next_state;


  assign pll_pfdena     = 1;
  assign pll_read_param = 0;

  assign idle_state      = (state == Idle);

  /*
   * Weird as it is, the ALTPLL_RECONFIG module needs the index ports
   * counter_type and counter_param set up one cycle before asserting
   * write_param.
   * So we simply delay the external write_param by one cycle with
   * respect to the internal one and adjust our internal busy signal
   * accordingly.
   */
  always @(posedge clock_ctr, posedge sys_reset)
    if (sys_reset)
      write_param_ctr_d1 <= 1'b0;
    else
      write_param_ctr_d1 <= write_param_ctr_d0;

  assign write_param_ctr = write_param_ctr_d1;
  assign busy            = write_param_ctr_d0 | write_param_ctr_d1 | busy_ctr;



  always @(posedge clock_ctr, posedge sys_reset)
    if (sys_reset) begin
      config_data_in      <= 9'b0;
      write_param_ctr_d0  <= 1'b0;
      counter_type_ctr    <= 4'd0;
      counter_param_ctr   <= 3'd0;
    end 
    else if (write_param_ctr_int) begin
      write_param_ctr_d0  <= 1'b1;
      config_data_in[  8] <= 1'b0;
      config_data_in[7:0] <= config_data_in_int;
      counter_type_ctr    <= counter_type_ctr_int;
      counter_param_ctr   <= counter_param_ctr_int;
    end
    else begin
      write_param_ctr_d0  <= 1'b0;
    end


  always @(posedge clock_ctr, posedge sys_reset)
    if (sys_reset)
      state <= ResetPLL;
    else
      state <= next_state;


  always @(
      state
   or busy
   or trigger
   or pll_m
   or pll_n
   or pll_c
  ) begin
    next_state            = state;
    reset_ctr             = 1'b0;
    write_param_ctr_int   = 1'b0;
    pll_areset_in_ctr     = 1'b0;
    reconfig_ctr          = 1'b0;
    counter_type_ctr_int  = 4'b0;
    counter_param_ctr_int = 3'b0;
    config_data_in_int    = 8'b0;

    case (state)
      Idle: begin
        if (trigger)
          next_state = SetM;
      end

      SetM: begin
        if (~busy) begin
          write_param_ctr_int   = 1'b1;
          counter_type_ctr_int  = 4'd1;
          counter_param_ctr_int = 3'd7;
          config_data_in_int    = pll_m;
          next_state            = SetN;
        end
      end

      SetN: begin
        if (~busy) begin
          write_param_ctr_int   = 1'b1;
          counter_type_ctr_int  = 4'd0;
          counter_param_ctr_int = 3'd7;
          config_data_in_int    = pll_n;
          next_state            = SetC0H;
        end
      end

      SetC0H: begin
        if (~busy) begin
          write_param_ctr_int   = 1'b1;
          counter_type_ctr_int  = 4'd4;
          counter_param_ctr_int = 3'd0;
          config_data_in_int    = pll_c;
          next_state            = SetC0L;
        end
      end

      SetC0L: begin
        if (~busy) begin
          write_param_ctr_int   = 1'b1;
          counter_type_ctr_int  = 4'd4;
          counter_param_ctr_int = 3'd1;
          config_data_in_int    = pll_c;
          next_state            = Reconfig;
        end
      end

      Reconfig: begin
        if (~busy) begin
          reconfig_ctr    = 1'b1;
          next_state      = Busy;
        end
      end

      Busy: begin
        if (~busy)
          next_state      = Idle;
      end

      ResetPLL: begin
        pll_areset_in_ctr = 1'b1;
        next_state        = ResetCTR;
      end

      ResetCTR: begin
        reset_ctr         = 1'b1;
        next_state        = Idle;
      end
    endcase
  end

endmodule
