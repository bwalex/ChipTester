// frequency counter - ELEC6027 VLSI design project - Team I
// Digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples.
// 
// vf1.2
//
// buffer module - Buffers last 8 frequency measurements and calculates
// their average.

module buffer (
  output logic [9:0]average,
  output logic [9:0]buff [7:0],
  output logic done_flag,
  input shortint samples_required,
  input wire [12:0]current_freq,
  input wire enable, in_wave, Clock, nReset
);

timeunit 1ns; timeprecision 10ps;

//shortint samples_required ;
shortint samples_taken ;
logic [12:0]temp_sum;

logic started ;
integer n;

// shifting of values from counter to buffer
always_ff @(posedge in_wave, negedge nReset)
  if (!nReset) begin
  	buff[0] <= 0 ;
	buff[1] <= 0 ;
	buff[2] <= 0 ;
	buff[3] <= 0 ;
	buff[4] <= 0 ;
	buff[5] <= 0 ;
	buff[6] <= 0 ;
	buff[7] <= 0 ;
	average <= 0 ;
	done_flag <= 0 ;
	started <= 0 ;
	temp_sum <= 0 ;
	samples_taken <= 0 ;
  end
  else begin
    if (enable) started <= 1 ;
    if (started) begin
      if (samples_taken < samples_required) begin
	    for (n = 7; n>0; n = n-1) buff[n] <= buff[n-1] ;
	    temp_sum <= buff[7] + buff[6] + buff[5] + buff[4] + buff[3] + buff[2] + buff[1] + buff[0] ;
        buff[0] <= current_freq ;
        average <= temp_sum >> 3 ;
        samples_taken <= samples_taken + 1 ;
      end
      else begin
        samples_taken <= 0 ;
        done_flag <= 1 ;
        started <= 0 ;
      end
    end
    else if (done_flag) done_flag <= 0 ;
  end
endmodule







