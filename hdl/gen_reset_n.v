module gen_reset_n(
		tx_clk,
		reset_n_in,
		reset_n_out
	);
	
input 	tx_clk;	
input	reset_n_in;
output	reset_n_out;

reg		reset_n_out;


parameter					ctr_width			=	20; // richard 16;
reg		[ctr_width-1:0]		ctr;	// Reset counter
reg							enet_reset_n;

always	@(posedge tx_clk or negedge reset_n_in)
begin
	if	(!reset_n_in)
	begin
		reset_n_out	<=	0;
		ctr			<=	0;
	end else begin
		if	(ctr == {ctr_width{1'b1}})
		begin
			reset_n_out	<=	1'b1; //enet_resetn_pb;	// Auto reset phy 1st time
		end else begin
			ctr	<=	ctr + 1;
			reset_n_out	<=	0;
		end
	end
end

endmodule
