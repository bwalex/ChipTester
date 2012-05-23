`timescale 1ns/10ps
module tester #(
  parameter ADDR_WIDTH = 20,
            DATA_WIDTH = 16,
            BE_WIDTH   = DATA_WIDTH/8,

            STF_WIDTH  = 24,
            RTF_WIDTH  = 24,

            /* REQ_WIDTH + CMD_WIDTH must be <= 8 */
            CMD_WIDTH  = 5,
            REQ_WIDTH  = 3,

            WAIT_WIDTH = 16,
            DSEL_WIDTH = 5, /* Target design select */
            CYCLE_RANGE = 5,
            PLL_MIF_FILE = "plladditional.mif",
            PLL_DATA_WIDTH = 8,

            DIF_WIDTH  = REQ_WIDTH+CMD_WIDTH+STF_WIDTH
)(
  input                    clock,
  input                    reset_n,

  output                   dyn_clock,

  input                    enable,
  output                   done,

  output  [ADDR_WIDTH-1:0] address,
  output  [  BE_WIDTH-1:0] byteenable,
  input   [DATA_WIDTH-1:0] readdata,
  output                   read,
  input                    readdataready,
  output                   write,
  output  [DATA_WIDTH-1:0] writedata,
  input                    waitrequest,

  output  [DSEL_WIDTH-1:0] target_sel,

  output  [ STF_WIDTH-1:0] mosi,
  input   [ RTF_WIDTH-1:0] miso
);

  wire                     sfifo_rdreq;
  wire                     sfifo_rdempty;
  wire    [ STF_WIDTH+CYCLE_RANGE:0] sfifo_dataq;

  wire    [ RTF_WIDTH+CYCLE_RANGE:0] rfifo_data;
  wire                     rfifo_wrreq;
  wire                     rfifo_wrfull;

  wire                     dififo_rdreq;
  wire                     dififo_rdempty;
  wire    [ DIF_WIDTH-1:0] dififo_dataq;
  
  wire                     pll_clock;
  wire                     pll_trigger;
  wire                     pll_locked;
  wire                     pll_stable;
  wire [PLL_DATA_WIDTH-1:0] pll_m;
  wire [PLL_DATA_WIDTH-1:0] pll_n;
  wire [PLL_DATA_WIDTH-1:0] pll_c;

  assign dyn_clock = pll_clock;

  test_controller#(
    .ADDR_WIDTH         (ADDR_WIDTH),
    .DATA_WIDTH         (DATA_WIDTH),
    .STF_WIDTH          (STF_WIDTH),
    .RTF_WIDTH          (RTF_WIDTH),
    .DSEL_WIDTH         (DSEL_WIDTH),
    .REQ_WIDTH          (REQ_WIDTH),
    .CMD_WIDTH          (CMD_WIDTH),
    .WAIT_WIDTH         (WAIT_WIDTH),
	  .CYCLE_RANGE        (CYCLE_RANGE),
    .PLL_DATA_WIDTH     (PLL_DATA_WIDTH)
  ) test_controller(
    .clock              (clock),
    .reset_n            (reset_n),
    .fifo_clock         (pll_clock),

    .enable             (enable),
    .done               (done),

    .address            (address),
    .byteenable         (byteenable),
    .read               (read),
    .readdata           (readdata),
    .readdataready      (readdataready),
    .write              (write),
    .writedata          (writedata),
    .waitrequest        (waitrequest),

    .sfifo_dataq        (sfifo_dataq),
    .sfifo_rdreq        (sfifo_rdreq),
    .sfifo_rdempty      (sfifo_rdempty),

    .rfifo_data         (rfifo_data),
    .rfifo_wrreq        (rfifo_wrreq),
    .rfifo_wrfull       (rfifo_wrfull),

    .dififo_dataq       (dififo_dataq),
    .dififo_rdreq       (dififo_rdreq),
    .dififo_rdempty     (dififo_rdempty),

    .target_sel         (target_sel),
	 
    .pll_m              (pll_m),
    .pll_n              (pll_n),
    .pll_c              (pll_c),
    .pll_trigger        (pll_trigger),
    .pll_locked         (pll_locked),
    .pll_stable         (pll_stable)
  );

  dut_if #(
    .STF_WIDTH          (STF_WIDTH),
    .RTF_WIDTH          (RTF_WIDTH),
    .REQ_WIDTH          (REQ_WIDTH),
    .CMD_WIDTH          (CMD_WIDTH),
	 .CYCLE_RANGE         (CYCLE_RANGE)
  ) dut_if(
    .clock              (pll_clock),
    .reset_n            (reset_n),

    .sfifo_data         (sfifo_dataq),
    .sfifo_rdreq        (sfifo_rdreq),
    .sfifo_rdempty      (sfifo_rdempty),

    .dififo_data        (dififo_dataq),
    .dififo_rdreq       (dififo_rdreq),
    .dififo_rdempty     (dififo_rdempty),

    .rfifo_data         (rfifo_data),
    .rfifo_wrreq        (rfifo_wrreq),
    .rfifo_wrfull       (rfifo_wrfull),

    .mosi_data          (mosi),
    .miso_data          (miso)
  );
  
  PLL_INTERFACE #(
    .FILELOCATION_AND_NAME (PLL_MIF_FILE),
    .FILENAME              (PLL_MIF_FILE)
  ) pll_if(
    .clock              (clock),
	  .reset_n            (reset_n),
	  .trigger            (pll_trigger),            
    .pll_m              (pll_m),
    .pll_n              (pll_n),
    .pll_c              (pll_c),
	
	  .c0                 (pll_clock),
	  .locked             (pll_locked),
	  .stable_reconfig    (pll_stable)
  );

  


endmodule