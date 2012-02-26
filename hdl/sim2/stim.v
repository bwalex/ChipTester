module stim #(
  parameter ADDR_WIDTH = 20,
            DATA_WIDTH = 16,
            BE_WIDTH   = DATA_WIDTH/8,
            BUF_WIDTH  = 64,
            BOFF_WIDTH = 10,
            STF_WIDTH  = 24,
            ORV_WIDTH  = 8,
            CHF_WIDTH  = STF_WIDTH+ORV_WIDTH+ADDR_WIDTH, /* (output vector), (address), (or value) */
            STFU_WIDTH = 4,
            CHFU_WIDTH = 4,
            SCC_WIDTH  = 5,
            SCD_WIDTH  = 24,
            WAIT_WIDTH = 16,
            DSEL_WIDTH = 5 /* Target design select */
)(
  input                       clock,
  input                       reset_n,


  /* Avalon MM master interface to mem_if */
  output     [ADDR_WIDTH-1:0] mem_address,
  output     [  BE_WIDTH-1:0] mem_byteenable,

  output                      mem_read,     /* comb */
  input      [DATA_WIDTH-1:0] mem_readdata,

  input                       mem_waitrequest,

  /* target interface */
  output reg [DSEL_WIDTH-1:0] target_sel,

  /* STIM_FIFO interface */
  output     [ STF_WIDTH-1:0] sfifo_data,
  output                      sfifo_wrreq, /* comb */
  input      [STFU_WIDTH-1:0] sfifo_wrusedw,
  input                       sfifo_wrfull,
  input                       sfifo_wrempty,
  
  /* CHECK_FIFO interface */
  output     [ CHF_WIDTH-1:0] cfifo_data,
  output                      cfifo_wrreq, /* comb */
  input      [CHFU_WIDTH-1:0] cfifo_wrusedw,
  input                       cfifo_wrfull,
  input                       cfifo_wrempty,

  /* CHECK <=> STIM interface */
  output reg [ SCC_WIDTH-1:0] sc_cmd,  /* comb */
  output reg [ SCD_WIDTH-1:0] sc_data, /* comb */
  output                      sc_switching,
  input                       sc_ready
);

  parameter SC_CMD_IDLE       = 5'b00000;
  parameter SC_CMD_BITMASK    = 5'b00001;

  parameter REQ_SWITCH_TARGET = 3'b000;
  parameter REQ_TEST_VECTOR   = 3'b001;
  parameter REQ_SETUP_BITMASK = 3'b010;

  parameter STATE_WIDTH       = 6;
  parameter IDLE              = 6'b000000;
  parameter READ_META         = 6'b000001;
  parameter READ_TV           = 6'b000010;
  parameter SWITCH_TARGET     = 6'b000011;
  parameter SWITCH_VDD        = 6'b000100;
  parameter WR_FIFOS          = 6'b000101;
  parameter SETUP_BITMASK     = 6'b000110;

  reg    [STATE_WIDTH-1:0] state;
  reg    [STATE_WIDTH-1:0] next_state; /* comb */

  reg    [ ADDR_WIDTH-1:0] address;
  wire                     inc_address;

  wire   [  STF_WIDTH-1:0] input_vector;
  wire   [  STF_WIDTH-1:0] result_vector;
  wire   [  STF_WIDTH-1:0] output_bitmask;
  wire   [ DSEL_WIDTH-1:0] new_target_sel;

  reg    [ WAIT_WIDTH-1:0] waitcnt;
  wire                     reset_waitcnt;
  wire                     change_target;

  reg    [  0:BUF_WIDTH-1] buffer;
  reg    [ BOFF_WIDTH-1:0] words_stored;
  wire                     reset_wstored; /* comb */
  wire   [ BOFF_WIDTH-1:0] buffer_offset;
  wire   [            3:0] req_type;
  reg    [            5:0] tv_len;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      state <= IDLE;
    else
      state <= next_state;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      tv_len <= 4;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      address <= 'b0;
    else if (inc_address)
      address <= address + 1;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      words_stored <= 0;
    else if (reset_wstored)
       words_stored <= 0;
    else if (inc_address)
      words_stored <= words_stored + 1;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      target_sel <= 0;
    else if (change_target)
      target_sel <= new_target_sel;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      waitcnt <= 'b0;
    else if (reset_waitcnt)
      waitcnt <= 'hFFFFFFFF;
    else if (waitcnt > 0)
      waitcnt <= waitcnt - 1;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      buffer <= 'b0;
    else if (mem_read && ~mem_waitrequest)
      buffer[(buffer_offset << 4) +: DATA_WIDTH] <= mem_readdata;


  assign mem_address    = address;
  assign mem_byteenable = 2'b11;
  assign mem_read       =    (state == IDLE          && (~sfifo_wrfull && ~cfifo_wrfull))
                          || (state == READ_META     && (req_type == REQ_TEST_VECTOR))
                          || (state == READ_META     && (req_type == REQ_SETUP_BITMASK))
                          || (state == SETUP_BITMASK && (words_stored != 2))
                          || (state == READ_TV       && (words_stored != tv_len));

  assign switching      =    (state == SWITCH_TARGET)
                          || (state == SWITCH_VDD);

  assign sfifo_wrreq    =    (state == WR_FIFOS);
  assign cfifo_wrreq    =    (state == WR_FIFOS);

  assign reset_waitcnt  =    (state == SWITCH_TARGET && next_state == SWITCH_VDD);

  assign reset_wstored  = (next_state == IDLE);
  assign change_target  = (next_state == SWITCH_VDD);


  assign inc_address    = (mem_read && ~mem_waitrequest);
  assign req_type       = buffer[0:2];
  assign input_vector   = buffer[8             +: STF_WIDTH];
  assign result_vector  = buffer[8+STF_WIDTH   +: STF_WIDTH];
  assign output_bitmask = buffer[8             +: STF_WIDTH];
  assign new_target_sel = buffer[16-DSEL_WIDTH +: DSEL_WIDTH];
  assign buffer_offset  = words_stored;

  assign sfifo_data     = input_vector;
  assign cfifo_data[CHF_WIDTH-1                      -: STF_WIDTH ] = result_vector;
  assign cfifo_data[CHF_WIDTH-STF_WIDTH-1            -: ADDR_WIDTH] = address-2;
  assign cfifo_data[CHF_WIDTH-STF_WIDTH-ADDR_WIDTH-1 -: ORV_WIDTH ] = 8'b0;



  always @(
       state
    or sfifo_wrfull
    or cfifo_wrfull
    or mem_waitrequest
    or req_type
    or words_stored
    or tv_len
    or input_vector
    or result_vector
    or address
    or cfifo_wrempty
    or sfifo_wrempty
    or waitcnt
	or sc_ready/* XXX */)
  begin
    next_state    = state;
    sc_cmd        = SC_CMD_IDLE;
    sc_data       = 'b0;

    case (state)
      IDLE: begin
        if (~sfifo_wrfull && ~cfifo_wrfull && ~mem_waitrequest)
          next_state = READ_META;
      end


      READ_META:
        case (req_type)
          REQ_SWITCH_TARGET:  next_state = SWITCH_TARGET;
          REQ_TEST_VECTOR:    next_state = READ_TV;
          REQ_SETUP_BITMASK:  next_state = SETUP_BITMASK;
          default:            next_state = IDLE;
        endcase


      SWITCH_TARGET: begin
        /* Wait for FIFOs to drain before switching Vdd */
        if (sfifo_wrempty && cfifo_wrempty)
          next_state = SWITCH_VDD;
      end


      SWITCH_VDD: begin
        if (waitcnt == 0)
          next_state = IDLE;
      end


      SETUP_BITMASK: begin
        if (words_stored == 2 && sc_ready) begin
          next_state = IDLE;

          sc_cmd  = SC_CMD_BITMASK;
          sc_data = output_bitmask;
        end
      end


      READ_TV: begin
        if (words_stored == tv_len)
          next_state = WR_FIFOS;
      end


      WR_FIFOS: begin
        next_state = IDLE;
      end
    endcase
  end
endmodule
