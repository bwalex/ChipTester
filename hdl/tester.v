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

            DIF_WIDTH  = REQ_WIDTH+CMD_WIDTH+STF_WIDTH
)(
  input                    clock,
  input                    reset_n,
  input                    fifo_clock,

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
  wire    [ STF_WIDTH-1:0] sfifo_dataq;

  wire    [ RTF_WIDTH-1:0] rfifo_data;
  wire                     rfifo_wrreq;
  wire                     rfifo_wrfull;

  wire                     dififo_rdreq;
  wire                     dififo_rdempty;
  wire    [ DIF_WIDTH-1:0] dififo_dataq;


  test_controller#(
    .ADDR_WIDTH         (ADDR_WIDTH),
    .DATA_WIDTH         (DATA_WIDTH),
    .STF_WIDTH          (STF_WIDTH),
    .RTF_WIDTH          (RTF_WIDTH),
    .DSEL_WIDTH         (DSEL_WIDTH),
    .REQ_WIDTH          (REQ_WIDTH),
    .CMD_WIDTH          (CMD_WIDTH),
    .WAIT_WIDTH         (WAIT_WIDTH)
  ) test_controller(
    .clock              (clock),
    .reset_n            (reset_n),
    .fifo_clock         (fifo_clock),

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

    .target_sel         (target_sel)
  );

  dut_if #(
    .STF_WIDTH          (STF_WIDTH),
    .RTF_WIDTH          (RTF_WIDTH),
    .REQ_WIDTH          (REQ_WIDTH),
    .CMD_WIDTH          (CMD_WIDTH)
  ) dut_if(
    .clock              (fifo_clock),
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


endmodule