module testoscillator;

  logic clock;
  logic Q1, Reset, Enable;
  
  
  RingOscillator r0 (.*);
  
  
  initial
    begin
      clock= '0;
      forever #5ns clock = ~clock;
    end
    
    
    initial
    begin
      Enable = 1'b1;
      Reset  = 1'b1;
      #50ns Reset = 1'b0;
      #50ns Reset = 1'b1;
end
endmodule