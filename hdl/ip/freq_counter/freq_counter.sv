// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.3
//
// top-level module - Provides the connections between the sub-modules
// of the process and the interface to previous/next blocks of the process.

timeunit 1ns; timeprecision 10ps;

module freq_counter #(
  parameter ADDR_WIDTH = 8,
            DATA_WIDTH = 32,
            NREGS = 5,
            NDESIGNS = 24
)(
  output                      irq,
  
  input      [ADDR_WIDTH-1:0] address,

  input                       read,
  output     [          31:0] readdata,
  output                      readdatavalid,

  input                       write,
  input      [          31:0] writedata,

  input      [  NDESIGNS-1:0] in_signal,
  output                      busy,

  input                       Clock,
  input                       nResetIn
);

  // declaration of local signals
  wire [DATA_WIDTH-1:0] edge_count;
  wire                  done_flag;

  wire [DATA_WIDTH-1:0] n_cycles;
  wire [DATA_WIDTH-1:0] input_select;

  wire                  enable;
  wire                  mux_wave;


  fc_mux#(
    .NDESIGNS     (NDESIGNS),
    .DATA_WIDTH   (DATA_WIDTH)
  ) mux_1 (
    .out_wave     (mux_wave),
    .select_input (input_select),
    .in_signal    (in_signal)
  );

  freq_measurement#(
    .DATA_WIDTH   (DATA_WIDTH)
  ) freq_measurement_1 (
    .Clock        (Clock),
    .nReset       (nResetIn),
    .edge_count   (edge_count),
    .done_flag    (done_flag),
    .n_cycles     (n_cycles),
    .in_wave      (mux_wave),
    .enable_in    (enable)
  );

  fc_control#(
    .ADDR_WIDTH    (ADDR_WIDTH),
    .DATA_WIDTH    (DATA_WIDTH)
  ) control_1 (
    .clock         (Clock),
    .nreset        (nResetIn),

    .address       (address),
    .read          (read),
    .readdata      (readdata),
    .readdatavalid (readdatavalid),
    .write         (write),
    .writedata     (writedata),

    .irq           (irq),

    .cycle_count   (n_cycles),
    .input_select  (input_select),
    .enable        (enable),
    .busy          (busy),
    .done          (done_flag),
    .edge_count    (edge_count)
  );

endmodule
