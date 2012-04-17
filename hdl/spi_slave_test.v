module spi_slave_test(
  input       reset_n,
  input       sclk,
  input       sdi,
  output      sdo,
  input       cs_n
);

  reg   [ 7:0] cmd;
  reg   [23:0] val;
  reg   [ 3:0] cnt;


  assign sdo = val[23];


  always @(posedge sclk, posedge cs_n)
    if (cs_n)
      cnt <= 0;
    else if (~cs_n && (cnt < 9))
      cnt <= cnt + 1;


  always @(posedge sclk, negedge reset_n)
    if (~reset_n)
      cmd <= 8'b0;
    else if ((~cs_n) && (cnt <= 7))
      cmd <= { cmd[6:0] , sdi };


  always @(posedge sclk, negedge reset_n)
    if (~reset_n)
      val <= 24'b0;
    else if (cnt == 8)
      val <= cmd * cmd;
    else if (~cs_n)
      val <= { val[22:0] , 1'b0 };


endmodule