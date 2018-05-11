
-- Note
-- 1. cam_width is used in cam_entity and ram so change generic everywhere



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;                                                       
--------------library that contians internal packages
LIBRARY work;
USE work.ram.ALL;
-----------------------------------------------------
entity search_entity is
    generic(
        cam_width : integer:=1024
    );
    port (
        reset : in STD_LOGIC;
        clk : in STD_LOGIC;
        word : in std_logic_vector(7 downto 0);
        address : out std_logic_vector(cam_width-1 downto 0);
        ones : out integer
    );
end search_entity;

architecture search_entity of search_entity is
--------- singal that is a array of 0,1's where data is present
signal is_present : std_logic_vector(cam_width-1 downto 0);
signal number_of_ones : integer;
--------------------------------------------------------------

-- function to calculate number of ones(= number of addresses where the search word is found) in the 1d array corresponding to the search word
function count_ones(s : std_logic_vector) return integer is
  variable temp : natural := 0;
begin
  for i in s'range loop
    if s(i) = '1' then temp := temp + 1; 
    end if;
  end loop;
  
  return temp;
end function count_ones;

begin
process(clk)
---------convert the std_logic_Vector to integer for searching
variable search_word : integer := to_integer(unsigned(word));
-------------------------------------------------------------
begin
--------- search for the word in the memory------------------
    is_present <= search(search_word);
----------calculate the number of 1's in the array-----------
    number_of_ones <= count_ones(is_present);
-------------------------------------------------------------
end process;
    address <= is_present;
    ones <= number_of_ones;
end search_entity;

--=====================================================
--=====================================================
--======================================================

--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
--use IEEE.std_logic_unsigned.all;
--use IEEE.std_logic_arith.all;
library IEEE;
--use IEEE.std_logic_arith.all;
use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.std_logic_unsigned.all;

--------------library that contians internal packages
LIBRARY work;
USE work.ram.ALL;
    use IEEE.NUMERIC_STD.ALL;  

entity cam_entity is
    generic(
        cam_width : integer:=1024;
        cam_depth : integer:=256;
        log_of_cam_width : integer := 10
    );
    port (
        reset : in STD_LOGIC;
        clk : in STD_LOGIC;
        word : in std_logic_vector(7 downto 0);
        search_enable : in std_logic;
        no_match : out std_logic;
        one_match : out std_logic;
        multi_match : out std_logic;
        cathode :     out std_logic_vector(6 downto 0);
        anode :       out std_logic_vector(3 downto 0);
        leds  :       out std_logic_vector(log_of_cam_width-1 downto 0);
        show_history :     in std_logic;
        clear_history :    in std_logic     
    );
end cam_entity;

architecture Behavioural of cam_entity is

component search_entity
    generic(
        cam_width : integer:=1024
    );
    port (
        reset : in STD_LOGIC;
        clk : in STD_LOGIC;
        word : in std_logic_vector(7 downto 0);
        address : out std_logic_vector(cam_width-1 downto 0);
        ones : out integer
    );
end component;

component display is 
    port( num : in Integer;
          clk : in std_logic;
          reset : in std_logic;
          cathode :     out std_logic_vector(6 downto 0);
          anode :       out std_logic_vector(3 downto 0)
          );
end component;

signal address : std_logic_vector(cam_width-1 downto 0);
signal matches : std_logic_vector(1 downto 0) := "00";
signal ones, ones_temp, b, c0, b_show  : integer;
signal c : integer := -1;
signal counter    : std_logic_vector(30 downto 0) := "0000000000000000000000000000000";

-- 2 FSMs are used here

-- 1st FSM(curr_state) is for (triggered when search_enable is pressed)searching the addresses where the search word is present and showing them on display
type state is (S0,S1,S2,S3,S4,S40,S50,S5) ;

-- 2nd FSM(show_state) is for (triggered when show_history is pressed) showing the history of words which was searched till the point of time when show_history is pressed
type state_history is (t0,t1,t2,t3,t4) ;
signal curr_state : state := s0;
signal show_state : state_history := t0;
signal temp : std_logic := '1';
signal history : std_logic_vector(cam_depth-1 downto 0) := "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

begin


--leds <= conv_std_logic_vector(ones_temp, log_of_cam_width);
-- converting ones_temp(integer) to leds (std_logic_vector)
leds <= std_logic_vector(to_unsigned(ones_temp, log_of_cam_width));

process(matches, reset,clk)
begin
    -- assigns values to match leds(no_match, one_match, multi_match) on the basis of the number of addresses where the search word is found
    if matches = "00" then
        no_match <= '0';
        one_match <= '0';
        multi_match <= '0';
    elsif matches = "01" then
        no_match <= '0';
        one_match <= '1';
        multi_match <= '0';
    elsif matches = "10" then
        no_match <= '0';
        one_match <= '0';
        multi_match <= '1';
    else
        no_match <= '1';
        one_match <= '0';
        multi_match <= '0';
    end if;

