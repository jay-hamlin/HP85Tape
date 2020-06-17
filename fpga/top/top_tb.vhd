library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.finish;
use std.env.stop;
 
library tape_control;
use tape_control.types.all;
use tape_control.constants.all;
 
library tape_control_sim;
use tape_control_sim.sim_subprograms.all;
use tape_control_sim.sim_constants.all;
 
entity top_tb is
end top_tb; 
 
architecture sim of top_tb is
 
  -- DUT signals
  signal clk            : std_logic := '1';
  signal rst_button     : std_logic := '1'; -- Pullup
  -- uart
  signal uart_to_dut    : std_logic := '1';
  signal uart_from_dut  : std_logic;
  -- debug LEDs
  signal led_1          : std_logic;
  signal led_2          : std_logic;
  signal led_3          : std_logic;
  signal led_4          : std_logic;
  signal led_5          : std_logic;
  -- HP-85 system bus
  signal HP85_data      : std_logic_vector(7 downto 0) := (others => '0');
  signal HP85_nLMA      : std_logic := '1';
  signal HP85_nRD       : std_logic := '1';
  signal HP85_nWR       : std_logic := '1';
  signal HP85_ph1_clk   : std_logic := '0';
  signal HP85_ph2_clk   : std_logic := '0';
  signal HP85_ph12_clk  : std_logic := '0';
  signal HP85_ph22_clk  : std_logic := '0';
 -- HP-85 interface level translator direction control
  signal HP85_output_oen : std_logic := '0';
  signal HP85_output_dir : std_logic := '0';

-- TB UART_TX signals
signal uart_tx_start : std_logic := '0';
signal uart_tx_data : std_logic_vector(7 downto 0) := (others => '0');
signal uart_tx_busy : std_logic;

signal read_data : std_logic_vector(7 downto 0) := (others => '0');

constant  TEST_DATA     : std_logic_vector :=  X"3F"; 

-- internal signals
signal bus_phase : integer range 0 to 7;
signal clock_slower_downer : integer range 0 to 4;

begin

  gen_clock(clk);
 
  DUT : entity tape_control.top(str)

  port map (
    clk => clk,
    rst_button => rst_button,

    uart_rx => uart_to_dut,
    uart_tx => uart_from_dut,

    led_1 => led_1,
    led_2 => led_2,
    led_3 => led_3,
    led_4 => led_4,
    led_5 => led_5,

    B85_data => HP85_data,
    B85_nLMA => HP85_nLMA,
    B85_nRD     =>  HP85_nRD,
    B85_nWR     =>  HP85_nWR,
    B85_ph1_clk =>  HP85_ph1_clk,
    B85_ph2_clk =>  HP85_ph2_clk,

    -- HP-85 interface level translator direction control
    B85_output_oen =>  HP85_output_oen,
    B85_output_dir =>  HP85_output_dir
  );
  
TB_UART_TX : entity tape_control.uart_tx(rtl)
port map (
  clk  => clk,
  rst  => << signal DUT.rst : std_logic >>,
  push_pulse  => uart_tx_start,
  data  => uart_tx_data,
  busy  => uart_tx_busy,
 tx => uart_to_dut
);

 
TOP_PROC_SEQUENCER : process

procedure WriteAddress(constant address : std_logic_vector(15 downto 0)) is
  begin
    HP85_nLMA <= '1';
    wait until falling_edge(HP85_ph1_clk);
    HP85_data <=  (others => 'Z'); -- always
    HP85_nLMA <= '0';
    wait until rising_edge(HP85_ph22_clk);
    HP85_nLMA <= '1';
    wait until falling_edge(HP85_ph22_clk);
    HP85_data <= address(7 downto 0); -- Little Endian

    wait until falling_edge(HP85_ph1_clk);
    HP85_data <=  (others => 'Z'); -- always
    HP85_nLMA <= '0';
    wait until rising_edge(HP85_ph22_clk);
    HP85_nLMA <= '1';
    wait until falling_edge(HP85_ph22_clk);
    HP85_data <= address(15 downto 8); -- Little Endian

  end procedure;


-- Start the transmission of 1 char and add it to the tb_fifo
procedure WriteRegister(constant address : std_logic_vector(15 downto 0); constant data : std_logic_vector(7 downto 0)) is
begin
  report "Write " & integer'image(to_integer(unsigned(address))) & "==> " & integer'image(to_integer(unsigned(data)));
  WriteAddress(address);
  wait until falling_edge(HP85_ph1_clk);
  HP85_data <=  (others => 'Z'); -- always
  HP85_nWR <= '0';
  wait until rising_edge(HP85_ph22_clk);
  HP85_nWR <= '1';
  wait until falling_edge(HP85_ph22_clk);
  HP85_data <= data;
  wait until falling_edge(HP85_ph1_clk);
  HP85_data <=  (others => 'Z'); -- always

end procedure;

procedure ReadRegister(constant address : std_logic_vector(15 downto 0) ) is
  begin
    WriteAddress(address);
    wait until falling_edge(HP85_ph1_clk);
    HP85_data <=  (others => 'Z'); -- always
    HP85_nRD <= '0';
    wait until rising_edge(HP85_ph22_clk);
    HP85_nRD <= '1';
    wait until falling_edge(HP85_ph22_clk);
    read_data <= HP85_data;

    report "Read " & integer'image(to_integer(unsigned(address))) & "==> " & integer'image(to_integer(unsigned(read_data)));

  end procedure;

begin

-- Reset strobe
rst_button <= '0';
wait for 10 * clock_period;
rst_button <= '1';

wait for 10 * clock_period;

