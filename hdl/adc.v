module adc #(
  parameter ADDR_WIDTH = 20,
            DATA_WIDTH = 16,
            BE_WIDTH   = DATA_WIDTH/8,
            ADC_WIDTH  = 8,
            COUNT_WIDTH = 5 /* only need 15 clock cycles; 32 is on the side of caution */
)(
  input                   clock,
  input                   reset_n,

  input                   enable,
  output                  done,

  /* Avalon MM master interface to mem_if */
  output reg [ADDR_WIDTH-1:0] mem_address,
  output     [  BE_WIDTH-1:0] mem_byteenable,
  output reg                  mem_write,
  output reg [DATA_WIDTH-1:0] mem_writedata,
  input                       mem_waitrequest,

  /* ADC Interface */
  output                  adc_pwrdwn,
  output                  adc_clock,
  output                  adc_clock_en,
  input  [ ADC_WIDTH-1:0] adc_d
);


  wire                    last_address;
  wire                    zero_address;
  wire                    inc_address;

  reg   [COUNT_WIDTH-1:0] pwrup_counter;   

  assign adc_clock     = clock;
  assign adc_pwrdwn    = (state == END);
  assign adc_clock_en  = (state != END);

  assign mem_byteenable = 2'b11;


  parameter STATE_WIDTH  = 6;
  parameter IDLE         = 6'b000001;
  parameter POWERUP      = 6'b000010;
  parameter SAMPLE1      = 6'b000100;
  parameter SAMPLE2      = 6'b001000;
  parameter END          = 6'b100000;


  reg    [ STATE_WIDTH-1:0] state;
  reg    [ STATE_WIDTH-1:0] next_state; /* comb */


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      mem_address <= 'b0;
    else if (zero_address)
      mem_address <= 'b0;
    else if (inc_address)
      mem_address <= mem_address + 1;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      pwrup_counter <= 5'b11111;
    else if (state == IDLE)
      pwrup_counter <= 5'b11111;
    else if (state == POWERUP && pwrup_counter >= 1)
      pwrup_counter <= pwrup_counter - 1;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      mem_writedata                  <= 'b0;
    else if (state == SAMPLE1)
      mem_writedata[15 -: ADC_WIDTH] <= adc_d;
    else if (state == SAMPLE2)
      mem_writedata[7  -: ADC_WIDTH] <= adc_d;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      mem_write <= 1'b0;
    else if (state == SAMPLE2)
      mem_write <= 1'b1;
    else
      mem_write <= 1'b0;


  always @(posedge clock, negedge reset_n)
    if (~reset_n)
      state <= END;
    else
      state <= next_state;


  assign last_address  = (mem_address == ((1 << ADDR_WIDTH) - 1));
  assign done          = (state == END);
  assign zero_address  = (state == END);
  assign inc_address   = (mem_write && ~mem_waitrequest);


  always @(
       state
    or enable
    or last_address
    or pwrup_counter
    or mem_waitrequest)
  begin
    next_state  = state;
    case (state)
      IDLE: begin
        if (~mem_waitrequest)
          next_state = POWERUP;
      end

      POWERUP: begin
        if (pwrup_counter == 0)
          next_state = SAMPLE1;
      end

      SAMPLE1: begin
        next_state   = SAMPLE2;
      end

      SAMPLE2: begin
        if (last_address)
          next_state = END;
        else
          next_state = SAMPLE1;
      end

      END: begin
        if (enable)
          next_state = IDLE;
      end
    endcase
  end
endmodule // adc
