module test_runner #(
  parameter ADDR_WIDTH = 8,
            DATA_WIDTH = 8,
            NREGS      = ((1<<7))
)(
  input                   clock,
  input                   nreset,

  /* XXX: as usual, data I/o is not parameterized because altera messes it up */

  /* Avalon MM slave interface */
  input      [ADDR_WIDTH-1:0] address,

  input                       read,
  output reg [           7:0] readdata,
  output reg                  readdatavalid,

  input                       write,
  input      [           7:0] writedata,


  /* Avalon Interrupt sender interface */
  output                  irq,


  /* Conduit */
  output reg              enable,
  output reg              busy,
  input                   done
);

  // Register map is currently as follows:
  // 128 real registers (addresses 0    - 0x7f)
  // 128 fake registers (addresses 0x80 - 0xFF)
  //
  // 0x0A: interrupt register - lowest bit is IRQ for TR
  // 0x7F: special ID: 0x0A
  //
  // fake registers are not stored in the register file, but are mapped to
  // special registers or direct I/O:
  //
  // 0x80: done input
  // 0x81: enable output
  parameter REG_IRQ     = 'h0A;
  parameter REG_ID      = NREGS-1;
  parameter REG_DONE    = 'h80;
  parameter REG_ENABLE  = 'h81;

  // Fields in REG_IRQ
  parameter IRQ_TR      = 0;


  assign irq = (regfile[REG_IRQ] != 8'h0);


  reg    [DATA_WIDTH-1:0] regfile [NREGS];

  reg                     done_d1;


  integer i;

  always @(posedge clock, negedge nreset)
    if (~nreset) begin
      for (i = 0; i < NREGS; i = i+1)
        regfile[i] <= 'b0;

      // Assign default set values
      regfile[NREGS-1] <= 8'h0A;
    end
    else if (done && ~done_d1) /* Positive edge-triggered IRQ */
      regfile[REG_IRQ][IRQ_TR] <= 1'b1;
    else if (write && (address < NREGS))
      regfile[address] <= writedata;
    else if (read && (address == REG_IRQ)) /* Clear IRQ reg when read */
      regfile[REG_IRQ] <= 'b0;


  always @(posedge clock, negedge nreset)
    if (~nreset)
      enable <= 1'b0;
    else if (write && (address == REG_ENABLE))
      enable <= writedata[0]; 
    else if (enable)
      enable <= 1'b0;


  always @(posedge clock, negedge nreset)
    if (~nreset)
      readdata <= 'b0;
    else if (read)
      if (address < NREGS)
        readdata <= regfile[address];
      else begin
        case(address)
          REG_DONE: readdata <= {7'b0 , done};
        endcase
      end


  always @(posedge clock, negedge nreset)
    if (~nreset)
      readdatavalid <= 1'b0;
    else
      readdatavalid <= read;


  always @(posedge clock, negedge nreset)
    if (~nreset)
      done_d1 <= 1'b0;
    else
      done_d1 <= done;


  always @(posedge clock, negedge nreset)
    if (~nreset)
      busy <= 1'b0;
    else if (enable)
      busy <= 1'b1;
    else if (done)
      busy <= 1'b0;

endmodule
