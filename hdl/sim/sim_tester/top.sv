`timescale 1ns/10ps
module top();

// synthesis translate_off
  
  logic        clock;
  logic        clock_10;
  logic        reset_n;
  wire         reset;

  event        start_test;

  logic        enable;

  wire  [19:0] sram_address;
  wire  [15:0] sram_data;
  wire         sram_ce_n;
  wire         sram_oe_n;
  wire         sram_we_n;
  wire  [ 1:0] sram_be_n;

  wire  [19:0] address;
  wire  [ 1:0] byteenable;
  wire  [15:0] readdata;
  wire         read;
  wire         readdataready;
  wire         write;
  wire  [15:0] writedata;
  wire         waitrequest;

  wire         sfifo_rdreq;
  wire         sfifo_rdempty;
  wire  [23:0] sfifo_dataq;

  wire  [23:0] rfifo_data;
  wire         rfifo_wrreq;
  wire         rfifo_wrfull;

  wire         dififo_rdreq;
  wire         dififo_rdempty;
  wire  [31:0] dififo_dataq;

  wire  [23:0] miso;
  wire  [23:0] mosi;



  /* XXX: Effectively the DUT/CUT , a 1-bit left shifter */
  assign miso  = mosi << 1;



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


  test_controller#(
    .WAIT_WIDTH         (4)
  ) test_controller(
    .clock              (clock),
    .reset_n            (reset_n),
    .fifo_clock         (clock_10),

    .enable             (enable),

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
    .dififo_rdempty     (dififo_rdempty)
  );

  dut_if dut_if(
    .clock              (clock_10),
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
        enable  = 0;
        reset_n = 1;
    #5  reset_n = 0;
    #16 reset_n = 1;
        enable  = 1;
    -> start_test;
  end

endmodule
