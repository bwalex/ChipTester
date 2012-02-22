library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity FullAdder4 is
  port( A, B               :  in  std_logic_vector(3 downto 0);
        CarryIn            :  in  std_logic;
        AB                 :  out std_logic_vector(3 downto 0);
        CarryOut           :  out std_logic);
end FullAdder4;

architecture Behavioral of FullAdder4 is
  signal IntSum : std_logic_vector (4 downto 0);
begin
  IntSum <= ('0'&A)+('0'&B)+("0000"&CarryIn);
  CarryOut <= IntSum(4);
  AB <= IntSum(3 downto 0);
end Behavioral;