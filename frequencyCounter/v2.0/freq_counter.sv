// freq_counter.sv - frequency counter
// ELEC6027 VLSI design project
// digital frequency counter to implement on Cyclone IV FPGA
// to measure output frequency of Southampton Superchip samples
// 
// v2.0

module freq_counter (freq_khz, buff, in_wave, Clock, nReset);

timeunit 1ns; timeprecision 10ps;

output logic [9:0] freq_khz ;
output logic [9:0] buff [7:0] ;
input logic in_wave, Clock, nReset ;


logic [12:0] temp_sum, count ;
logic flag ;

integer n;

always_ff @(posedge Clock, negedge nReset)
if (!nReset) // asynchronous reset
begin
	buff[0] <= 0 ;
	buff[1] <= 0 ;
	buff[2] <= 0 ;
	buff[3] <= 0 ;
	buff[4] <= 0 ;
	buff[5] <= 0 ;
	buff[6] <= 0 ;
	buff[7] <= 0 ;
	count <= 0 ;
	flag <= 0 ;
end
else
	if (in_wave) begin
		if (!flag) begin
			for (n = 7; n>0; n = n-1) buff[n] <= buff[n-1] ;
			temp_sum <= buff[7] + buff[6] + buff[5] + buff[4] + buff[3] + buff[2] + buff[1] + buff[0] ;
			freq_khz <= temp_sum >> 3 ;
			buff[0] <= count ;
			count <= 1 ;
			flag <= 1 ;
		end
		else count <= count + 1 ;
	end
	else begin
		count <= count + 1 ;
		flag <= 0 ;
	end
endmodule
