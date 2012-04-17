module REPLL_CONTROL
(  sys_reset,
   clock_ctr,
   trigger,
   busy_ctr,
   MultiFactor,
   DividFactor,
 	counter_param_ctr,
	counter_type_ctr,
	reset_ctr,
	pll_areset_in_ctr,
	write_param_ctr,
	reconfig_ctr,
	pll_pfdena,
	pll_read_param,
	config_data_in);
	
	input sys_reset;
	input clock_ctr;
	input trigger;
	input busy_ctr;
	input [7:0] MultiFactor;
	input [7:0] DividFactor;
	
	output logic [2:0] counter_param_ctr;
	output logic [3:0] counter_type_ctr;
	output logic reset_ctr;
	output logic pll_areset_in_ctr;
	output logic write_param_ctr;
	output logic reconfig_ctr;
	output logic pll_pfdena;
	output logic pll_read_param;
	output logic [8:0] config_data_in;
	
	parameter Idle         = 4'b0000;
	parameter ResetPLL     = 4'b0001;
	parameter ResetREC     = 4'b0010;
	parameter SetTypeM     = 4'b0011;
	parameter SetParamHM   = 4'b0100;
	parameter SetParamLM   = 4'b0101;
	parameter WriteHM      = 4'b0110;
	parameter WriteLM      = 4'b0111;
	parameter Interval     = 4'b1000;
	parameter SetTypeC     = 4'b1001;
	parameter SetParamHC   = 4'b1010;
	parameter SetParamLC   = 4'b1011;
	parameter WriteHC      = 4'b1100;
	parameter WriteLC      = 4'b1101;
	parameter Reconfig     = 4'b1110;
	parameter Busy         = 4'b1111;
	
	
	reg  [3:0]  state;
	reg  [4:0]  next_state;
	
	reg [2:0] counter_5;
   reg [3:0] counter_10;
   reg Delay_5;
   reg Delay_10;
   reg timed_5;
   reg timed_10;
	
	assign pll_pfdena = 1;
	assign pll_read_param = 0;
	assign config_data_in[8] = 0;
	
	
	assign counter_param_ctr =   ( state == Idle 
	                            || state == ResetPLL
								       || state == ResetREC
										 || state == SetTypeM
										 || state == SetParamHM
										 || state == WriteHM
										 || state == SetParamHC
										 || state == WriteHC )?        3'b000:3'b001;
	assign counter_type_ctr  =   ( state == Idle 
	                            || state == ResetPLL
								       || state == ResetREC
										 || state == SetTypeC
										 || state == SetParamHC
										 || state == WriteHC
										 || state == SetParamLC
										 || state == WriteLC
										 || state == Reconfig
										 || state == Busy )?        4'b0000:4'b0001;
	assign reset_ctr         =   ( state == ResetREC );
   assign pll_areset_in_ctr =   ( state == ResetPLL );
	assign write_param_ctr   =   ( state == WriteHM
	                            || state == WriteLM
										 || state == WriteHC
										 || state == WriteLC );
   assign reconfig_ctr      =   ( state == Busy );
	assign Delay_5           =   ( state == SetTypeM
	                            || state == WriteHM
										 || state == SetTypeC
										 || state == WriteHC
										 || state == WriteLC );
	assign Delay_10          =   ( state == ResetPLL
	                            || state == SetParamHM
										 || state == SetParamLM
										 || state == Interval
										 || state == SetParamHC
										 || state == SetParamLC );

 always @(posedge clock_ctr, negedge sys_reset)
    if (~sys_reset)
      state <= ResetPLL;
    else
      state <= next_state;

 always @(
       state
    or trigger
	 or timed_5
	 or timed_10
	 or busy_ctr
    )
  begin
    next_state    = state;

    case (state)
        Idle:     if (trigger)
                    next_state = SetTypeM;
        ResetPLL:  next_state = ResetREC;
		
	 	  ResetREC: if (timed_10)
                    next_state = Idle;
        SetTypeM:  
                    next_state = SetParamHM;
        SetParamHM:if (timed_5)
                    next_state = WriteHM;
        WriteHM:   if (timed_10)
                    next_state = SetParamLM;
        SetParamLM:if (timed_5)
                    next_state = WriteLM;
        WriteLM:   if (timed_10)
                    next_state = Interval;
        Interval:   next_state = SetTypeC;
                   
        SetTypeC:  if (timed_10)
                    next_state = SetParamHC;
        SetParamHC:if (timed_5)
                    next_state = WriteHC;
        WriteHC:   if (timed_10)
                    next_state = SetParamLC;
        SetParamLC:if (timed_5)
                    next_state = WriteLC;
        WriteLC:   if (timed_10)
                    next_state = Reconfig;         
        Reconfig: if (timed_5)
                    next_state = Busy;
        Busy:     if (~busy_ctr)
                    next_state = Idle;
     endcase 
	end 
	
	
	
always_ff @(posedge clock_ctr, posedge Delay_5)
begin:Delay5Cycles
  if (Delay_5)
    begin
    counter_5 <= 3'b001;
    timed_5 <= 0;
    end
  else
    if (counter_5 == 3'b000)
      begin
        counter_5 <= 3'b000;
        timed_5 <= 0;
      end
  else
    if (counter_5 == 3'b100)
      begin
      counter_5 <= 3'b000;
      timed_5 <= 1;
      end
  else
    begin
    counter_5 <= counter_5+1;
    timed_5 <= 0;
    end
end  

always_ff @(posedge clock_ctr, posedge Delay_10)
begin:Delay10Cycles
  if (Delay_10)
    begin
    counter_10 <= 4'b0001;
    timed_10 <= 0;
    end
  else
    if (counter_10 == 4'b0000)
      begin
        counter_10 <= 4'b0000;
        timed_10 <= 0;
      end
  else
    if (counter_10 == 4'b1001)
      begin
      counter_10 <= 4'b0000;
      timed_10 <= 1;
      end
  else
    begin
    counter_10 <= counter_10 +1;
    timed_10 <= 0;
    end
end  

endmodule
