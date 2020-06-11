library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
library tape_control;
use tape_control.constants.all;
use tape_control.types.all;
 
entity top is
  port (
    clk : in std_logic;
    rst_button : in std_logic;
 
    -- UART
    uart_rx : in std_logic;
    uart_tx : out std_logic;
 
    -- Debug LEDs
    led_1 : out std_logic;
    led_2 : out std_logic;
    led_3 : out std_logic;
    led_4 : out std_logic;
    led_5 : out std_logic;

    -- There is a spare test point on the header, pin 44
    J13_test_point : out std_logic;
     
    -- HP-85 Bus interface
    B85_data : inout std_logic_vector(7 downto 0);
    B85_nLMA : in std_logic;
    B85_nRD  : in std_logic;
    B85_nWR  : in std_logic;
    B85_ph1_clk : in  std_logic;
    B85_ph2_clk : in std_logic;
    -- HP-85 interface level translator direction control
    B85_output_oen : out std_logic;
    B85_output_dir : out std_logic

  );
end top; 
 
architecture str of top is

  -- internal interface
  signal status_register  : std_logic_vector(7 downto 0);
  signal status_reg_was_read  : std_logic;
  signal control_register  : std_logic_vector(7 downto 0);
  signal control_reg_avail  : std_logic;
  signal data_register_out  : std_logic_vector(7 downto 0);
  signal data_register_in  : std_logic_vector(7 downto 0);
  signal data_reg_avail  : std_logic;
  signal rst  : std_logic;

begin

RESET : entity tape_control.reset(rtl)
   port map (
    clk => clk,
    rst_in => rst_button,
    rst_out => rst
  );

DEBUG_LEDS : entity tape_control.debug_leds(rtl)
  port map (
    clk => clk,
    rst => rst,
    led_1_in => control_reg_avail,
    led_2_in => data_reg_avail,
    led_3_in => rst_button,
    led_1 => led_1,
    led_2 => led_2,
    led_3 => led_3,
    led_4 => led_4,
    led_5 => led_5
  );
 
HP85BUS_INST : entity tape_control.hp85bus_interface(rtl)
  port map(
    -- internal signals
    clk  => clk,
    rst  => rst,
      -- HP-85 system bus signals (the front end)
    ph1_clk => B85_ph1_clk,
    ph2_clk => B85_ph2_clk,
    bus_data => B85_data,
    bus_nLMA => B85_nLMA,
    bus_nRD => B85_nRD,
    bus_nWR => B85_nWR,
    bus_output_oen => B85_output_oen,
    bus_output_dir => B85_output_dir,
    -- Module output signals (the back end)
    status_register  =>status_register, 
    status_reg_was_read => status_reg_was_read,
    control_register  =>control_register,
    control_reg_avail =>control_reg_avail,
    data_register_out  =>data_register_out,
    data_register_in  =>data_register_in,
    data_reg_avail => data_reg_avail
    );

J13_test_point <= status_reg_was_read;

PROTOCOL_MACH_INST : entity tape_control.protocol_machine(rtl)
  port map (
    clk  => clk,
    rst  => rst,
    -- signals to the front end (HP85bus) module
    status_register  =>status_register,
    status_reg_was_read => status_reg_was_read,
    control_register  =>control_register,
    control_reg_avail  =>control_reg_avail,
    data_register_from  =>data_register_out,   -- protocol_machine --> hp85bus
    data_register_to  =>data_register_in,  --  hp85bus -->  protocol_machine
    data_reg_avail  =>data_reg_avail,
    -- uart rx, tx through TOP
    uart_tx  => uart_tx,
    uart_rx  => uart_rx
  );

end architecture;