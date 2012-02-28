`timescale 1ns/10ps
module top();

// synthesis translate_off
	
	logic       clock;
	logic       reset_n;

	event		start_test;

	wire [19:0] address;
	wire [1:0]  byteenable;
	wire [15:0] readdata;
	wire        read;
	wire        write;
	wire [15:0] writedata;
	wire        waitrequest;

	wire [19:0] stim_address;
	wire [1:0]  stim_byteenable;
	wire [15:0] stim_readdata;
	wire        stim_read;
	wire        stim_waitrequest;
	wire        check_waitrequest;
	
	wire [19:0] sram_address;
	wire [15:0] sram_data;
	wire        sram_ce_n;
	wire        sram_oe_n;
	wire        sram_we_n;
	wire [ 1:0] sram_be_n;

	wire [23:0] sfifo_data;
	wire [51:0] cfifo_data;
	wire        sfifo_wrreq;
	wire        cfifo_wrreq;
	logic       sfifo_wrfull;
	logic       cfifo_wrfull;
	logic       sfifo_wrempty;
	logic       cfifo_wrempty;
	wire [ 4:0] sc_cmd;
	wire [23:0] sc_data;
	wire        sc_switching;
  
	
	
	sram_arb arb(
		.clock(clock),
		.reset_n(1'b1),
		.sel(1'b0),
		.sram_address(sram_address),
		.sram_data(sram_data),
		.sram_ce_n(sram_ce_n),
		.sram_oe_n(sram_oe_n),
		.sram_we_n(sram_we_n),
		.sram_be_n(sram_be_n),
		.sopc_address(address),
		.sopc_byteenable(byteenable),
		.sopc_readdata(readdata),
		.sopc_read(read),
		.sopc_write(write),
		.sopc_writedata(writedata),
		.sopc_waitrequest(waitrequest),

		.tr_address(address),
		.tr_byteenable(byteenable),
		.tr_read(read),
		.tr_write(write),
		.tr_writedata(writedata)
	);
	
	mem_if memif(
		.clock              (clock),
		.reset_n            (reset_n),

		.mem_address        (address),
		.mem_byteenable     (byteenable),
		.mem_read           (read),
		.mem_readdata       (readdata),
		.mem_write          (write),
		.mem_writedata      (writedata),
		.mem_waitrequest    (waitrequest),

		.stim_address       (stim_address),
		.stim_byteenable    (stim_byteenable),
		.stim_read          (stim_read),
		.stim_readdata      (stim_readdata),
		.stim_waitrequest   (stim_waitrequest),

		.check_address      (stim_address),
		.check_byteenable   (stim_byteenable),
		.check_write        (1'b0),
		.check_writedata    (16'h0),
		.check_waitrequest  (check_waitrequest)
	);

	stim stim_mod(
		.clock              (clock),
		.reset_n            (reset_n),

		.mem_address        (stim_address),
		.mem_byteenable     (stim_byteenable),
		.mem_read           (stim_read),
		.mem_readdata       (stim_readdata),
		.mem_waitrequest    (stim_waitrequest),

		.sfifo_data         (sfifo_data),
		.sfifo_wrreq        (sfifo_wrreq),
		.sfifo_wrfull       (sfifo_wrfull),
		.sfifo_wrempty      (sfifo_wrempty),

		.cfifo_data         (cfifo_data),
		.cfifo_wrreq        (cfifo_wrreq),
		.cfifo_wrfull       (cfifo_wrfull),
		.cfifo_wrempty      (cfifo_wrempty),

		.sc_cmd             (sc_cmd),
		.sc_data            (sc_data),
		.sc_switching       (sc_switching)
	);

	
	
	async_sram#(
	    .USE_INIT(1),
		 .INIT_FILE("sram_contents.txt")
	) sram(
		.A(sram_address),
		.IO(sram_data),
		.CE_(sram_ce_n),
		.OE_(sram_oe_n),
		.WE_(sram_we_n),
		.LB_(sram_be_n[0]),
		.UB_(sram_be_n[1])
	);

	always
	begin
	       clock = 0;
	  #5   clock = 1;
	  #5   clock = 0;
	end

	initial begin
		    reset_n = 1;
		#5  reset_n = 0;
		#16 reset_n = 1;
		-> start_test;
	end

	initial begin
	  cfifo_wrfull = 1'b0;
	  sfifo_wrfull = 1'b0;
	  cfifo_wrempty = 1'b1;
	  sfifo_wrempty = 1'b1;
	  @ start_test;
	  #1000
	  while (top.stim_mod.state != 6'b000101) /* WR_FIFOS state */
            @(posedge clock);
	  sfifo_wrfull = 1'b1;
	  #100  @(posedge clock);
	  sfifo_wrfull = 1'b0;
	end
endmodule
