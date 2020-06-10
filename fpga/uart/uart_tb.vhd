library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.finish;

library tape_control;

library tape_control_sim;
use tape_control_sim.sim_subprograms.all;
use tape_control_sim.sim_fifo.all;
use tape_control_sim.sim_constants.all;


entity uart_tb is
end uart_tb; 

architecture sim of uart_tb is

  -- common signals
  signal clk : std_logic := '1';
  signal rst : std_logic := '1';
  signal tx_rx  : std_logic := '1';
  
  -- TX signals
  signal tx_start : std_logic := '0';
  signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_busy : std_logic;

  -- RX signals
  signal rx_data : std_logic_vector(7 downto 0);
  signal rx_valid : std_logic;
  signal rx_stop_bit_error : std_logic;

  -- TB fifo for storing the transmitted characters
  shared variable fifo : sim_fifo;
 
begin

  gen_clock(clk);

  UART_TX_TB : entity tape_control.uart_tx(rtl)
  port map (
    clk  => clk,
    rst  => rst,
    push_pulse  => tx_start,
    data  => tx_data,
    busy  => tx_busy,
    tx => tx_rx
  );

  UART_RX_TB : entity tape_control.uart_rx(rtl)
  port map (
      clk => clk,
      rst => rst,
      rx  => tx_rx,
      data => rx_data,
      valid => rx_valid, 
      stop_bit_error => rx_stop_bit_error
    );


  PROC_SEQUENCER : process

    -- Start the transmission of 1 char and add it to the tb_fifo
    procedure transmit(constant data : std_logic_vector(tx_data'range)) is
    begin
      tx_start <= '1';
      tx_data <= data;
      fifo.push(to_integer(unsigned(data)));
      report "Transmit " & integer'image(to_integer(unsigned(data)));
      wait until rising_edge(clk);
      tx_start <= '0';
      tx_data <= (others => 'X');
      wait until rising_edge(clk);
    end procedure;

    procedure wait_until_fifo_empty is
      begin
        while not fifo.empty loop
          wait until rising_edge(clk);
        end loop;
    end procedure;

    variable tx_data_var : tx_data'subtype := (others => '0');
 
  begin
    tx_data_var := std_logic_vector(unsigned(tx_data_var) + 65);
    -- Reset strobe
    wait for 10 * clock_period;
    rst <= '0';
    -- wait until the uart is ready
    wait until tx_busy = '0';
    report "Report 3";
    loop
      transmit(tx_data_var);

      wait until tx_busy = '0';

      report "Report 4";

      tx_data_var := std_logic_vector(unsigned(tx_data_var) + 1);
      -- break out of the loop when it wraps
      if unsigned(tx_data_var) = 75 then  -- 0,1,2,3,4,5
        exit;
      end if;
    end loop;
  
    -- wait until the checker is done
    wait_until_fifo_empty;

    print_test_ok;
    finish;

  end process; -- PROC_SEQUENCER

  PROC_CHECK_RX : process
        variable expected : integer;
  begin
    wait until rx_valid = '1';

    expected := fifo.pop;
    assert to_integer(unsigned(rx_data)) = expected
    -- check that the content of the uart rx output matches the input
    report "Output from UART_RX (" & integer'image(to_integer(unsigned(rx_data)))
      & ") doesn't match transmitted word (" & integer'image(expected) & ")"
    severity failure;

    report "Recieved " & integer'image(expected);

  end process; -- PROC_CHECK_RX

end architecture;