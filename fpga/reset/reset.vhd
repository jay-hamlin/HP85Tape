library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset is
  port (
    clk : in std_logic;
    rst_in : in std_logic;  -- pullup, active low
    rst_out : out std_logic
 );
end reset; 

architecture rtl of reset is

  signal counter : unsigned(7 downto 0) := (others => '0');

begin

    rst_out <= not counter(counter'high);  -- init in reset

    PROC_RESET : process(clk)
    begin
      if rising_edge(clk) then
        if rst_in = '0' then
          counter <= (others => '0');
        else
          if counter(counter'high) = '0' then
            counter <= counter +1;
          end if;
        end if;
      end if;
    end process; -- PROC_RESET

end architecture;

 