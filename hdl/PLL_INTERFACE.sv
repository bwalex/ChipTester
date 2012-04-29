module PLL_INTERFACE#(
  parameter FILELOCATION_AND_NAME = "H:\.das\Desktop\VLSI\April Progress\hdl.mif",
  parameter FILENAME = "PLL.mif"
  )(
  input        clock,
  input        reset_n,
  input        trigger,
  input  [7:0] pll_m,
  input  [7:0] pll_n,
  input  [7:0] pll_c,

  output       c0,
  output       locked,

  output       busy,
  output [8:0] data_out,
  output       stable_reconfig
);

  wire         pll_areset;
  wire         pll_configupdate;
  wire         pll_scanclk;
  wire         pll_scanclkena;
  wire         pll_scandata;
  wire         areset;
  wire         configupdate;
  wire         scanclk;
  wire         scanclkena;
  wire         scandata;
  wire         pll_scandataout;
  wire         pll_scandone;
  wire         scandataout;
  wire         scandone;
  wire         write_param;
  wire         rec_reset;
  wire         reconfig;
  wire         pfdena;
  wire         read_param;
  wire   [2:0] counter_param;
  wire   [3:0] counter_type;
  wire         pll_areset_in;
  wire   [8:0] data_in;
  wire         reset;
  wire         idle_state;


  assign reset           = ~reset_n;
  assign areset          =  pll_areset;
  assign configupdate    =  pll_configupdate;
  assign scanclk         =  pll_scanclk;
  assign scanclkena      =  pll_scanclkena;
  assign scandata        =  pll_scandata;
  assign pll_scandataout =  scandataout;
  assign pll_scandone    =  scandone;

  assign stable_reconfig =  locked & idle_state;


  REPLL_CONTROL ctr2
  (
    .sys_reset          (reset),
    .clock_ctr          (clock),
    .trigger            (trigger),
    .busy_ctr           (busy),
    .pll_m              (pll_m),
    .pll_n              (pll_n),
    .pll_c              (pll_c),

    .counter_param_ctr  (counter_param),
    .counter_type_ctr   (counter_type),
    .reset_ctr          (rec_reset),
    .pll_areset_in_ctr  (pll_areset_in),
    .write_param_ctr    (write_param),
    .reconfig_ctr       (reconfig),
    .pll_pfdena         (pfdena),
    .pll_read_param     (read_param),
    .config_data_in     (data_in),
    .idle_state         (idle_state)
  );


  PLL #(
    .FILENAME         (FILENAME)
   )  p0 (
  areset,
  configupdate,
  clock,
  pfdena,
  scanclk,
  scanclkena,
  scandata,
  c0,
  locked,
  scandataout,
  scandone);

  REPLL_pllrcfg_1a01  #(
    .FILELOCATION_AND_NAME         (FILELOCATION_AND_NAME)
   ) pr0 (
  busy,
  clock,
  counter_param,
  counter_type,
  data_in,
  data_out,
  pll_areset,
  pll_areset_in,
  pll_configupdate,
  pll_scanclk,
  pll_scanclkena,
  pll_scandata,
  pll_scandataout,
  pll_scandone,
  read_param,
  reconfig,
  rec_reset,
  write_param) /* synthesis synthesis_clearbox=2 */;

endmodule
