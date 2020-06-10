library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tape_control;
use tape_control.constants.all;

--
--
-- I found this code at: http://www.deathbylogic.com/2013/07/vhdl-standard-fifo/
--
--
entity uart_fifo is
  Generic (
		constant DATA_WIDTH  : positive := 8;
		constant FIFO_DEPTH	: positive := 8
	);
 port (
    clk : in std_logic;
    rst : in std_logic;
    push : in std_logic;        -- strobe to store byte
    pop : in std_logic;         -- strobe to read byte
    data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);  -- in from rx_uart
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0);  -- out to protocol engine
    full : out std_logic;       -- '1' if fifo is full
    empty : out std_logic      -- '1' if fifo is empty
  );
end uart_fifo; 

architecture rtl of uart_fifo is

begin
  -- Memory Pointer Process
  fifo_proc : process (clk)
    type FIFO_Memory is array (0 to FIFO_DEPTH - 1) of STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
    variable Memory : FIFO_Memory;

    variable Head : natural range 0 to FIFO_DEPTH - 1;
    variable Tail : natural range 0 to FIFO_DEPTH - 1;

    variable Looped : boolean;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        Head := 0;
        Tail := 0;
        
        Looped := false;

        full  <= '1';
        empty <= '1';
      else
        full <= '0';

        if (pop = '1') then
          if ((Looped = true) or (Head /= Tail)) then
            -- Update data output
            data_out <= Memory(Tail);
            
            -- Update Tail pointer as needed
            if (Tail = FIFO_DEPTH - 1) then
              Tail := 0;
              
              Looped := false;
            else
              Tail := Tail + 1;
            end if;

          end if;
        end if;
        
        if (push = '1') then
          full <= '1';
          if ((Looped = false) or (Head /= Tail)) then
            -- Write Data to Memory
            Memory(Head) := data_in;
            
            -- Increment Head pointer as needed
            if (Head = FIFO_DEPTH - 1) then
              Head := 0;
              
              Looped := true;
            else
              Head := Head + 1;
            end if;
          end if;
        else
          -- Update Empty and Full flags
          if (Head = Tail) then
            if Looped then
              full <= '1';
              empty <= '0';
            else
              full <= '0';
              empty <= '1';
            end if;
          else
            empty	<= '0';
            full	<= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture;