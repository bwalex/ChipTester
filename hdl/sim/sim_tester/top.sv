`timescale 1ns/10ps
module top();

// synthesis translate_off
  
  logic        clock;
  logic        clock_10;
  logic        reset_n;
  wire         reset;

  event        start_test;

  wire  [19:0] address;
  wire  [ 1:0] byteenable;
  wire  [15:0] readdata;
  wire         read;
  wire         readdataready;
  wire         write;
  wire  [15:0] writedata;
  wire         waitrequest;

  wire  [19:0] stim_address;
  wire  [ 1:0] stim_byteenable;
  wire  [15:0] stim_readdata;
  wire         stim_read;
  wire         stim_readdataready;
  wire         stim_waitrequest;

  wire  [19:0] check_address;
  wire  [ 1:0] check_byteenable;
  wire  [15:0] check_writedata;
  wire         check_write;
  wire         check_waitrequest;
  
  wire  [19:0] sram_address;
  wire  [15:0] sram_data;
  wire         sram_ce_n;
  wire         sram_oe_n;
  wire         sram_we_n;
  wire  [ 1:0] sram_be_n;

  wire  [23:0] sfifo_data;
  wire         sfifo_wrreq;
  logic        sfifo_wrfull;
  logic        sfifo_wrempty;
  wire         sfifo_rdreq;
  wire         sfifo_rdempty;
  wire  [23:0] sfifo_dataq;

  wire  [23:0] rfifo_data;
  wire         rfifo_wrreq;
  wire         rfifo_wrfull;
  wire         rfifo_rdreq;
  wire         rfifo_rdempty;
  wire  [23:0] rfifo_dataq;

  wire  [31:0] dififo_data;
  wire         dififo_wrreq;
  wire         dififo_wrfull;
  wire         dififo_rdreq;
  wire         dififo_rdempty;
  wire  [31:0] dififo_dataq;

  wire  [51:0] cfifo_data;
  wire         cfifo_wrreq;
  logic        cfifo_wrfull;
  logic        cfifo_wrempty;
  wire         cfifo_rdreq;
  wire         cfifo_rdempty;
  wire  [51:0] cfifo_dataq;


  wire  [ 4:0] sc_cmd;
  wire  [23:0] sc_data;
  wire         sc_switching;
  
  
  assign reset = ~reset_n;


  async_sram#(
    .USE_INIT           (1),
    .INIT_FILE          ("sram_contents.txt")
  ) sram(
    .A                  (sram_address),
    .IO                 (sram_data),
    .CE_                (sram_ce_n),
    .OE_                (sram_oe_n),
    .WE_                (sram_we_n),
    .LB_                (sram_be_n[0]),
    .UB_                (sram_be_n[1])
  );


  sram_arb_sync arb(
    .clock              (clock),
    .reset_n            (reset_n),
    .sel                (1'b0),
    .sram_address       (sram_address),
    .sram_data          (sram_data),
    .sram_ce_n          (sram_ce_n),
    .sram_oe_n          (sram_oe_n),
    .sram_we_n          (sram_we_n),
    .sram_be_n          (sram_be_n),
    .sopc_address       (address),
    .sopc_byteenable    (byteenable),
    .sopc_readdata      (readdata),
    .sopc_read          (read),
    .sopc_readdataready (readdataready),
    .sopc_write         (write),
    .sopc_writedata     (writedata),
    .sopc_waitrequest   (waitrequest),

    .tr_address         (address),
    .tr_byteenable      (byteenable),
    .tr_read            (read),
    .tr_write           (write),
    .tr_writedata       (writedata)
  );


  mem_if memif(
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
    .WAIT_WIDTH         (4)
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

    .dififo_data         (dififo_data),
    .dififo_wrreq        (dififo_wrreq),
    .dififo_wrfull       (dififo_wrfull),

    .sc_cmd             (sc_cmd),
    .sc_data            (sc_data),
    .sc_switching       (sc_switching),
    .sc_ready           (sc_ready)
  );


  check check_mod(
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
    .sc_switching       (sc_switching),
    .sc_ready           (sc_ready)
  );


  loopback loopback_mod(
    .clock              (clock_10),
    .reset_n            (reset_n),

    .sfifo_data         (sfifo_dataq),
    .sfifo_rdreq        (sfifo_rdreq),
    .sfifo_rdempty      (sfifo_rdempty),

    .rfifo_data         (rfifo_data),
    .rfifo_wrreq        (rfifo_wrreq),
    .rfifo_wrfull       (rfifo_wrfull)
  );


  cfifo cfifo_inst(
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


  stfifo sfifo_inst(
    .aclr               (reset),
    .data               (sfifo_data),
    .rdclk              (clock_10),
    .rdreq              (sfifo_rdreq),
    .wrclk              (clock),
    .wrreq              (sfifo_wrreq),
    .q                  (sfifo_dataq),
    .rdempty            (sfifo_rdempty),
    .wrempty            (sfifo_wrempty),
    .wrfull             (sfifo_wrfull)
  );


  rfifo rfifo_inst(
    .aclr               (reset),
    .data               (rfifo_data),
    .rdclk              (clock),
    .rdreq              (rfifo_rdreq),
    .wrclk              (clock_10),
    .wrreq              (rfifo_wrreq),
    .q                  (rfifo_dataq),
    .rdempty            (rfifo_rdempty),
    .wrfull             (rfifo_wrfull)
  );


  dififo dififo_inst(
    .aclr               (reset),
    .data               (dififo_data),
    .rdclk              (clock),
    .rdreq              (dififo_rdreq),
    .wrclk              (clock_10),
    .wrreq              (dififo_wrreq),
    .q                  (dififo_dataq),
    .rdempty            (dififo_rdempty),
    .wrfull             (dififo_wrfull)
  );


  // 100 MHz clock
  always
  begin
         clock = 0;
    #5   clock = 1;
    #5   clock = 0;
  end

  // 10 MHz clock
  always
  begin
         clock_10 = 0;
    #50  clock_10 = 1;
    #50  clock_10 = 0;
  end

  initial begin
        reset_n = 1;
    #5  reset_n = 0;
    #16 reset_n = 1;
    -> start_test;
  end

  initial begin
    //cfifo_wrfull = 1'b0;
    //sfifo_wrfull = 1'b0;
    //cfifo_wrempty = 1'b1;
    //sfifo_wrempty = 1'b1;
    @ start_test;
    #1000
    while (top.stim_mod.state != 6'b000101) /* WR_FIFOS state */
            @(posedge clock);
    //sfifo_wrfull = 1'b1;
    #100  @(posedge clock);
    //sfifo_wrfull = 1'b0;
  end
endmodule
