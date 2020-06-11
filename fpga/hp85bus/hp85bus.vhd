library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tape_control;
use tape_control.constants.all;

--  OPERATION
-- data written by the CPU is sampled on the rising edge of the ph1_clk
-- control signals are sampled on the falling edge of the ph2_clk
-- 
-- For READS: Data is asserted on the falling edge of the ph2_clk and remain until the falling edge of ph1_clk

entity hp85bus_interface is
  port (
    -- internal signals
    clk : in std_logic;
    rst : in std_logic;
    -- HP-85 system bus signals (the front end)
    ph1_clk : in std_logic;
    ph2_clk : in std_logic;
    bus_data : inout std_logic_vector(7 downto 0);
    bus_nLMA : in std_logic;
    bus_nRD : in std_logic;
    bus_nWR : in std_logic;
    bus_output_oen : out std_logic; -- PIO2.11 -fpga pin 45 connects to 74LVC4245 /OE pin.  ACTIVE LOW
    bus_output_dir : out std_logic; -- PIO2.15 -fpga pin 60 connects to 74LVC4245 DIR pin. HIGH = BUS INPUT, LOW = BUS OUTPUT
    -- Module output signals (the back end)
    status_register  : in std_logic_vector(7 downto 0);
    status_reg_was_read : out std_logic;  -- asserts when the status register was read 
    control_register  : out std_logic_vector(7 downto 0);
    control_reg_avail : out std_logic;  -- asserts when the control register has been written
    data_register_out  : out std_logic_vector(7 downto 0);
    data_register_in  : in std_logic_vector(7 downto 0);
    data_reg_avail : out std_logic  -- asserts when the data register has been written
   );
end hp85bus_interface; 

architecture rtl of hp85bus_interface is

  -- Internal registers
  signal latched_address : std_logic_vector(15 downto 0);
  signal latched_data : std_logic_vector(7 downto 0);

  -- Internal flags
  signal nLMA_event : std_logic;
  signal nWR_event  : std_logic;
  signal nRD_event  : std_logic;
  signal rs_notQ  : std_logic;
  signal rs_Q  : std_logic;
  signal dir  : std_logic;
  signal gatedRD_event : std_logic;

  begin

  -- 
  -- dir (direction OUTPUT ENABLE) is asserted from the falling edge of ph2_clk to the rising edge of ph1_clk during a read event
  -- this is the time it would be ok to put data onto the bus

  -- First we use an RS latch to find the falling edge of ph2_clk and rising edge of ph1_clk
  rs_notQ <= (ph2_clk nor rs_Q); -- SET
  rs_Q  <= (ph1_clk nor rs_notQ); -- RESET
  
  -- We need to cut nRD_event short on the rising edge of ph2_clk or there is a glitch on the enable output
  gatedRD_event <= (gatedRD_event or nRD_event) and (not ph2_clk); -- RSET
 
 -- AND the output of the RS latch with NOT ph1_clk to get the rising edge...
  dir <= (((not ph2_clk) and rs_Q) and (gatedRD_event and nRD_event)); 
  -- Use it to drive the output enable and 74LVC4245A external buffer
  bus_output_oen <= '0'; -- ok to be enabled always
  bus_output_dir <= (not dir); -- assert output enable to the external buffer /OEN which is active low
  bus_data <= latched_data when (dir = '1') else "ZZZZZZZZ";  -- bus_data is an output or tri-stated

  HP85BUS_CLK_PH1_PROC : process(ph1_clk)
  begin
    if rising_edge(ph1_clk) then
      control_reg_avail <= '0';  -- default value
      data_reg_avail <= '0';  -- default value
      status_reg_was_read <= '0';  -- default value
      
      if nLMA_event = '1' then
        -- Little Endian
        latched_address(7 downto 0) <= latched_address(15 downto 8);    -- similar to  "address_latch >>= 8;             
        latched_address(15 downto 8) <= bus_data;
      end if;
      if nWR_event = '1' then
        if (latched_address = TAPE_REGISTER_ADDRESS) then
          control_register <= bus_data;
          control_reg_avail <= '1';
        end if;
        if (latched_address = TAPE_DATA_ADDRESS) then
          data_register_out <= bus_data;
          data_reg_avail <= '1';
        end if;  
      end if;
      if nRD_event = '1' then
        if (latched_address = TAPE_REGISTER_ADDRESS) then
          status_reg_was_read <= '1';
        end if;
      end if;
    end if;
  end process;

  HP85BUS_CLK_PH2_PROC : process(ph2_clk)
  begin
     -- control signals are sampled on the falling edge of the ph2_clk
    -- For READS: Data is asserted on the falling edge of the ph2_clk and remain until the falling edge of ph1_clk
  
    if falling_edge(ph2_clk) then
      nLMA_event <= '0';
      nWR_event <= '0';
      nRD_event <= '0';

      if (bus_nLMA = '0') then -- address
        nLMA_event <= '1';
      end if;
      if (bus_nWR = '0') then -- write
        nWR_event <= '1';
      end if;
      if (bus_nRD = '0') then -- read 
        if (latched_address = TAPE_REGISTER_ADDRESS) then
          nRD_event <= '1';
          latched_data <= status_register;
        end if;
        if (latched_address = TAPE_DATA_ADDRESS) then
          nRD_event <= '1';
          latched_data <= data_register_in;
        end if;
      end if;
    end if;
  end process;

end architecture;