end process;

-- port map of display(for ssd, to get values of anode and cathode)

Fisplay : display port map( num => c,
                            clk => clk,
                            reset => reset,
                            cathode => cathode,
                            anode => anode);

-- port map of search_entity(to find the number of addresses where search word is found)

map_1 : search_entity
    generic map (
        cam_width => cam_width
    ) 
    port map(
    reset => reset,
    clk   => clk,
    word  => word,
    address => address,
    ones => ones
); 


-- main process
process(clk,reset)
begin
    
    -- clears the history is clear_history is pressed
    if clear_history = '1' then
        history <= (others => '0'); 
    end if;
    
    -- resets the values of c(ssd) and number_of_matches and make the curr_state to S0
    if reset = '1' then
        matches <= "00";
        c <= -1;
        ones_temp <= 0;
        curr_state <= S0;
    end if;
    
    -- if show_history is pressed then show_state is set to be t1 to start showing the history of the words which were searched earlier
    if show_history = '1' then
        matches <= "00";
        ones_temp <= 0;
        show_state <= t1;
        curr_state <= S0;
    end if;

   -- on the rising edge of clk the controller and data_path are implemented for both the FSMs
   if Rising_edge(clk) then
       case show_state is
           -- idle state for show_state
           when t0 =>
           
           -- state where b_show is initialized
           when t1 => b_show <= cam_depth + 2;
                      
                      show_state <= t2;
           
           -- state for searching the data words which were searched earlier
           when t2 => for i in 0 to cam_depth-1 loop
                           if history(i) = '1' and i < b_show then
                               c <= i;
                               if b_show = cam_depth + 2 then
                                    b_show <= cam_depth + 1;
                               end if;
                           end if;
                       end loop;
                       show_state <= t3;

           -- intermediate state between t2 and t4 which gets terminated to t0 when the history searched is completed
           when t3 =>  if b_show = c OR b_show = cam_depth + 2 then
                           show_state <= t0;
                           c <= -1;
                       else
                           b_show <= c;
                           show_state <= t4;
                           counter <= (others => '0');
                       end if;

           -- state to show the words which were searched earlier(history)
           when t4 => counter <= counter +1 ;
                      if counter(27) = '1' then
                           show_state <= t2; 
                       end if;
       end case;
   
        case curr_state is
            -- idle state of curr_state FSM
            when s0 =>  if search_enable = '1' then
                            curr_state <= s1;
                            history(to_integer(unsigned(word))) <= '1';
                        end if;

            -- state where intialization of b, c is done and number of ones is assigned to ones_temp
            when s1 =>  ones_temp <= ones;
                        if ones > 0 then
                            curr_state <= s2;
                            b <= cam_width;
                            c <= cam_width;
                            
                            if ones = 1 then
                                matches <= "01";
                            else
                                matches <= "10";
                            end if;
                        else
                            curr_state <= s0;
                            matches <= "11";
                        end if;
            
            -- state to find the last address where the data was found and which has not been displayed yet
            when s2 => 
                        for i in 0 to cam_width-1 loop
                            if address(i) = '1' and i < b then
                                c <= i;
                                c0 <= i;
                            end if;
                        end loop;
                        
                        curr_state <= s3;
            
            -- intermideate state between s2 and s04 where ones_temp is decreased ( ones_temp = the number of addresses left to display where the search word was found )
            when s3 => 
                        b <= c;
                        ones_temp <= ones_temp -1 ;
                        curr_state <= s40;
                        c <= 2781;
                        -- data
                        counter <= (others => '0');
            
            -- state to show the "add" word
            when s40 => 
                        counter <= counter + 1;
                        if counter(27) = '1' then
                            curr_state <= S4;
                            c <= c0;
                            counter <= (others => '0'); 
                        end if;
            
            -- state to output the current address where the data is found
            when s4 =>  counter <= counter + 1;
                        if counter(27) = '1' then
                            curr_state <= S50;
                            c <= 55930;
                            -- add
                            counter <= (others => '0'); 
                        end if;
            
            -- state to output the "da7a"(data) word
            when s50 => 
                        counter <= counter + 1;
                        if counter(27) = '1' then
                            curr_state <= S5;
                            c <= value_at_ram(c0);
                            counter <= (others => '0'); 
                        end if;
            
            -- state to output the data (value) stored at the current address
            when S5 => counter <= counter + 1;
                        if counter(27) = '1' then
                            if ones_temp = 0 then
                                curr_state <= S0;
                                c <= -1;
                                matches <= "00";
                            else
                            curr_state <= S2;
                            end if; 
                        end if;
        end case;
   end if;
end process;

end Behavioural;

