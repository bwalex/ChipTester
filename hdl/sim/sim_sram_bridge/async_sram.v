//[Disclaimer] Integrated Silicon Solutions Inc. ("ISSI") hereby grants the
// user of this model a non-exclusive, nontransferable
// license to use this model under the following terms.
// The user is granted this license only to use the model
// and is not granted rights to sell, copy (except as needed to
// run the model), rent, lease or sub-license the model
// in whole or in part, or in modified form to anyone.
// The User may modify the model to suit its specific
// applications, but rights to derivative works and such
// modifications shall belong to ISSI.
//
// This model is provided on an "AS IS" basis and ISSI
// makes absolutely no warranty with respect to the information
// contained herein. ISSI DISCLAIMS AND CUSTOMER WAIVES ALL
// WARRANTIES, EXPRESS AND IMPLIED, INCLUDING WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
// ENTIRE RISK AS TO QUALITY AND PERFORMANCE IS WITH THE
// USER ACCORDINGLY, IN NO EVENT SHALL ISSI BE LIABLE
// FOR ANY DIRECT OR INDIRECT DAMAGES, WHETHER IN CONTRACT OR
// TORT, INCLUDING ANY LOST PROFITS OR OTHER INCIDENTAL,
// CONSEQUENTIAL, EXEMPLARY, OR PUNITIVE DAMAGES ARISING OUT OF
// THE USE OR APPLICATION OF THE model. Further, ISSI
// reserves the right to make changes without notice to any
// product herein to improve reliability, function, or design.
// ISSI does not convey any license under patent rights or
// any other intellectual property rights, including those of
// third parties. ISSI is not obligated to provide maintenance
// or support for the licensed model.


// IS61LV6416L Asynchronous SRAM, 64K x 16 = 1M; speed: 10ns. File: ASRAM.8130.1
// Please include "+define+ OEb" in running script if you want to check 
// timing in the case of OE_ being set. 

`define OEb
`timescale 1ns/10ps

module async_sram (A, IO, CE_, OE_, WE_, LB_, UB_);

parameter dqbits = 16;
parameter memdepth = 1048576;
parameter addbits = 20;
parameter Taa   = 8;
parameter Toha  = 2.5;
parameter Thzce = 3;
parameter Tsa   = 0;
parameter Thzwe = 3.5;
parameter INIT_FILE = "sram.txt";
parameter USE_INIT  = 0;

input CE_, OE_, WE_, LB_, UB_;
input [(addbits - 1) : 0] A;
inout [(dqbits - 1) : 0] IO;
 
wire [(dqbits - 1) : 0] dout;
reg  [(dqbits/2 - 1) : 0] bank0 [0 : memdepth];
reg  [(dqbits/2 - 1) : 0] bank1 [0 : memdepth];
reg  [(dqbits - 1) : 0] tmp_reg [0 : memdepth];
// wire [(dqbits - 1) : 0] memprobe = {bank1[A], bank0[A]};

wire r_en = WE_ & (~CE_) & (~OE_);
wire w_en = (~WE_) & (~CE_) & ((~LB_) | (~UB_));
assign #(r_en ? Taa : Thzce) IO = r_en ? dout : 16'bz;   

assign dout [(dqbits/2 - 1) : 0]        = LB_ ? 8'bz : bank0[A];
assign dout [(dqbits - 1) : (dqbits/2)] = UB_ ? 8'bz : bank1[A];

always @(A or w_en)
  begin
    #Tsa
    if (w_en)
      #Thzwe
      begin
        bank0[A] = LB_ ? bank0[A] : IO [(dqbits/2 - 1) : 0];
        bank1[A] = UB_ ? bank1[A] : IO [(dqbits - 1)   : (dqbits/2)];
      end
  end

integer i;
  
initial begin
  if (USE_INIT)
  begin
    $readmemh(INIT_FILE, tmp_reg);
    for (i = 0; i < memdepth; i++)
    begin
      bank0[i] = tmp_reg[i][7 :0];
      bank1[i] = tmp_reg[i][15:8];
    end
  end
end

specify

  specparam

    tSA   = 0,
    tAW   = 6.5,
    tSCE  = 6.5,
    tSD   = 5,
    tPWE2 = 8,
    tPWE1 = 6.5,
    tPBW  = 6.5;

  $setup (A, negedge CE_, tSA);
  $setup (A, posedge CE_, tAW);
  $setup (IO, posedge CE_, tSD);
  $setup (A, negedge WE_, tSA);
  $setup (IO, posedge WE_, tSD);
  $setup (A, negedge LB_, tSA);
  $setup (A, negedge UB_, tSA);

  $width (negedge CE_, tSCE);
  $width (negedge LB_, tPBW);
  $width (negedge UB_, tPBW);
  `ifdef OEb
  $width (negedge WE_, tPWE1);
  `else
  $width (negedge WE_, tPWE2);
  `endif 

endspecify

endmodule

