entity TestChip is
end;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

architecture Bench of TestChip is
  
component VirtualChip is
  port (PCLK : in std_logic;
        ain, bin, cin: in std_logic_vector(7 downto 0);
        aout, bout, cout: inout std_logic_vector(7 downto 0));
end component;

  signal clk: std_logic;
  signal Ain : std_logic_vector(7 downto 0);
  signal Bin : std_logic_vector(7 downto 0);
  signal Cin : std_logic_vector(7 downto 0);
  signal Aout: std_logic_vector(7 downto 0);
  signal Bout: std_logic_vector(7 downto 0);
  signal Cout: std_logic_vector(7 downto 0);

begin
  
chip_1: VirtualChip       port map(PCLK  => clk, 
                                   ain(7 downto 0)  => Ain(7 downto 0),
                                   bin(7 downto 0)  => Bin(7 downto 0),
                                   cin(7 downto 0)  => Cin(7 downto 0),
                                   aout(7 downto 0)  => Aout(7 downto 0),
                                   bout(7 downto 0)  => Bout(7 downto 0),
                                   cout(7 downto 0)  => Cout(7 downto 0));
process
begin                                   
Ain <="00000000";
Bin <="00000000";
Cin <="00000000";

wait for 100 ns;
Ain <= "00000000";
Bin <= "01110000";
Cin <= "00000010";

wait for 200 ns;
Ain <= "01100000";
Bin <= "00101000";
Cin <= "10101001";
wait for 200 ns;

end process;       
     
process
  begin
  clk <= '1';
  wait for 10ns;
  clk <= '0';
  wait for 10ns;     
end process;                  
end Bench;