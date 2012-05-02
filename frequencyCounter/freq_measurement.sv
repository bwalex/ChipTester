// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.3
//
// frequency measurement module - Measures the frequency of the input signal.
// 

module freq_measurement #(
  parameter DATA_WIDTH = 16
)(
  input                         Clock,
  input                         nReset,

  output logic [DATA_WIDTH-1:0] edge_count,
  output                        done_flag,
  input        [DATA_WIDTH-1:0] n_cycles,
  input                         in_wave,
  input                         enable_in
);

  timeunit       1ns;
  timeprecision 10ps;

  wire                          rising_edge;
  wire                          count_overflow;
  logic        [DATA_WIDTH-1:0] cycle_count;
  logic                         in_wave_sync0;
  logic                         in_wave_sync1;
  logic                         in_wave_d1;
  logic                         in_wave_d2;
  logic                         enable_d1;
  logic                         enable;


  /* Synchronizer stage - we are effectively crossing a clock domain */
  always_ff @(posedge Clock, negedge nReset)
    if (!nReset) begin
      in_wave_sync0 <= 1'b0;
      in_wave_sync1 <= 1'b0;
      in_wave_d1    <= 1'b0;
      in_wave_d2    <= 1'b0;
    end
    else begin
      in_wave_sync0 <= in_wave;
      in_wave_sync1 <= in_wave_sync0;
      in_wave_d1    <= in_wave_sync1;
      in_wave_d2    <= in_wave_d1;
    end


  assign rising_edge    = (in_wave_d1 & ~in_wave_d2);


  assign count_overflow = (cycle_count == n_cycles);
  assign done_flag      = count_overflow;


  always_ff @(posedge Clock, negedge nReset)
    if (!nReset)
      enable_d1   <= 1'b0;
    else
      enable_d1   <= enable_in;


  always_ff @(posedge Clock, negedge nReset)
    if (!nReset)
      enable      <= 1'b0;
    else if (count_overflow)
      enable      <= 1'b0;
    else if (enable_in & ~enable_d1)
      enable      <= 1'b1;


  always_ff @(posedge Clock, negedge nReset)
    if (!nReset)
      edge_count  <= 0;
    else if (rising_edge && enabled)
      edge_count  <= edge_count + 1;


  always_ff @(posedge Clock, negedge nReset)
    if (!nReset)
      cycle_count <= 0;
    else if (count_overflow)
      cycle_count <= 0;
    else if (enabled)
      cycle_count <= cycle_count + 1;

endmodule
