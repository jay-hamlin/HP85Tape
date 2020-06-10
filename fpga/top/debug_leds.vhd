library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity debug_leds is
  port (
    clk : in std_logic;
    rst : in std_logic;
 
    -- Signals to debug
    led_1_in : in std_logic;
    led_2_in : in std_logic;
    led_3_in : in std_logic;

    -- LED outputs
    led_1 : out std_logic; -- use for stop bit error
    led_2 : out std_logic; -- sticky version of led_1
    led_3 : out std_logic; -- uart tx valid pulse while busy
    led_4 : out std_logic; -- sticky version of led_3
    led_5 : out std_logic  -- '1' power on
  );
end debug_leds; 

architecture rtl of debug_leds is

signal slow_counter : integer range 0 to 8191;

begin
  led_5 <= '1';
  led_4 <= '0';

  PROC_LEDS : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        led_1 <= '0';
        led_2 <= '0';
        led_3 <= '0';

        slow_counter <= 0;
      else
        if led_1_in = '1' then
          led_1 <= '1';
          slow_counter <= 8191;
        end if;
        if led_2_in = '1' then
          led_2 <= '1';
          slow_counter <= 8191;
        end if;
        if led_3_in = '1' then
          led_3 <= '1';
          slow_counter <= 8191;
        end if;

        if slow_counter > 0 then
          slow_counter <= slow_counter - 1;
        else
          slow_counter <= 8191;
          led_1 <= '0';
          led_2 <= '0';
          led_3 <= '0'; 
        end if;
       
      end if;
    end if;
  end process; -- PROC_LEDS


end architecture;