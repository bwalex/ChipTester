`define BFM top.tb.mm_master_bfm_0
`define CLK top.tb.clock_source_0
`define RST top.tb.reset_source_0
`timescale 1ns/10ps
module top();

// synthesis translate_off
	import verbosity_pkg::*;
	import avalon_mm_pkg::*;

	event		start_test;

	logic [15:0] READDATA;
	wire        clock;
	wire [19:0] address;
	wire [1:0]  byteenable;
	wire [15:0] readdata;
	wire        readdataready;
	wire        read;
	wire        write;
	wire [15:0] writedata;
	wire        waitrequest;
	
	wire [19:0] sram_address;
	wire [15:0] sram_data;
	wire        sram_ce_n;
	wire        sram_oe_n;
	wire        sram_we_n;
	wire [ 1:0] sram_be_n;

	sram_bridge_bfm tb(
		.sram_bridge_conduit_clock(clock),
		.sram_bridge_conduit_address(address),
		.sram_bridge_conduit_byteenable(byteenable),
		.sram_bridge_conduit_readdata(readdata),
		.sram_bridge_conduit_read(read),
		.sram_bridge_conduit_readdataready(readdataready),
		.sram_bridge_conduit_write(write),
		.sram_bridge_conduit_writedata(writedata),
		.sram_bridge_conduit_waitrequest(waitrequest)
	);

	sram_arb_sync arb(
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
		.sopc_readdataready(readdataready),
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

	async_sram sram(
		.A(sram_address),
		.IO(sram_data),
		.CE_(sram_ce_n),
		.OE_(sram_oe_n),
		.WE_(sram_we_n),
		.LB_(sram_be_n[0]),
		.UB_(sram_be_n[1])
	);

	initial begin
		set_verbosity(VERBOSITY_INFO);
		`BFM.init();
		//`CLK.init();
		//`RST.init();
		wait(`RST.reset == 0)
			-> start_test;
	end

	initial begin
		@ start_test;

		avalon_write(.addr(20'hA), .data(16'hAABB));
		avalon_write(.addr(20'hB), .data(16'h1122));
		avalon_write(.addr(20'hC), .data(16'h0099));
		avalon_read(.addr(20'hC), .data(READDATA));
		avalon_read(.addr(20'hB), .data(READDATA));
		avalon_read(.addr(20'hA), .data(READDATA));
		avalon_get_result(.data(READDATA));
		avalon_get_result(.data(READDATA));
		avalon_get_result(.data(READDATA));
		avalon_get_result(.data(READDATA));
	end

// ============================================================
    // Tasks
    // ============================================================
    //
    // Avalon-MM single-transaction read and write procedures.
    //
    // ------------------------------------------------------------
    task avalon_write (
    // ------------------------------------------------------------
        input [19:0] addr,
        input [15:0] data
    );
    begin
        // Construct the BFM request
        `BFM.set_command_request(REQ_WRITE);
        `BFM.set_command_idle(0, 0);
        `BFM.set_command_init_latency(0);
        `BFM.set_command_address(addr);    
        `BFM.set_command_byte_enable('1,0);
        `BFM.set_command_data(data, 0);      

        // Queue the command
        `BFM.push_command();
        
        // Wait until the transaction has completed
        while (`BFM.get_response_queue_size() != 1)
            @(posedge clock);

        // Dequeue the response and discard
        `BFM.pop_response();
    end
    endtask
            
    // ------------------------------------------------------------
    task avalon_read (
    // ------------------------------------------------------------
        input  [19:0] addr,
        output [15:0] data
    );
    begin
        // Construct the BFM request
        `BFM.set_command_request(REQ_READ);
        `BFM.set_command_idle(0, 0);
        `BFM.set_command_init_latency(0);
        `BFM.set_command_address(addr);
        `BFM.set_command_byte_enable('1,0);
        `BFM.set_command_data(0, 0);      

        // Queue the command
        `BFM.push_command();
    end
    endtask

    task avalon_get_result (
        output [15:0] data
    );
    begin
        // Wait until the transaction has completed
        while (`BFM.get_response_queue_size() < 1)
            @(posedge clock);

        // Dequeue the response and return the data
        `BFM.pop_response();
        data = `BFM.get_response_data(0);
    end
    endtask;
endmodule