report "Write control register";


-- We start with a few writes
WriteRegister(TAPE_REGISTER_ADDRESS, "11001010");  -- 0xCA
wait for 10 * clock_period;
WriteRegister(TAPE_DATA_ADDRESS, "11000101");  -- 0xC5
wait for 10 * clock_period;
WriteRegister(TAPE_REGISTER_ADDRESS, "01010101");  -- 0x55
wait for 10 * clock_period;

-- Two reads
ReadRegister(TAPE_DATA_ADDRESS);
wait for 10 * clock_period;
ReadRegister(TAPE_REGISTER_ADDRESS);
wait for 220 * clock_period; -- 1us

-- Now we need to write from the rx uart into the status register and data register
-- write char to dut
report "uart Write status register ";
uart_tx_data <= std_logic_vector(to_unsigned(PKT_HDR_WR_STATUS, 8)); -- write status register packet
uart_tx_start <= '1';
wait until rising_edge(clk);
uart_tx_start <= '0';
wait for 2000 * clock_period; -- 100us
report "0x55 ";
uart_tx_data <= "01010110"; -- 0x56
uart_tx_start <= '1';
wait until rising_edge(clk);
uart_tx_start <= '0';
wait for 2000 * clock_period; -- 100us

report "uart Write data register ";
uart_tx_data <= std_logic_vector(to_unsigned(PKT_HDR_WR_DATA, 8)); -- write status register packet
uart_tx_start <= '1';
wait until rising_edge(clk);
uart_tx_start <= '0';
wait for 2000 * clock_period; -- 200us
report "0x55 ";
uart_tx_data <= "01011101"; -- 0x5D
uart_tx_start <= '1';
wait until rising_edge(clk);
uart_tx_start <= '0';
wait for 2000 * clock_period; -- 200us

report "uart Write tachometer ";
uart_tx_data <= std_logic_vector(to_unsigned(PKT_HDR_WR_TACH, 8)); -- tachometer to fastest speed
uart_tx_start <= '1';
wait until rising_edge(clk);
uart_tx_start <= '0';
wait for 2000 * clock_period; -- 200us
report "0x10";
uart_tx_data <= "00000010"; -- 0x10
uart_tx_start <= '1';
wait until rising_edge(clk);
uart_tx_start <= '0';
wait for 20000 * clock_period; -- 1ms

report "uart Write hole ";
uart_tx_data <= std_logic_vector(to_unsigned(PKT_HDR_WR_HOLE, 8)); -- tachometer to fastest speed
uart_tx_start <= '1';
wait until rising_edge(clk);
uart_tx_start <= '0';
wait for 2000 * clock_period; -- 200us
report "0x08";
uart_tx_data <= "00000010"; -- 2
uart_tx_start <= '1';
wait until rising_edge(clk);
uart_tx_start <= '0';
wait for 20000 * clock_period; -- 1ms


-- Read status
ReadRegister(TAPE_REGISTER_ADDRESS);
wait for 12 * clock_period; -- 1us
-- Read data
ReadRegister(TAPE_DATA_ADDRESS);
wait for 12 * clock_period;


wait for 12000 * clock_period;

print_test_ok;
finish;

end process; -- PROC_SEQUENCER

--
-- HP-85 Bus operation.
-- CPU SIDE OPERATION
-- /LMA, /RD, /WR are asserted on the falling edge of ph1_clk and remain asserted until the rising edge of ph22_clk
-- data written by the CPU is asserted on the falling edge of the ph22_clk and remain until the falling edge of ph1_clk
--
--
-- PERIPHERAL OPERATION
-- data written by the CPU is sampled on the rising edge of the ph1_clk
-- control signals are sampled on the falling edge of the ph2_clk
-- 
-- For READS: Data is asserted on the falling edge of the ph2_clk and remain until the falling edge of ph1_clk
-- 
-- 
-- TIMING
-- A full cycle take 8 x 200ns for a total cycle time of 1.6us. Our simulation runs at 1.64us per cycle.
-- Since a full write has 2 address cycles and a data cycle, consequtive writes take 4.8us unless it can make use of the address auto-increment.
--


TOP_PROC_HP_85_BUS : process

begin

  bus_phase <= 0;
  clock_slower_downer <= 0;

  wait for 200 * clock_period;

  loop
    wait on clk;

    case bus_phase is
      when 0 =>   -- rising edge of ph1 clk
        HP85_ph1_clk <= '1';
      when 1 =>   -- falling edge of ph1 clk
        HP85_ph1_clk <= '0';
      when 2 =>   -- rising edge of ph1.2 clk
        HP85_ph12_clk <= '1';
      when 3 =>   -- falling edge of ph1.2 clk
        HP85_ph12_clk <= '0';
      when 4 =>   -- rising edge of ph2 clk
        HP85_ph2_clk <= '1';
      when 5 =>   -- falling edge of ph2 clk
        HP85_ph2_clk <= '0';
      when 6 =>   -- rising edge of ph2.2 clk
        HP85_ph22_clk <= '1';
      when 7 =>   -- falling edge of ph2.2 clk
        HP85_ph22_clk <= '0';
    end case;

   
    if(clock_slower_downer = 4) then -- 0,1,2,3,4
      clock_slower_downer <= 0;
      if(bus_phase = 7) then -- 0,1,2,3,4,5,6,7
        bus_phase <= 0;
      else
        bus_phase <= bus_phase + 1;
      end if;
    else
      clock_slower_downer <= clock_slower_downer + 1;
    end if;

  end loop;
end process; -- PROC_HP_85_BUS

end architecture;