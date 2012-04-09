// sram_bridge_bfm.v

// Generated using ACDS version 11.1sp1 216 at 2012.03.07.19:03:08

`timescale 1 ps / 1 ps
module sram_bridge_bfm (
		output wire        sram_bridge_conduit_clock,         // sram_bridge_conduit.clock
		output wire [19:0] sram_bridge_conduit_address,       //                    .address
		output wire [1:0]  sram_bridge_conduit_byteenable,    //                    .byteenable
		input  wire [15:0] sram_bridge_conduit_readdata,      //                    .readdata
		output wire        sram_bridge_conduit_read,          //                    .read
		output wire        sram_bridge_conduit_write,         //                    .write
		output wire [15:0] sram_bridge_conduit_writedata,     //                    .writedata
		input  wire        sram_bridge_conduit_waitrequest,   //                    .waitrequest
		input  wire        sram_bridge_conduit_readdataready  //                    .readdataready
	);

	wire         mm_master_bfm_0_m0_waitrequest;                                               // mm_master_bfm_0_m0_translator:av_waitrequest -> mm_master_bfm_0:avm_waitrequest
	wire  [15:0] mm_master_bfm_0_m0_writedata;                                                 // mm_master_bfm_0:avm_writedata -> mm_master_bfm_0_m0_translator:av_writedata
	wire  [19:0] mm_master_bfm_0_m0_address;                                                   // mm_master_bfm_0:avm_address -> mm_master_bfm_0_m0_translator:av_address
	wire         mm_master_bfm_0_m0_write;                                                     // mm_master_bfm_0:avm_write -> mm_master_bfm_0_m0_translator:av_write
	wire         mm_master_bfm_0_m0_read;                                                      // mm_master_bfm_0:avm_read -> mm_master_bfm_0_m0_translator:av_read
	wire  [15:0] mm_master_bfm_0_m0_readdata;                                                  // mm_master_bfm_0_m0_translator:av_readdata -> mm_master_bfm_0:avm_readdata
	wire         mm_master_bfm_0_m0_readdatavalid;                                             // mm_master_bfm_0_m0_translator:av_readdatavalid -> mm_master_bfm_0:avm_readdatavalid
	wire   [1:0] mm_master_bfm_0_m0_byteenable;                                                // mm_master_bfm_0:avm_byteenable -> mm_master_bfm_0_m0_translator:av_byteenable
	wire         mm_master_bfm_0_m0_translator_avalon_universal_master_0_waitrequest;          // sram_bridge_16_0_avalon_slave_0_translator:uav_waitrequest -> mm_master_bfm_0_m0_translator:uav_waitrequest
	wire   [1:0] mm_master_bfm_0_m0_translator_avalon_universal_master_0_burstcount;           // mm_master_bfm_0_m0_translator:uav_burstcount -> sram_bridge_16_0_avalon_slave_0_translator:uav_burstcount
	wire  [15:0] mm_master_bfm_0_m0_translator_avalon_universal_master_0_writedata;            // mm_master_bfm_0_m0_translator:uav_writedata -> sram_bridge_16_0_avalon_slave_0_translator:uav_writedata
	wire  [20:0] mm_master_bfm_0_m0_translator_avalon_universal_master_0_address;              // mm_master_bfm_0_m0_translator:uav_address -> sram_bridge_16_0_avalon_slave_0_translator:uav_address
	wire         mm_master_bfm_0_m0_translator_avalon_universal_master_0_lock;                 // mm_master_bfm_0_m0_translator:uav_lock -> sram_bridge_16_0_avalon_slave_0_translator:uav_lock
	wire         mm_master_bfm_0_m0_translator_avalon_universal_master_0_write;                // mm_master_bfm_0_m0_translator:uav_write -> sram_bridge_16_0_avalon_slave_0_translator:uav_write
	wire         mm_master_bfm_0_m0_translator_avalon_universal_master_0_read;                 // mm_master_bfm_0_m0_translator:uav_read -> sram_bridge_16_0_avalon_slave_0_translator:uav_read
	wire  [15:0] mm_master_bfm_0_m0_translator_avalon_universal_master_0_readdata;             // sram_bridge_16_0_avalon_slave_0_translator:uav_readdata -> mm_master_bfm_0_m0_translator:uav_readdata
	wire         mm_master_bfm_0_m0_translator_avalon_universal_master_0_debugaccess;          // mm_master_bfm_0_m0_translator:uav_debugaccess -> sram_bridge_16_0_avalon_slave_0_translator:uav_debugaccess
	wire   [1:0] mm_master_bfm_0_m0_translator_avalon_universal_master_0_byteenable;           // mm_master_bfm_0_m0_translator:uav_byteenable -> sram_bridge_16_0_avalon_slave_0_translator:uav_byteenable
	wire         mm_master_bfm_0_m0_translator_avalon_universal_master_0_readdatavalid;        // sram_bridge_16_0_avalon_slave_0_translator:uav_readdatavalid -> mm_master_bfm_0_m0_translator:uav_readdatavalid
	wire         sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_waitrequest;   // sram_bridge_16_0:waitrequest -> sram_bridge_16_0_avalon_slave_0_translator:av_waitrequest
	wire  [15:0] sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_writedata;     // sram_bridge_16_0_avalon_slave_0_translator:av_writedata -> sram_bridge_16_0:writedata
	wire  [19:0] sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_address;       // sram_bridge_16_0_avalon_slave_0_translator:av_address -> sram_bridge_16_0:address
	wire         sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_write;         // sram_bridge_16_0_avalon_slave_0_translator:av_write -> sram_bridge_16_0:write
	wire         sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_read;          // sram_bridge_16_0_avalon_slave_0_translator:av_read -> sram_bridge_16_0:read
	wire  [15:0] sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_readdata;      // sram_bridge_16_0:readdata -> sram_bridge_16_0_avalon_slave_0_translator:av_readdata
	wire         sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_readdatavalid; // sram_bridge_16_0:readdataready -> sram_bridge_16_0_avalon_slave_0_translator:av_readdatavalid
	wire   [1:0] sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_byteenable;    // sram_bridge_16_0_avalon_slave_0_translator:av_byteenable -> sram_bridge_16_0:byteenable
	wire         rst_controller_reset_out_reset;                                               // rst_controller:reset_out -> [mm_master_bfm_0:reset, mm_master_bfm_0_m0_translator:reset, sram_bridge_16_0_avalon_slave_0_translator:reset]
	wire         clk_clk;

	altera_avalon_clock_source #(
		.CLOCK_RATE (100)
	) clock_source_0 (
		.clk (clk_clk)  // clk.clk
	);

	altera_avalon_reset_source #(
		.ASSERT_HIGH_RESET    (1),
		.INITIAL_RESET_CYCLES (1)
	) reset_source_0 (
		.reset (rst_controller_reset_out_reset), // reset.reset
		.clk   (clk_clk)      //   clk.clk
	);

	altera_avalon_mm_master_bfm #(
		.AV_ADDRESS_W               (20),
		.AV_SYMBOL_W                (8),
		.AV_NUMSYMBOLS              (2),
		.AV_BURSTCOUNT_W            (1),
		.AV_READRESPONSE_W          (16),
		.AV_WRITERESPONSE_W         (16),
		.USE_READ                   (1),
		.USE_WRITE                  (1),
		.USE_ADDRESS                (1),
		.USE_BYTE_ENABLE            (1),
		.USE_BURSTCOUNT             (0),
		.USE_READ_DATA              (1),
		.USE_READ_DATA_VALID        (1),
		.USE_WRITE_DATA             (1),
		.USE_BEGIN_TRANSFER         (0),
		.USE_BEGIN_BURST_TRANSFER   (0),
		.USE_WAIT_REQUEST           (0),
		.USE_TRANSACTIONID          (0),
		.USE_WRITERESPONSE          (0),
		.USE_READRESPONSE           (0),
		.USE_CLKEN                  (0),
		.AV_CONSTANT_BURST_BEHAVIOR (0),
		.AV_BURST_LINEWRAP          (0),
		.AV_BURST_BNDR_ONLY         (0),
		.AV_MAX_PENDING_READS       (3),
		.AV_FIX_READ_LATENCY        (0),
		.AV_READ_WAIT_TIME          (0),
		.AV_WRITE_WAIT_TIME         (1),
		.REGISTER_WAITREQUEST       (0),
		.AV_REGISTERINCOMINGSIGNALS (0)
	) mm_master_bfm_0 (
		.clk                      (clk_clk),                          //       clk.clk
		.reset                    (rst_controller_reset_out_reset),   // clk_reset.reset
		.avm_address              (mm_master_bfm_0_m0_address),       //        m0.address
		.avm_readdata             (mm_master_bfm_0_m0_readdata),      //          .readdata
		.avm_writedata            (mm_master_bfm_0_m0_writedata),     //          .writedata
		.avm_waitrequest          (mm_master_bfm_0_m0_waitrequest),   //          .waitrequest
		.avm_write                (mm_master_bfm_0_m0_write),         //          .write
		.avm_read                 (mm_master_bfm_0_m0_read),          //          .read
		.avm_byteenable           (mm_master_bfm_0_m0_byteenable),    //          .byteenable
		.avm_readdatavalid        (mm_master_bfm_0_m0_readdatavalid), //          .readdatavalid
		.avm_burstcount           (),                                 // (terminated)
		.avm_begintransfer        (),                                 // (terminated)
		.avm_beginbursttransfer   (),                                 // (terminated)
		.avm_arbiterlock          (),                                 // (terminated)
		.avm_lock                 (),                                 // (terminated)
		.avm_debugaccess          (),                                 // (terminated)
		.avm_transactionid        (),                                 // (terminated)
		.avm_readresponse         (16'b0000000000000000),             // (terminated)
		.avm_readid               (8'b00000000),                      // (terminated)
		.avm_writeresponserequest (),                                 // (terminated)
		.avm_writeresponse        (16'b0000000000000000),             // (terminated)
		.avm_writeresponsevalid   (1'b0),                             // (terminated)
		.avm_writeid              (8'b00000000),                      // (terminated)
		.avm_clken                ()                                  // (terminated)
	);

	sram_bridge #(
		.ADDR_WIDTH (20)
	) sram_bridge_16_0 (
		.byteenable      (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_byteenable),    //           avalon_slave_0.byteenable
		.read            (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_read),          //                         .read
		.readdata        (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_readdata),      //                         .readdata
		.write           (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_write),         //                         .write
		.writedata       (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_writedata),     //                         .writedata
		.waitrequest     (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_waitrequest),   //                         .waitrequest
		.address         (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_address),       //                         .address
		.readdataready   (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_readdatavalid), //                         .readdatavalid
		.clock           (clk_clk),                                                                      //               clock_sink.clk
		.nreset          (reset_reset_n),                                                                //               reset_sink.reset_n
		.m_clock         (sram_bridge_conduit_clock),                                                    // avalon_mm_master_conduit.export
		.m_address       (sram_bridge_conduit_address),                                                  //                         .export
		.m_byteenable    (sram_bridge_conduit_byteenable),                                               //                         .export
		.m_readdata      (sram_bridge_conduit_readdata),                                                 //                         .export
		.m_read          (sram_bridge_conduit_read),                                                     //                         .export
		.m_write         (sram_bridge_conduit_write),                                                    //                         .export
		.m_writedata     (sram_bridge_conduit_writedata),                                                //                         .export
		.m_waitrequest   (sram_bridge_conduit_waitrequest),                                              //                         .export
		.m_readdataready (sram_bridge_conduit_readdataready)                                             //                         .export
	);

	altera_merlin_master_translator #(
		.AV_ADDRESS_W                (20),
		.AV_DATA_W                   (16),
		.AV_BURSTCOUNT_W             (1),
		.AV_BYTEENABLE_W             (2),
		.UAV_ADDRESS_W               (21),
		.UAV_BURSTCOUNT_W            (2),
		.USE_READ                    (1),
		.USE_WRITE                   (1),
		.USE_BEGINBURSTTRANSFER      (0),
		.USE_BEGINTRANSFER           (0),
		.USE_CHIPSELECT              (0),
		.USE_BURSTCOUNT              (0),
		.USE_READDATAVALID           (1),
		.USE_WAITREQUEST             (1),
		.AV_SYMBOLS_PER_WORD         (2),
		.AV_ADDRESS_SYMBOLS          (0),
		.AV_BURSTCOUNT_SYMBOLS       (0),
		.AV_CONSTANT_BURST_BEHAVIOR  (0),
		.UAV_CONSTANT_BURST_BEHAVIOR (0),
		.AV_LINEWRAPBURSTS           (0),
		.AV_REGISTERINCOMINGSIGNALS  (1)
	) mm_master_bfm_0_m0_translator (
		.clk                   (clk_clk),                                                               //                       clk.clk
		.reset                 (rst_controller_reset_out_reset),                                        //                     reset.reset
		.uav_address           (mm_master_bfm_0_m0_translator_avalon_universal_master_0_address),       // avalon_universal_master_0.address
		.uav_burstcount        (mm_master_bfm_0_m0_translator_avalon_universal_master_0_burstcount),    //                          .burstcount
		.uav_read              (mm_master_bfm_0_m0_translator_avalon_universal_master_0_read),          //                          .read
		.uav_write             (mm_master_bfm_0_m0_translator_avalon_universal_master_0_write),         //                          .write
		.uav_waitrequest       (mm_master_bfm_0_m0_translator_avalon_universal_master_0_waitrequest),   //                          .waitrequest
		.uav_readdatavalid     (mm_master_bfm_0_m0_translator_avalon_universal_master_0_readdatavalid), //                          .readdatavalid
		.uav_byteenable        (mm_master_bfm_0_m0_translator_avalon_universal_master_0_byteenable),    //                          .byteenable
		.uav_readdata          (mm_master_bfm_0_m0_translator_avalon_universal_master_0_readdata),      //                          .readdata
		.uav_writedata         (mm_master_bfm_0_m0_translator_avalon_universal_master_0_writedata),     //                          .writedata
		.uav_lock              (mm_master_bfm_0_m0_translator_avalon_universal_master_0_lock),          //                          .lock
		.uav_debugaccess       (mm_master_bfm_0_m0_translator_avalon_universal_master_0_debugaccess),   //                          .debugaccess
		.av_address            (mm_master_bfm_0_m0_address),                                            //      avalon_anti_master_0.address
		.av_waitrequest        (mm_master_bfm_0_m0_waitrequest),                                        //                          .waitrequest
		.av_byteenable         (mm_master_bfm_0_m0_byteenable),                                         //                          .byteenable
		.av_read               (mm_master_bfm_0_m0_read),                                               //                          .read
		.av_readdata           (mm_master_bfm_0_m0_readdata),                                           //                          .readdata
		.av_readdatavalid      (mm_master_bfm_0_m0_readdatavalid),                                      //                          .readdatavalid
		.av_write              (mm_master_bfm_0_m0_write),                                              //                          .write
		.av_writedata          (mm_master_bfm_0_m0_writedata),                                          //                          .writedata
		.av_burstcount         (1'b1),                                                                  //               (terminated)
		.av_beginbursttransfer (1'b0),                                                                  //               (terminated)
		.av_begintransfer      (1'b0),                                                                  //               (terminated)
		.av_chipselect         (1'b0),                                                                  //               (terminated)
		.av_lock               (1'b0),                                                                  //               (terminated)
		.av_debugaccess        (1'b0),                                                                  //               (terminated)
		.uav_clken             (),                                                                      //               (terminated)
		.av_clken              (1'b1)                                                                   //               (terminated)
	);

	altera_merlin_slave_translator #(
		.AV_ADDRESS_W                   (20),
		.AV_DATA_W                      (16),
		.UAV_DATA_W                     (16),
		.AV_BURSTCOUNT_W                (1),
		.AV_BYTEENABLE_W                (2),
		.UAV_BYTEENABLE_W               (2),
		.UAV_ADDRESS_W                  (21),
		.UAV_BURSTCOUNT_W               (2),
		.AV_READLATENCY                 (0),
		.USE_READDATAVALID              (1),
		.USE_WAITREQUEST                (1),
		.USE_UAV_CLKEN                  (0),
		.AV_SYMBOLS_PER_WORD            (2),
		.AV_ADDRESS_SYMBOLS             (0),
		.AV_BURSTCOUNT_SYMBOLS          (0),
		.AV_CONSTANT_BURST_BEHAVIOR     (0),
		.UAV_CONSTANT_BURST_BEHAVIOR    (0),
		.AV_REQUIRE_UNALIGNED_ADDRESSES (0),
		.CHIPSELECT_THROUGH_READLATENCY (0),
		.AV_READ_WAIT_CYCLES            (0),
		.AV_WRITE_WAIT_CYCLES           (0),
		.AV_SETUP_WAIT_CYCLES           (0),
		.AV_DATA_HOLD_CYCLES            (0)
	) sram_bridge_16_0_avalon_slave_0_translator (
		.clk                   (clk_clk),                                                                      //                      clk.clk
		.reset                 (rst_controller_reset_out_reset),                                               //                    reset.reset
		.uav_address           (mm_master_bfm_0_m0_translator_avalon_universal_master_0_address),              // avalon_universal_slave_0.address
		.uav_burstcount        (mm_master_bfm_0_m0_translator_avalon_universal_master_0_burstcount),           //                         .burstcount
		.uav_read              (mm_master_bfm_0_m0_translator_avalon_universal_master_0_read),                 //                         .read
		.uav_write             (mm_master_bfm_0_m0_translator_avalon_universal_master_0_write),                //                         .write
		.uav_waitrequest       (mm_master_bfm_0_m0_translator_avalon_universal_master_0_waitrequest),          //                         .waitrequest
		.uav_readdatavalid     (mm_master_bfm_0_m0_translator_avalon_universal_master_0_readdatavalid),        //                         .readdatavalid
		.uav_byteenable        (mm_master_bfm_0_m0_translator_avalon_universal_master_0_byteenable),           //                         .byteenable
		.uav_readdata          (mm_master_bfm_0_m0_translator_avalon_universal_master_0_readdata),             //                         .readdata
		.uav_writedata         (mm_master_bfm_0_m0_translator_avalon_universal_master_0_writedata),            //                         .writedata
		.uav_lock              (mm_master_bfm_0_m0_translator_avalon_universal_master_0_lock),                 //                         .lock
		.uav_debugaccess       (mm_master_bfm_0_m0_translator_avalon_universal_master_0_debugaccess),          //                         .debugaccess
		.av_address            (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_address),       //      avalon_anti_slave_0.address
		.av_write              (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_write),         //                         .write
		.av_read               (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_read),          //                         .read
		.av_readdata           (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_readdata),      //                         .readdata
		.av_writedata          (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_writedata),     //                         .writedata
		.av_byteenable         (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_byteenable),    //                         .byteenable
		.av_readdatavalid      (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_readdatavalid), //                         .readdatavalid
		.av_waitrequest        (sram_bridge_16_0_avalon_slave_0_translator_avalon_anti_slave_0_waitrequest),   //                         .waitrequest
		.av_begintransfer      (),                                                                             //              (terminated)
		.av_beginbursttransfer (),                                                                             //              (terminated)
		.av_burstcount         (),                                                                             //              (terminated)
		.av_writebyteenable    (),                                                                             //              (terminated)
		.av_lock               (),                                                                             //              (terminated)
		.av_chipselect         (),                                                                             //              (terminated)
		.av_clken              (),                                                                             //              (terminated)
		.uav_clken             (1'b0),                                                                         //              (terminated)
		.av_debugaccess        (),                                                                             //              (terminated)
		.av_outputenable       ()                                                                              //              (terminated)
	);



endmodule