--------------seven_segment_display---------------

-- seven segment display which outputs cathode value for current anode value

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ssd is
Port ( bcdin : in STD_LOGIC_VECTOR (3 downto 0);
reset : in std_logic;
sevensegment : out STD_LOGIC_VECTOR (6 downto 0);
clk         : in std_logic
);
end ssd;

architecture ssd of ssd is
signal temp : std_logic := '1';
begin


process(bcdin)
begin

case bcdin is
when "0000" =>
sevensegment <= "1000000"; ---0
when "0001" =>
sevensegment <= "1111001"; ---1
when "0010" =>
sevensegment <= "0100100"; ---2
when "0011" =>
sevensegment <= "0110000"; ---3
when "0100" =>
sevensegment <= "0011001"; ---4
when "0101" =>
sevensegment <= "0010010"; ---5
when "0110" =>
sevensegment <= "0000010"; ---6
when "0111" =>
sevensegment <= "1111000"; ---7
when "1000" =>
sevensegment <= "0000000"; ---8
when "1001" =>
sevensegment <= "0010000"; ---9
when "1010" =>
sevensegment <= "0001000"; ---A
when "1011" =>
sevensegment <= "0000011"; ---B
when "1100" =>
sevensegment <= "1000110"; ---C
when "1101" =>
sevensegment <= "0100001"; ---D
when "1110" =>
sevensegment <= "0000110"; ---E
when "1111" =>
sevensegment <= "0001110"; ---F
when others =>
sevensegment <= "1111111"; ---null
end case;

end process;

end ssd;

-------------------------andoe---------------

-- this arch. outputs anode values which changes at every rising clock edge in cyclic order

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity anode1 is
    Port ( clock : in  STD_LOGIC;
           anodeout : out  STD_LOGIC_VECTOR (3 downto 0));
end anode1;

architecture anode1 of anode1 is
signal q_tmp: std_logic_vector(3 downto 0):= "1110";
begin
process(clock)
begin
if Rising_edge(clock) then
	q_tmp(1) <= q_tmp(0);
	q_tmp(2) <= q_tmp(1);
	q_tmp(3) <= q_tmp(2);
	q_tmp(0) <= q_tmp(3);
end if;
end process;
anodeout <= q_tmp;
end anode1;

----------clock Divider------------------

-- for display purpose clk is divided by 2**17 to make freq of clk in range 4Hz - 1KHz

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity clkdiv is 
    port( pushbutton : in std_logic;
            clock1 : in std_logic;
          out_clock : out std_logic
        );
end clkdiv;
    
architecture clkdiv of clkdiv is 
signal a: std_logic_vector(16 downto 0) := "00000000000000000";
begin
    process(clock1)
    begin 
        if clock1'event and clock1 = '1' then
            a <= a+1;
        end if;
    end process;
    out_clock <= a(16) when pushbutton = '0' else (clock1);
end clkdiv;


----------display------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity display is 
    port( num : in Integer;
          clk : in std_logic;
          reset : in std_logic;
          cathode :     out std_logic_vector(6 downto 0);
          anode :       out std_logic_vector(3 downto 0)
        );
end display;
    
architecture display of display is
 
component anode1 is
    Port ( clock : in  STD_LOGIC;
           anodeout : out  STD_LOGIC_VECTOR (3 downto 0));
end component;

component ssd is
Port ( bcdin : in STD_LOGIC_VECTOR (3 downto 0);
reset : in std_logic;
sevensegment : out STD_LOGIC_VECTOR (6 downto 0);
clk           : in std_logic);
end component;

component clkdiv is 
    port( pushbutton : in std_logic;
          clock1 : in std_logic;
          out_clock : out std_logic
        );
end component;

signal cathode_temp : std_logic_vector(6 downto 0) := "1111111";
signal anode_temp, print_num : std_logic_vector(3 downto 0);
signal sixteen : std_logic_vector(15 downto 0);
signal clock_to_be_used : std_logic;
signal sim_mode :          std_logic := '0';

begin 
sim_mode <= '0';
LK_TO_BE_USED: clkdiv port map(	pushbutton => sim_mode,
                                  clock1 => clk,
                                  out_clock => clock_to_be_used);
                                  
ODE: anode1 Port map ( 
        clock => clock_to_be_used,
        anodeout => anode_temp
        );


anode <= anode_temp;                               
cathode <= cathode_temp; 


SS: ssd Port map ( bcdin => print_num,
                    sevensegment => cathode_temp,
                    reset => reset, clk => clk);             

-- number which has to be showed on ssd                    
sixteen <= conv_std_logic_vector(num, 16);
                                                          
process(print_num, anode_temp)
begin 
-- this porcess selects 4 digits out of 16 digits of print_num corresponding to anode values(priority encoder)
if(anode_temp(3) = '0') then
  print_num <= sixteen(15 downto 12);
  
  elsif (anode_temp(2) = '0') then
  print_num <= sixteen(11 downto 8);
  
  elsif(anode_temp(1) = '0') then
  print_num <= sixteen(7 downto 4);
      
  elsif(anode_temp(0) = '0') then
  print_num <= sixteen(3 downto 0);
end if;
end process;

end display;