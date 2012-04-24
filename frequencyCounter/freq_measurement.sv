// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.2
//
// frequency measurement module - Measures the frequency of the input signal.
// 

module freq_measurement (
  output logic [12:0]out_value,
  input wire in_wave,
  input wire enable, Clock, nReset
);

timeunit 1ns; timeprecision 10ps;

logic previous, started ;
logic [12:0]measure ;

always_ff @(posedge Clock, negedge nReset)
  if (!nReset)      // asynchronous reset
  begin
    measure <= 0 ;
    previous <= 0 ;
    started <= 0 ;
    out_value <= 0 ;
  end
  else 
  if (enable)
    if (in_wave) begin
      if (!previous) begin
        measure <= 1 ;        // resets counter to 1 when input goes high
        previous <= 1 ;
        started <= 1 ;
        out_value <= measure ;
      end
      else if (started) measure <= measure + 1 ;
    end
    else if (started) begin
      measure <= measure + 1 ;
      previous <= 0 ;
    end

endmodule
