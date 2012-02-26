module LongRecognition(output logic MatchBit, MatchAll,
                       input logic Clock, Reset, DataIn);

enum logic [3:0] {S0,S1,S2,S3,S4,S5,S6,S7,S8} state;

//Team P's code
always_ff @(posedge Clock, negedge Reset)
if(!Reset) state <= S0;
else
  case(state)
    S0:if(DataIn) state <= S1;
       else       state <= S0;
    S1:if(DataIn) state <= S2;
       else       state <= S0;
    S2:if(DataIn) state <= S3;
       else       state <= S0;
    S3:if(DataIn) state <= S4;
       else       state <= S0;
    S4:if(DataIn) state <= S5;
       else       state <= S0;
    S5:if(DataIn) state <= S6;
       else       state <= S0;
    S6:if(DataIn) state <= S0;
       else       state <= S7;
    S7:if(DataIn) state <= S8;
       else       state <= S0;
    S8:if(DataIn) state <= S1;
       else       state <= S0;
  endcase
  
always_comb
begin
  if(state == S0) 
    begin
      MatchBit = 0;
      MatchAll = 0;
    end
  elseif(state == S8) 
    begin
      MatchBit = 1;
      MatchAll = 1;
    end
    else 
      begin
        MatchBit = 1;
        MatchAll = 0;
      end
end

endmodule