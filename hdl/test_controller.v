`timescale 1ns/10ps

module test_controller #(
  parameter ADDR_WIDTH = 20,
            DATA_WIDTH = 16,
            BE_WIDTH   = DATA_WIDTH/8,


            STF_WIDTH  = 24,
            RTF_WIDTH  = 24,

            /* REQ_WIDTH + CMD_WIDTH must be <= 8 */
            CMD_WIDTH  = 5,
            REQ_WIDTH  = 3,

            SCC_WIDTH  = 5,
            SCD_WIDTH  = 24,

            WAIT_WIDTH = 16,
            DSEL_WIDTH = 5, /* Target design select */

            DIF_WIDTH  = REQ_WIDTH+CMD_WIDTH+STF_WIDTH,
            CHF_WIDTH  = STF_WIDTH+ADDR_WIDTH /* (output vector), (address) */
)(
  input                    clock,
  input                    reset_n,
  input                    fifo_clock,

  output  [ADDR_WIDTH-1:0] address,
  output  [  BE_WIDTH-1:0] byteenable,
  input   [DATA_WIDTH-1:0] readdata,
  output                   read,
  input                    readdataready,
  output                   write,
  output  [DATA_WIDTH-1:0] writedata,
  input                    waitrequest,

  input                    sfifo_rdreq,
  output                   sfifo_rdempty,
  output  [ STF_WIDTH-1:0] sfifo_dataq,

  input   [ RTF_WIDTH-1:0] rfifo_data,
  input                    rfifo_wrreq,
  output                   rfifo_wrfull,

  input                    dififo_rdreq,
  output                   dififo_rdempty,
  output  [ DIF_WIDTH-1:0] dififo_dataq,

  output  [DSEL_WIDTH-1:0] target_sel
);


  wire                     reset;

  wire    [ADDR_WIDTH-1:0] stim_address;
  wire    [  BE_WIDTH-1:0] stim_byteenable;
  wire    [DATA_WIDTH-1:0] stim_readdata;
  wire                     stim_read;
  wire                     stim_readdataready;
  wire                     stim_waitrequest;

  wire    [ADDR_WIDTH-1:0] check_address;
  wire    [  BE_WIDTH-1:0] check_byteenable;
  wire    [DATA_WIDTH-1:0] check_writedata;
  wire                     check_write;
  wire                     check_waitrequest;

  wire    [ STF_WIDTH-1:0] sfifo_data;
  wire                     sfifo_wrreq;
  wire                     sfifo_wrfull;
  wire                     sfifo_wrempty;

  wire                     rfifo_rdreq;
  wire                     rfifo_rdempty;
  wire    [ RTF_WIDTH-1:0] rfifo_dataq;

  wire    [ DIF_WIDTH-1:0] dififo_data;
  wire                     dififo_wrreq;
  wire                     dififo_wrfull;

  wire    [ CHF_WIDTH-1:0] cfifo_data;
  wire                     cfifo_wrreq;
  wire                     cfifo_wrfull;
  wire                     cfifo_wrempty;
  wire                     cfifo_rdreq;
  wire                     cfifo_rdempty;
  wire    [ CHF_WIDTH-1:0] cfifo_dataq;

  wire    [ SCC_WIDTH-1:0] sc_cmd;
  wire    [ SCD_WIDTH-1:0] sc_data;
  wire                     sc_ready;


  assign reset = ~reset_n;



  mem_if#(
    .ADDR_WIDTH         (ADDR_WIDTH),
    .DATA_WIDTH         (DATA_WIDTH)
  ) memif(
    .clock              (clock),
    .reset_n            (reset_n),

    .mem_address        (address),
    .mem_byteenable     (byteenable),
    .mem_read           (read),
    .mem_readdata       (readdata),
    .mem_readdataready  (readdataready),
    .mem_write          (write),
    .mem_writedata      (writedata),
    .mem_waitrequest    (waitrequest),

    .stim_address       (stim_address),
    .stim_byteenable    (stim_byteenable),
    .stim_read          (stim_read),
    .stim_readdata      (stim_readdata),
    .stim_readdataready (stim_readdataready),
    .stim_waitrequest   (stim_waitrequest),

    .check_address      (check_address),
    .check_byteenable   (check_byteenable),
    .check_write        (check_write),
    .check_writedata    (check_writedata),
    .check_waitrequest  (check_waitrequest)
  );


  stim#(
    .ADDR_WIDTH         (ADDR_WIDTH),
    .DATA_WIDTH         (DATA_WIDTH),
    .STF_WIDTH          (STF_WIDTH),
    .CHF_WIDTH          (CHF_WIDTH),
    .DIF_WIDTH          (DIF_WIDTH),
    .CMD_WIDTH          (CMD_WIDTH),
    .REQ_WIDTH          (REQ_WIDTH),
    .SCC_WIDTH          (SCC_WIDTH),
    .SCD_WIDTH          (SCD_WIDTH),
    .DSEL_WIDTH         (DSEL_WIDTH),
    .WAIT_WIDTH         (WAIT_WIDTH)
  ) stim_mod(
    .clock              (clock),
    .reset_n            (reset_n),

    .mem_address        (stim_address),
    .mem_byteenable     (stim_byteenable),
    .mem_read           (stim_read),
    .mem_readdata       (stim_readdata),
    .mem_readdataready  (stim_readdataready),
    .mem_waitrequest    (stim_waitrequest),

    .sfifo_data         (sfifo_data),
    .sfifo_wrreq        (sfifo_wrreq),
    .sfifo_wrfull       (sfifo_wrfull),
    .sfifo_wrempty      (sfifo_wrempty),

    .cfifo_data         (cfifo_data),
    .cfifo_wrreq        (cfifo_wrreq),
    .cfifo_wrfull       (cfifo_wrfull),
    .cfifo_wrempty      (cfifo_wrempty),

    .dififo_data        (dififo_data),
    .dififo_wrreq       (dififo_wrreq),
    .dififo_wrfull      (dififo_wrfull),

    .sc_cmd             (sc_cmd),
    .sc_data            (sc_data),
    .sc_ready           (sc_ready)
  );


  check#(
    .ADDR_WIDTH         (ADDR_WIDTH),
    .DATA_WIDTH         (DATA_WIDTH),
    .RTF_WIDTH          (RTF_WIDTH),
    .CHF_WIDTH          (CHF_WIDTH),
    .SCC_WIDTH          (SCC_WIDTH),
    .SCD_WIDTH          (SCD_WIDTH)
  ) check_mod(
    .clock              (clock),
    .reset_n            (reset_n),

    .mem_address        (check_address),
    .mem_byteenable     (check_byteenable),
    .mem_write          (check_write),
    .mem_writedata      (check_writedata),
    .mem_waitrequest    (check_waitrequest),

    .rfifo_data         (rfifo_dataq),
    .rfifo_rdreq        (rfifo_rdreq),
    .rfifo_rdempty      (rfifo_rdempty),

    .cfifo_data         (cfifo_dataq),
    .cfifo_rdreq        (cfifo_rdreq),
    .cfifo_rdempty      (cfifo_rdempty),

    .sc_cmd             (sc_cmd),
    .sc_data            (sc_data),
    .sc_ready           (sc_ready)
  );


  dcfifo_custom#(
    .DATA_WIDTH         (STF_WIDTH),
    .FIFO_DEPTH         (16)
  ) sfifo_inst(
    .aclr               (reset),
    .data               (sfifo_data),
    .rdclk              (fifo_clock),
    .rdreq              (sfifo_rdreq),
    .wrclk              (clock),
    .wrreq              (sfifo_wrreq),
    .q                  (sfifo_dataq),
    .rdempty            (sfifo_rdempty),
    .wrempty            (sfifo_wrempty),
    .wrfull             (sfifo_wrfull)
  );


  dcfifo_custom#(
    .DATA_WIDTH         (RTF_WIDTH),
    .FIFO_DEPTH         (16)
  ) rfifo_inst(
    .aclr               (reset),
    .data               (rfifo_data),
    .rdclk              (clock),
    .rdreq              (rfifo_rdreq),
    .wrclk              (fifo_clock),
    .wrreq              (rfifo_wrreq),
    .q                  (rfifo_dataq),
    .rdempty            (rfifo_rdempty),
    .wrfull             (rfifo_wrfull)
  );


  dcfifo_custom#(
    .DATA_WIDTH         (CHF_WIDTH),
    .FIFO_DEPTH         (16)
  ) cfifo_inst(
    .aclr               (reset),
    .data               (cfifo_data),
    .rdclk              (clock),
    .rdreq              (cfifo_rdreq),
    .wrclk              (clock),
    .wrreq              (cfifo_wrreq),
    .q                  (cfifo_dataq),
    .rdempty            (cfifo_rdempty),
    .wrempty            (cfifo_wrempty),
    .wrfull             (cfifo_wrfull)
  );


  dcfifo_custom#(
    .DATA_WIDTH         (DIF_WIDTH),
    .FIFO_DEPTH         (16)
  ) dififo_inst(
    .aclr               (reset),
    .data               (dififo_data),
    .rdclk              (fifo_clock),
    .rdreq              (dififo_rdreq),
    .wrclk              (clock),
    .wrreq              (dififo_wrreq),
    .q                  (dififo_dataq),
    .rdempty            (dififo_rdempty),
    .wrfull             (dififo_wrfull)
  );

endmodule