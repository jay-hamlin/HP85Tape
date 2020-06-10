library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tape_control;
use tape_control.constants.all;

entity uart_tx is
  port (
    clk : in std_logic;
    rst : in std_logic;
    push_pulse : in std_logic;
    data : in std_logic_vector(7 downto 0);
    busy : out std_logic;
    tx : out std_logic
  );
end uart_tx; 

architecture rtl of uart_tx is

  -- For counting clock periods.
  constant clock_cycles_per_bit : integer := integer(clock_frequency / real(baud_rate));
  subtype clk_counter_type is integer range 0 to clock_cycles_per_bit - 1;
  signal clk_counter : clk_counter_type;
  
  type state_type is (
    IDLE,
    POP0_FIFO,
    POP1_FIFO,
    START_BIT,
    DATA_BITS,
    STOP_BIT);
  signal state : state_type;

  -- For sampling the data input
  signal data_sampled : std_logic_vector(data'range);

  signal bit_counter : integer range data'range;

  signal data_uart : std_logic_vector(data'range);

  signal start_uart : std_logic;

  signal fifo_empty : std_logic;

begin

  TX_UART_FIFO : entity tape_control.uart_fifo(rtl)
   port map(
      clk => clk,
      rst => rst,
      push => push_pulse,      -- strobe to store byte
      pop => start_uart,       -- strobe to read byte
      data_in => data,   -- in from protocol engine
      data_out =>data_uart,   -- out to uart
      full => busy,  -- '1' if fifo is full
      empty => fifo_empty      -- '1' if fifo is empty
    );


  FSM_PROC : process(clk)
    -- Increment clock counter, return true if it wraps
    impure function clk_counter_wrapped return boolean is
      begin
        if clk_counter = clk_counter_type'high then
          clk_counter <= 0;
          return true;
        else
          clk_counter <= clk_counter + 1;
          return false;
        end if;
      end function;

  begin
    if rising_edge(clk) then
      if rst = '1' then
        state <= IDLE;
        tx <= '1';
        start_uart <= '0';
        data_sampled <= (others => '0');
        bit_counter <= 0;
      else
        tx <= '1';
        start_uart <= '0';

        case state is
          -- Wait for the start signal
          when IDLE =>
            if fifo_empty = '0' then  -- there is at least 1 byte in the fifo
              state <= POP0_FIFO;
              start_uart <= '1';
              
            end if;
          when POP0_FIFO =>
            state <= POP1_FIFO;
          --  data_sampled <= data_uart;
            start_uart <= '0';
          when POP1_FIFO =>
            state <= START_BIT;
            data_sampled <= data_uart;
          -- transmit start bit
          when START_BIT =>
            tx <= '0';
            if clk_counter_wrapped then
              state <= DATA_BITS;
            end if;
         
          -- transmit the data bits
          when DATA_BITS =>
            tx <= data_sampled(bit_counter);
            if clk_counter_wrapped then
              if bit_counter = data'high then
                state <= STOP_BIT;
                bit_counter <= 0;
              else
                bit_counter <= bit_counter + 1;
              end if;
            end if;

          -- transmit the stop bit
          when STOP_BIT =>
            -- tx default value is already '1' so we don't need to make an assignment
            if clk_counter_wrapped then
              state <= IDLE;
            end if;
 
        end case;
      end if; -- reset not '1
    end if;  -- clk rising edge
  end process; -- FSM_PROC


end architecture;