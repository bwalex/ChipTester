module VirtualChip(output [0:7]aout, bout, cout,
                   input clk, input  [0:7]ain, bin, cin);
// the clk is not a real pin on the chip, it simply mimics the analog part on the 
// real thing to provide the funtionality as an oscillator. 
// It should be connected to a clock from the FPGA system
Inverter inverter(aout[0], ain[0]);
RingOscillator ringOscillator(clk, ain[1:3]);
Fulladder fulladder(aout[1:5],ain[4:7],bin[0:4]);
Recognition8 recognition8(aout[5:6], bin[5:7]);
//LongRecognition longrecognition(aout[7],bout[0], cin[0:2]);

endmodule