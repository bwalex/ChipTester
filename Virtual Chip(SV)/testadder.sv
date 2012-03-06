module testadder;
  logic CarryOut;
  logic [3:0] AB;
  logic CarryIn;
  logic [3:0] A, B;
  
  Fulladder a0 (.*);
  
  

  initial
    begin
    A=4'b0000;
    B=4'b0000;
    CarryIn=1'b0;

    #100ns

    A=4'b0001;
    B=4'b0001;
    CarryIn=1'b0;
    
    #100ns

    A=4'b0010;
    B=4'b0100;
    CarryIn=1'b1; 
       
    end
  endmodule

