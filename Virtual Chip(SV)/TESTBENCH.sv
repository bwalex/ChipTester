module TESTBENCH;
  logic [0:7]aout, bout, cout;
  logic clk;
  logic [0:7]ain, bin, cin;
  
  
  VirtualChip v0 (.*);
  
  
  initial
    begin
      clk= '0;
      forever #5ns clk = ~clk;
    end
    

  initial
    begin
    ain =8'b01100000;
    bin =8'b00000000;
    cin =8'b00000000;

    #100ns

    ain = 8'b00101000;
    bin = 8'b00111100;
    cin = 8'b00000010;
    
    #100ns

    ain = 8'b01100010;
    bin = 8'b01110000;
    cin = 8'b00000010;
    
    #100ns
    ain = 8'b01100001;
    bin = 8'b00101000;
    cin = 8'b10101001;    
    
    #100ns
    ain = 8'b01100110;
    bin = 8'b00100000;
    cin = 8'b10101001;
    
    end
  endmodule








