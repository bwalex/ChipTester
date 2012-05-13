module de2115sys(
  input         clock_50,
  input         reset_n, /* XXX: unused */

  output        SMA_CLKOUT,

  // SDRAM
  output [12:0] DRAM_ADDR,
  output [ 1:0] DRAM_BA,
  output        DRAM_CAS_N,
  output        DRAM_CKE,
  output        DRAM_CLK,
  output        DRAM_CS_N,
  inout  [31:0] DRAM_DQ,
  output [ 3:0] DRAM_DQM,
  output        DRAM_RAS_N,
  output        DRAM_WE_N,

  // SRAM
  output [19:0] SRAM_ADDR,
  inout  [15:0] SRAM_DQ,
  output        SRAM_CE_N,
  output        SRAM_OE_N,
  output        SRAM_WE_N,
  output [ 1:0] SRAM_BE_N,

  // Switch
  input         SW_SEL,

  // UART
  input         UART_RXD,
  input         UART_RTS,
  output        UART_TXD,
  output        UART_CTS,

  // LED
  output [ 3:0] LEDR,
  output        LEDG,
  output        LEDG0,
  output        LEDG4,
  
  //////////// I2C for EEPROM //////////
  output        EEP_I2C_SCLK,
  inout         EEP_I2C_SDAT,

  //////////// SDCARD //////////
  output        SD_CLK,
  output        SD_CMD,
  input         SD_DAT0,
  output        SD_DAT3,
  input         SD_WP_N, /* XXX: unused */

 //////////// LCD //////////
  output        LCD_BLON,
  inout  [ 7:0] LCD_DATA,
  output        LCD_EN,
  output        LCD_ON,
  output        LCD_RS,
  output        LCD_RW,

 //////////// Flash //////////
  output [22:0] FL_ADDR,
  output        FL_CE_N,
  inout  [ 7:0] FL_DQ,
  output        FL_OE_N,
  output        FL_RST_N,
  input         FL_RY,   /* XXX: unused */
  output        FL_WE_N,
  output        FL_WP_N,

 //////////// USB OTG controller //////////
  inout  [15:0] OTG_DATA,
  output [ 1:0] OTG_ADDR,
  output        OTG_CS_N,
  output        OTG_WR_N,
  output        OTG_RD_N,
  input  [ 1:0] OTG_INT,
  output        OTG_RST_N,
  input  [ 1:0] OTG_DREQ,
  output [ 1:0] OTG_DACK_N,
  inout         OTG_FSPEED,
  inout         OTG_LSPEED,

  // Ethernet
  output        ENET0_GTX_CLK,
  input         ENET0_INT_N,  /* XXX: unused */
  output        ENET0_MDC,
  inout         ENET0_MDIO,
  output        ENET0_RST_N,
  input         ENET0_RX_CLK,
  input         ENET0_RX_COL, /* XXX: unused */
  input         ENET0_RX_CRS, /* XXX: unused */
  input  [ 3:0] ENET0_RX_DATA,
  input         ENET0_RX_DV,
  input         ENET0_RX_ER,
  input         ENET0_TX_CLK, /* XXX: unused */
  output [ 3:0] ENET0_TX_DATA,
  output        ENET0_TX_EN,
  output        ENET0_TX_ER,  /* XXX: no driver */
  input         ENET0_LINK100 /* XXX: unused */
);

  wire          clock_100;
  wire          clock_10;
  wire          global_reset_n;

  wire          dyn_clock;

  wire          enet_tx_clk_mac;
  wire          enet_tx_clk_phy;
  wire          enet_rx_clk_270deg;

  wire          enet_gtx_clk;
  wire          enet_rx_clk;

  wire          enet_resetn;
  
  wire          NET0_mdio_in;
  wire          NET0_mdio_oen;
  wire          NET0_mdio_out;
  
  wire          ena_10_from_the_tse_mac;
  wire          eth_mode_from_the_tse_mac;
  wire          set_1000_to_the_tse_mac;
  wire          set_10_to_the_tse_mac;

  wire          UART_CTS_n;

  wire          sopc_sram_clock;
  wire   [19:0] sopc_sram_address;
  wire   [ 1:0] sopc_sram_byteenable;
  wire          sopc_sram_read;
  wire   [15:0] sopc_sram_readdata;
  wire          sopc_sram_readdataready;
  wire          sopc_sram_write;
  wire   [15:0] sopc_sram_writedata;
  wire          sopc_sram_waitrequest;

  wire   [19:0] tr_sram_address;
  wire   [ 1:0] tr_sram_byteenable;
  wire          tr_sram_read;
  wire   [15:0] tr_sram_readdata;
  wire          tr_sram_readdataready;
  wire          tr_sram_write;
  wire   [15:0] tr_sram_writedata;
  wire          tr_sram_waitrequest;

  wire   [ 3:0] func_sel;

  wire          sram_arb_msel;

  wire          tr_done;
  wire          tr_enable;

  wire   [23:0] temp_test;
  wire   [23:0] tr_miso;
  wire   [23:0] tr_mosi;
  wire   [ 4:0] tr_target_sel;

  wire          sigtap_clk;


  assign temp_test  = {tr_miso[23:3], dyn_clock, clock_10, tr_miso[0]};


  assign SMA_CLKOUT = dyn_clock;

  assign UART_CTS = ~UART_CTS_n;

  // Ethernet
  assign enet_rx_clk             = ENET0_RX_CLK;
  //assign enet_tx_clk             = ENET0_TX_CLK;
  assign ENET0_GTX_CLK           = enet_gtx_clk;

  assign NET0_mdio_in            = ENET0_MDIO;
  assign ENET0_MDIO              = NET0_mdio_oen ? 1'bz : NET0_mdio_out;

  assign ENET0_RST_N             = enet_resetn;
  assign set_1000_to_the_tse_mac = 1'b0;
  assign set_10_to_the_tse_mac   = 1'b0;


  // Flash
  assign FL_RST_N   = global_reset_n;
  assign FL_WP_N    = 1'b1;


  // USB (OTG)
  assign OTG_DACK_N = OTG_DREQ;
  assign OTG_FSPEED = 1'b1;
  assign OTG_LSPEED = 1'b0;


  // LCD
  assign LCD_BLON   = 0;    // not supported
  assign LCD_ON     = 1'b1; // alwasy on


  ddr_o phy_ckgen
  (
    .datain_h (1'b1),
    .datain_l (1'b0),
    .outclock (enet_tx_clk_phy),
    .dataout  (enet_gtx_clk)
  );
  //assign enet_gtx_clk = 1'b0;

  
  enet_rx_clk_pll enet_rx_clk_pll
  (
    .inclk0 (enet_rx_clk),
    .c0     (enet_rx_clk_270deg),
    .c1     (enet_tx_clk_mac),
    .c2     (enet_tx_clk_phy)
  );
  

  gen_reset_n system_gen_reset_n (
    .tx_clk      (clock_50),
    .reset_n_in  (1'b1),
    .reset_n_out (global_reset_n)
  );

  gen_reset_n net_gen_reset_n(
    .tx_clk      (clock_50),
    .reset_n_in  (global_reset_n),
    .reset_n_out (enet_resetn)
  );

  assign LEDG = sopc_sram_waitrequest;
  assign LEDG0 = tr_sram_waitrequest;

  sigtap_pll sigtap_clock (
    .inclk0(sopc_sram_clock),
    .c0(sigtap_clk)
  );

  /* XXX: temporary PLL. should move as reconfig into tester mod */
  pll_10 pll10 (
    .areset(1'b0),
    .inclk0(clock_50),
    .c0(clock_10)
  );

  sram_arb_sync#(
    .ADDR_WIDTH (20),
    .DATA_WIDTH (16),
    .SEL_WIDTH  (1)
  ) sram_arb
  (
    .clock               (clock_100),
    .reset_n             (global_reset_n),

    .sel                 (sram_arb_msel),

    .sram_address        (SRAM_ADDR),
    .sram_data           (SRAM_DQ),
    .sram_ce_n           (SRAM_CE_N),
    .sram_oe_n           (SRAM_OE_N),
    .sram_we_n           (SRAM_WE_N),
    .sram_be_n           (SRAM_BE_N),

    .sopc_address        (sopc_sram_address),
    .sopc_byteenable     (sopc_sram_byteenable),
    .sopc_read           (sopc_sram_read),
    .sopc_readdata       (sopc_sram_readdata),
    .sopc_readdataready  (sopc_sram_readdataready),
    .sopc_write          (sopc_sram_write),
    .sopc_writedata      (sopc_sram_writedata),
    .sopc_waitrequest    (sopc_sram_waitrequest),

    .tr_address          (tr_sram_address),
    .tr_byteenable       (tr_sram_byteenable),
    .tr_read             (tr_sram_read),
    .tr_readdata         (tr_sram_readdata),
    .tr_readdataready    (tr_sram_readdataready),
    .tr_write            (tr_sram_write),
    .tr_writedata        (tr_sram_writedata),
    .tr_waitrequest      (tr_sram_waitrequest)
  );


  tester#(
    .ADDR_WIDTH          (20),
    .DATA_WIDTH          (16),
    .WAIT_WIDTH          (4)
  ) tester
  (
    .clock               (clock_100),
    .reset_n             (global_reset_n),
    .fifo_clock          (clock_10),

    .dyn_clock           (dyn_clock),

    .enable              (tr_enable),
    .done                (tr_done),

    .address             (tr_sram_address),
    .byteenable          (tr_sram_byteenable),
    .readdata            (tr_sram_readdata),
    .read                (tr_sram_read),
    .readdataready       (tr_sram_readdataready),
    .write               (tr_sram_write),
    .writedata           (tr_sram_writedata),
    .waitrequest         (tr_sram_waitrequest),

    .target_sel          (tr_target_sel),
    .mosi                (tr_mosi),
    .miso                (tr_miso)
  );


  /* XXX: Effectively the DUT/CUT , a 1-bit left shifter */
  assign tr_miso  = tr_mosi << 1;



  linuxsys u0 (
    .clk_0                                  (clock_50),
    .reset_n                                (global_reset_n),

    .altpll_sys                             (clock_100),
//  .phasedone_from_the_altpll_0            (<connected-to-phasedone_from_the_altpll_0>),
//  .c0_out_clk_out                         (<connected-to-c0_out_clk_out>),
//  .areset_to_the_altpll_0                 (<connected-to-areset_to_the_altpll_0>),
//  .locked_from_the_altpll_0               (<connected-to-locked_from_the_altpll_0>),

    .altpll_sdram                           (DRAM_CLK),
    .zs_addr_from_the_sdram_0               (DRAM_ADDR),
    .zs_ba_from_the_sdram_0                 (DRAM_BA),
    .zs_cas_n_from_the_sdram_0              (DRAM_CAS_N),
    .zs_cke_from_the_sdram_0                (DRAM_CKE),
    .zs_cs_n_from_the_sdram_0               (DRAM_CS_N),
    .zs_dq_to_and_from_the_sdram_0          (DRAM_DQ),
    .zs_dqm_from_the_sdram_0                (DRAM_DQM),
    .zs_ras_n_from_the_sdram_0              (DRAM_RAS_N),
    .zs_we_n_from_the_sdram_0               (DRAM_WE_N),
    
    .address_to_the_cfi_flash_0             (FL_ADDR),
    .write_n_to_the_cfi_flash_0             (FL_WE_N),
    .data_to_and_from_the_cfi_flash_0       (FL_DQ),
    .read_n_to_the_cfi_flash_0              (FL_OE_N),
    .select_n_to_the_cfi_flash_0            (FL_CE_N),

    .USB_DATA_to_and_from_the_usb           (OTG_DATA),
    .USB_ADDR_from_the_usb                  (OTG_ADDR),
    .USB_RD_N_from_the_usb                  (OTG_RD_N),
    .USB_WR_N_from_the_usb                  (OTG_WR_N),
    .USB_CS_N_from_the_usb                  (OTG_CS_N),
    .USB_RST_N_from_the_usb                 (OTG_RST_N),
    .USB_INT0_to_the_usb                    (OTG_INT[0]),
    .USB_INT1_to_the_usb                    (OTG_INT[1]),

//    // MII interface
//    .tse_mac_conduit_connection_m_rx_d      (ENET0_RX_DATA),
//    .tse_mac_conduit_connection_m_rx_en     (ENET0_RX_DV),
//    .tse_mac_conduit_connection_m_rx_err    (ENET0_RX_ER),
//    .tse_mac_conduit_connection_m_tx_d      (ENET0_TX_DATA),
//    .tse_mac_conduit_connection_m_tx_en     (ENET0_TX_EN),
//    .tse_mac_conduit_connection_m_tx_err    (ENET0_TX_ER),
//    .tse_mac_conduit_connection_m_rx_col    (ENET0_RX_COL),
//    .tse_mac_conduit_connection_m_rx_crs    (ENET0_RX_CRS),
//    .tx_clk_to_the_tse_mac                  (enet_tx_clk),
//    .rx_clk_to_the_tse_mac                  (enet_rx_clk),
//    .set_10_to_the_tse_mac                  (set_10_to_the_tse_mac),
//    .set_1000_to_the_tse_mac                (set_1000_to_the_tse_mac),
//    .ena_10_from_the_tse_mac                (ena_10_from_the_tse_mac),
//    .eth_mode_from_the_tse_mac              (eth_mode_from_the_tse_mac),
//    .mdio_out_from_the_tse_mac              (NET0_mdio_out),
//    .mdio_oen_from_the_tse_mac              (NET0_mdio_oen),
//    .mdio_in_to_the_tse_mac                 (NET0_mdio_in),
//    .mdc_from_the_tse_mac                   (ENET0_MDC),

    // RGMII interface
    .tse_mac_conduit_connection_rgmii_in    (ENET0_RX_DATA),
    .tse_mac_conduit_connection_rgmii_out   (ENET0_TX_DATA),
    .tse_mac_conduit_connection_rx_control  (ENET0_RX_DV),
    .tse_mac_conduit_connection_tx_control  (ENET0_TX_EN),
    .tx_clk_to_the_tse_mac                  (enet_tx_clk_mac),
    .rx_clk_to_the_tse_mac                  (enet_rx_clk_270deg),
    .set_10_to_the_tse_mac                  (set_10_to_the_tse_mac),
    .set_1000_to_the_tse_mac                (set_1000_to_the_tse_mac),
    .ena_10_from_the_tse_mac                (ena_10_from_the_tse_mac),
    .eth_mode_from_the_tse_mac              (eth_mode_from_the_tse_mac),
    .mdio_out_from_the_tse_mac              (NET0_mdio_out),
    .mdio_oen_from_the_tse_mac              (NET0_mdio_oen),
    .mdio_in_to_the_tse_mac                 (NET0_mdio_in),
    .mdc_from_the_tse_mac                   (ENET0_MDC),

    .lcd_external_data                      (LCD_DATA),
    .lcd_external_E                         (LCD_EN),
    .lcd_external_RS                        (LCD_RS),
    .lcd_external_RW                        (LCD_RW),

//  .sd_clk_external_connection_export      (SD_CLK),
//  .sd_cmd_external_connection_export      (SD_CMD),
//  .sd_dat_external_connection_export      (SD_DAT),
//  .sd_wp_n_external_connection_export     (SD_WP_N),

    .spi_0_external_MISO                    (SD_DAT0),
    .spi_0_external_MOSI                    (SD_CMD),
    .spi_0_external_SCLK                    (SD_CLK),
    .spi_0_external_SS_n                    (SD_DAT3),

//  .spi_1_external_MISO                    (),
//  .spi_1_external_MOSI                    (),
//  .spi_1_external_SCLK                    (),
//  .spi_1_external_SS_n                    (),

    .uart_0_external_rxd                    (UART_RXD),
    .uart_0_external_txd                    (UART_TXD),
    .uart_0_external_cts_n                  (UART_CTS_n),
    .uart_0_external_rts_n                  (~UART_RTS),

    .eep_i2c_scl_external_connection_export (EEP_I2C_SCLK),
    .eep_i2c_sda_external_connection_export (EEP_I2C_SDAT),

    .sram_conduit_clock                     (sopc_sram_clock),
    .sram_conduit_address                   (sopc_sram_address),
    .sram_conduit_byteenable                (sopc_sram_byteenable),
    .sram_conduit_readdata                  (sopc_sram_readdata),
    .sram_conduit_read                      (sopc_sram_read),
    .sram_conduit_readdataready             (sopc_sram_readdataready),
    .sram_conduit_write                     (sopc_sram_write),
    .sram_conduit_writedata                 (sopc_sram_writedata),
    .sram_conduit_waitrequest               (sopc_sram_waitrequest),

    .test_runner_conduit_done               (tr_done),
    .test_runner_conduit_enable             (tr_enable),
    .test_runner_conduit_busy               (sram_arb_msel),

    .freq_counter_external_in_signal        (temp_test),
    .freq_counter_external_busy             (LEDG4),

    .func_sel_external_connection_export    (LEDR)
  );

endmodule
