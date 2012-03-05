module check #(
  parameter ADDR_WIDTH = 20,
            DATA_WIDTH = 16,
            BE_WIDTH   = DATA_WIDTH/8,
            BUF_WIDTH  = 64,
            BOFF_WIDTH = 10,
            RTF_WIDTH  = 24,
            CHF_WIDTH  = RTF_WIDTH+ADDR_WIDTH, /* (output vector), (address), (or value) */
            SCC_WIDTH  = 5,
            SCD_WIDTH  = 24,
            RESULT_VECTOR_WORDS = 2
)(
  input                       clock,
  input                       reset_n,

  /* Avalon MM master interface to mem_if */
  output     [ADDR_WIDTH-1:0] mem_address,
  output     [  BE_WIDTH-1:0] mem_byteenable,
  output                      mem_write,
  output     [DATA_WIDTH-1:0] mem_writedata,
  input                       mem_waitrequest,

  /* RES_FIFO interface */
  input      [ RTF_WIDTH-1:0] rfifo_data,
  output                      rfifo_rdreq,
  input                       rfifo_rdempty,
  
  /* CHECK_FIFO interface */
  input      [ CHF_WIDTH-1:0] cfifo_data,
  output                      cfifo_rdreq,
  input                       cfifo_rdempty,

  /* CHECK <=> STIM interface */
  input      [ SCC_WIDTH-1:0] sc_cmd,
  input      [ SCD_WIDTH-1:0] sc_data,
  output                      sc_ready
);

  parameter META_RUN          = 8'b10000000;

  parameter SC_CMD_IDLE       = 5'b00000;
  parameter SC_CMD_BITMASK    = 5'b00001;

  parameter STATE_WIDTH       = 6;
  parameter IDLE              = 6'b000000;
  parameter RD_FIFOS          = 6'b000001;
  parameter CMP_AND_MASK      = 6'b000010;
  parameter COMPRESS          = 6'b000011;
  parameter WRITEBACK         = 6'b000100;
  parameter SETUP_BITMASK     = 6'b000110;

  reg    [ STATE_WIDTH-1:0] state;
  reg    [ STATE_WIDTH-1:0] next_state; /* comb */

  reg    [  ADDR_WIDTH-1:0] address;
  wire   [  ADDR_WIDTH-1:0] c_address;

  wire   [   RTF_WIDTH-1:0] c_result_vector;
  wire   [   RTF_WIDTH-1:0] result_vector;
  reg    [   RTF_WIDTH-1:0] result_bitmask;
  wire   [   RTF_WIDTH-1:0] bitmask;
  wire                      inc_address;
  wire                      load_address;
  wire                      load_bitmask;

  reg    [  BOFF_WIDTH-1:0] words_stored;
  wire                      reset_wstored; /* comb */
  wire   [DATA_WIDTH/2-1:0] meta_info;
  reg                       check_fail_r;
  wire                      check_fail;
  wire                      load_fail;
  reg    [             5:0] res_len;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      state <= IDLE;
    else
      state <= next_state;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      res_len <= RESULT_VECTOR_WORDS;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      address <= 'b0;
    else if (load_address)
      address <= c_address;
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
      check_fail_r <= 0;
    else if (load_fail)
      check_fail_r <= check_fail;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      result_bitmask <= 'hFFFFFFFF;
    else if (load_bitmask)
      result_bitmask <= bitmask;


  assign sc_ready       =    (state == IDLE && rfifo_rdempty && cfifo_rdempty);
  assign reset_wstored  =    (state == IDLE);

  assign mem_address    = address;
  assign mem_byteenable = 2'b11;
  assign mem_write      =    (state == WRITEBACK);

  assign rfifo_rdreq    =    (state == RD_FIFOS);
  assign cfifo_rdreq    =    (state == RD_FIFOS);
  assign load_address   =    (state == CMP_AND_MASK);

  assign load_fail      =    (state == CMP_AND_MASK);

  assign check_fail     = (c_result_vector != result_vector);

  assign inc_address    = (mem_write && ~mem_waitrequest);

  assign load_bitmask     = (sc_cmd == SC_CMD_BITMASK);
  assign bitmask          = sc_data;

  assign c_result_vector  = cfifo_data[CHF_WIDTH-1                      -: RTF_WIDTH ] & result_bitmask;
  assign c_address        = cfifo_data[CHF_WIDTH-RTF_WIDTH-1            -: ADDR_WIDTH];
  assign meta_info        = 8'b0 | META_RUN | check_fail_r;
  assign result_vector    = rfifo_data & result_bitmask;
  assign mem_writedata    = (words_stored == 0) ?
                                  result_vector[RTF_WIDTH-1            -: DATA_WIDTH  ] :
                                { result_vector[RTF_WIDTH-DATA_WIDTH-1 -: DATA_WIDTH/2], meta_info };


  always @(
       state
    or rfifo_rdempty
    or cfifo_rdempty
    or mem_waitrequest
    or words_stored
    or res_len
    or sc_cmd/* XXX */)
  begin
    next_state    = state;

    case (state)
      IDLE: begin
        if (~rfifo_rdempty && ~cfifo_rdempty)
          next_state = RD_FIFOS;
      end

      RD_FIFOS: begin
        next_state = CMP_AND_MASK;
      end

      CMP_AND_MASK: begin
        next_state = WRITEBACK;
      end

      WRITEBACK: begin
        if (words_stored == (res_len - 1))
          next_state = IDLE;
      end
    endcase
  end
endmodule
