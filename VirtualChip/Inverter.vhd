library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Inverter is
  port(A0  :     in  std_logic;
       Q0  :     out std_logic);
end Inverter;

architecture Behavioral of Inverter is
  
begin
  Q0 <= not A0;
end Behavioral;