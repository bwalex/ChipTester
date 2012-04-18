module PLL_INTERFACE
	(

	input   clock,
	input   reset_n,
	input   trigger,
	input [15:0] PLL_DATA,
	
	output	c0,
	output	locked,

	output   busy,
	output   [8:0]  data_out

	
	);
	
	
	wire pll_areset;
	wire pll_configupdate;
	wire pll_scanclk;
	wire pll_scanclkena;
	wire pll_scandata;
	wire	areset;
	wire	configupdate;
	wire	scanclk;
	wire	scanclkena;
	wire	scandata;
	wire pll_scandataout;
	wire pll_scandone;
	wire	scandataout;
	wire	scandone;
	wire write_param;
	wire rec_reset;
	wire reconfig;
	wire pfdena;
	wire read_param;
	wire [2:0]  counter_param;
	wire [3:0]  counter_type;
	wire pll_areset_in;
	wire [8:0]  data_in;
	wire [7:0]MultiFactor;
   wire [7:0] DividFactor;
	wire reset;

   assign reset = ~reset_n;
	assign areset = pll_areset;
	assign configupdate = pll_configupdate;
	assign scanclk = pll_scanclk;
	assign scanclkena = pll_scanclkena;
	assign scandata = pll_scandata;
	assign pll_scandataout = scandataout;
	assign pll_scandone = scandone;
	assign MultiFactor = PLL_DATA[15:8];
	assign DividFactor = PLL_DATA[7:0];
	
	
	
REPLL_CONTROL ctr2
( reset,
  clock,
  trigger,
  busy,
  MultiFactor,
  DividFactor,
 	counter_param,
	counter_type,
  rec_reset,
	pll_areset_in,
	write_param,
	reconfig,
	pfdena,
	read_param,
	data_in);	
	
 PLL p0
(
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
	
  REPLL_pllrcfg_1a01  pr0
	( 
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
