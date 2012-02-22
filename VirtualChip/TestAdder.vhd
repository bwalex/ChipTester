entity TestAdder is
end;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

architecture Bench of TestAdder is
  component FullAdder4
    port( A, B               :  in  std_logic_vector(3 downto 0);
          CarryIn            :  in  std_logic;
          AB                 :  out std_logic_vector(3 downto 0);
          CarryOut           :  out std_logic);
  end component;
  
  signal Ain : std_logic_vector(3 downto 0);
  signal Bin : std_logic_vector(3 downto 0);
  signal Sum : std_logic_vector(3 downto 0);
  signal Cin : std_logic;
  signal Cout: std_logic;

begin
  
Adder_1: FullAdder4       port map(A(3 downto 0)  => Ain(3 downto 0), CarryIn  => Cin, 
                                   B(3 downto 0)  => Bin(3 downto 0),
                                   AB(3 downto 0) => Sum(3 downto 0), Carryout => Cout);
process
begin                                   
Ain <="0000";
Bin <="0000";
Cin <='0';

wait for 100 ns;
Ain <= "0000";
Bin <= "0111";
Cin <= '0';

wait for 200 ns;
Ain <= "0110";
Bin <= "0010";
Cin <= '1';
wait for 200 ns;

end process;                                   
end Bench;