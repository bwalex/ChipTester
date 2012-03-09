module RingOscillator(output logic Q1,
                      input logic clock, Reset, Enable);

logic [3:0] count;

always_ff @(posedge clock, negedge Reset)
if(!Reset)
  begin
    Q1 = 1'b0;
    count <= 4'b0000;
  end
else if(Enable)
  if(count == 4'b1000) 
    count <=4'b0000;
  else
    count <= count + 1;


always_ff @(posedge count[3], negedge Reset)

if(!Reset) Q1 <= 0;
else Q1 <= ~Q1;


endmodule