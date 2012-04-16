module REPLL_CONTROL
( sys_reset,
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
	
	assign pll_pfdena = 1;
	assign pll_read_param = 0;
	assign config_data_in[8] = 0;
	
  enum {Idle, ResetPLL, ResetREC, SetTypeM, SetParamHM,SetParamLM, WriteHM, WriteLM, Interval, SetTypeC, SetParamHC, SetParamLC, WriteHC, WriteLC, Reconfig, Busy} state;
  
  logic [2:0] counter_5;
  logic [3:0] counter_10;
  logic Delay_5;
  logic Delay_10;
  logic timed_5;
  logic timed_10;
  
  
always_ff @(posedge clock_ctr, posedge sys_reset)
begin
  if (sys_reset)
    state <= ResetPLL;
  else
      case (state)
        Idle:     if (trigger)
                    state <= SetTypeM;
        ResetPLL: 
                    state <= ResetREC;
        ResetREC: if (timed_10)
                    state <= Idle;
        SetTypeM:  
                    state <= SetParamHM;
        SetParamHM:if (timed_5)
                    state <= WriteHM;
        WriteHM:   if (timed_10)
                    state <= SetParamLM;
        SetParamLM:if (timed_5)
                    state <= WriteLM;
        WriteLM:   if (timed_10)
                    state <= Interval;
        Interval:   state <= SetTypeC;
                   
        SetTypeC:  if (timed_10)
                    state <= SetParamHC;
        SetParamHC:if (timed_5)
                    state <= WriteHC;
        WriteHC:   if (timed_10)
                    state <= SetParamLC;
        SetParamLC:if (timed_5)
                    state <= WriteLC;
        WriteLC:   if (timed_10)
                    state <= Reconfig;         
        Reconfig: if (timed_5)
                    state <= Busy;
        Busy:     if (~busy_ctr)
                    state <= Idle;
        default:    state <= Idle;
      endcase
end

always
begin
  case (state)
    Idle:     begin
                 counter_param_ctr = 3'b000;
                 counter_type_ctr  = 4'b0000;
                 reset_ctr         = 1'b0;
	              pll_areset_in_ctr = 1'b0;
	              write_param_ctr   = 1'b0;
	              reconfig_ctr      = 1'b0;    
	              Delay_5           = 1'b0;
	              Delay_10          = 1'b0;
	              config_data_in[7:0]= 8'b00000000;        
              end
    ResetPLL: begin
                pll_areset_in_ctr = 1'b1;
                Delay_10          = 1'b1;
              end
    ResetREC: begin
                pll_areset_in_ctr = 1'b0;
                reset_ctr         = 1'b1;
                Delay_10          = 1'b0;
              end
    SetTypeM:  begin
                reset_ctr         = 1'b0;
                counter_type_ctr  = 4'b0001;
                Delay_5           = 1'b1;
                config_data_in[7:0]= MultiFactor;
              end
    SetParamHM:begin
                counter_param_ctr = 3'b000;
                Delay_5           = 1'b0;
                Delay_10          = 1'b1;
              end
    WriteHM:   begin
                write_param_ctr   = 1'b1;
                Delay_10          = 1'b0;
                Delay_5           = 1'b1;
              end
    SetParamLM:begin
                write_param_ctr   = 1'b0;
                counter_param_ctr = 3'b001;
                Delay_5           = 1'b0;
                Delay_10          = 1'b1;
              end
    WriteLM:   begin
                write_param_ctr   = 1'b1;
                Delay_10          = 1'b0;
                Delay_5           = 1'b0;
              end
    Interval:  begin
                write_param_ctr   = 1'b0;
                Delay_10          = 1'b1;
                Delay_5           = 1'b0;
               end
    SetTypeC:  begin
                reset_ctr         = 1'b0;
                counter_type_ctr  = 4'b0100;
                Delay_5           = 1'b1;
                Delay_10          = 1'b0;
                config_data_in[7:0]= DividFactor;
              end
    SetParamHC:begin
                counter_param_ctr = 3'b000;
                Delay_5           = 1'b0;
                Delay_10          = 1'b1;
              end
    WriteHC:   begin
                write_param_ctr   = 1'b1;
                Delay_10          = 1'b0;
                Delay_5           = 1'b1;
              end
    SetParamLC:begin
                write_param_ctr   = 1'b0;
                counter_param_ctr = 3'b001;
                Delay_5           = 1'b0;
                Delay_10          = 1'b1;
              end
    WriteLC:   begin
                write_param_ctr   = 1'b1;
                Delay_10          = 1'b0;
                Delay_5           = 1'b1;
              end          
    Reconfig: begin
                write_param_ctr   = 1'b0;
               	Delay_5           = 1'b0;
              end
    Busy:     begin
                reconfig_ctr      = 1'b1;
              end
    default:  begin
                counter_param_ctr = 3'b000;
                counter_type_ctr  = 4'b0000;
               	reset_ctr         = 1'b0;
	              pll_areset_in_ctr = 1'b0;
	              write_param_ctr   = 1'b0;
	              reconfig_ctr      = 1'b0;
	              Delay_5           = 1'b0;
	              Delay_10          = 1'b0;
              end
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
