// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.3
//
// frequency measurement module - Measures the frequency of the input signal.
// 

module freq_measurement #(
  parameter DATA_WIDTH = 16
)(
  output logic [DATA_WIDTH-1:0]out_value,
  output logic done_flag,
  input wire [DATA_WIDTH-1:0]samples_required,
  input wire in_wave,
  input wire enable, Clock, nReset
);

timeunit 1ns; timeprecision 10ps;

logic delay, active ;
logic [DATA_WIDTH-1:0]samples_taken ;
logic [DATA_WIDTH-1:0]count ;

    
always_ff @(posedge Clock, negedge nReset)
  if (!nReset)      // asynchronous reset
  begin
    active <= 0 ;
    out_value <= 0 ;
    samples_taken <= 0 ;
    done_flag <= 0 ;
  end else if ((enable) && (!done_flag)) begin
    if ((in_wave) && (!delay)) begin
      if (!active) active <= 1 ;
      if (active) samples_taken <= samples_taken + 1 ;
      if (samples_taken == samples_required - 1) begin
        active <= 0 ;
        done_flag <= 1 ;
        out_value <= count ;
      end
    end
  end
  
  
always_ff @(posedge Clock, negedge nReset)
  if (!nReset) count <= 0 ;
  else if ((enable) && (active)) count <= count + 1 ;
  
  
always_ff @(posedge Clock, negedge nReset)
  if (!nReset) delay <= 0 ;
  else if (enable) delay <= in_wave ;
 
endmodule
