library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.finish;

library tape_control;

library tape_control_sim;
use tape_control_sim.sim_subprograms.all;
use tape_control_sim.sim_constants.all;
use tape_control.constants.all;


entity hp85bus_tb is
end hp85bus_tb; 

architecture sim of hp85bus_tb is

  -- common signals
  signal clk : std_logic := '1';
  signal rst : std_logic := '1';
  
  -- HP85 bus control signals
  signal hp85_ph1_clk : std_logic := '0';
  signal hp85_ph2_clk : std_logic := '0';
  signal hp85_ph12_clk : std_logic := '0';
  signal hp85_ph22_clk : std_logic := '0';
  signal hp85_bus_data : std_logic_vector(7 downto 0) := (others => '0');
  signal hp85_bus_nLMA : std_logic := '1';
  signal hp85_bus_nRD : std_logic := '1';
  signal hp85_bus_nWR : std_logic := '1';

  -- backend  signals
  signal status_register  : std_logic_vector(7 downto 0);
  signal control_register  : std_logic_vector(7 downto 0);
  signal control_reg_avail : std_logic ;  -- asserts when the control register has been written
  signal data_register_out : std_logic_vector(7 downto 0);
  signal data_register_in : std_logic_vector(7 downto 0) := (others => '0');
  signal data_reg_avail : std_logic ;   -- asserts when the data register has been writte
 
  signal read_data : std_logic_vector(7 downto 0) := (others => '0');

  constant  TEST_DATA     : std_logic_vector :=  X"3F"; 

  -- internal signals
  signal bus_phase : integer range 0 to 7;
  signal clock_slower_downer : integer range 0 to 4;
 
 
begin

  gen_clock(clk);

 HP85BUS_INTERFACE : entity tape_control.hp85bus_interface(rtl)
  port map (
      -- internal signals
      clk => clk,
      rst => rst,
      -- HP-85 system bus signals (the front end)
      ph1_clk => hp85_ph1_clk,
      ph2_clk => hp85_ph2_clk,
      bus_data => hp85_bus_data,
      bus_nLMA => hp85_bus_nLMA,
      bus_nRD => hp85_bus_nRD,
      bus_nWR => hp85_bus_nWR,
      -- Module output signals (the back end)
      status_register  => status_register,
      control_register   => control_register,
      control_reg_avail  => control_reg_avail,
      data_register_out   => data_register_out,
      data_register_in   => data_register_in,
      data_reg_avail  =>  data_reg_avail
  );
 
 
  PROC_SEQUENCER : process

    procedure WriteAddress(constant address : std_logic_vector(15 downto 0)) is
      begin
        hp85_bus_nLMA <= '1';
        wait until falling_edge(hp85_ph1_clk);
        hp85_bus_data <=  (others => 'Z'); -- always
        hp85_bus_nLMA <= '0';
        wait until rising_edge(hp85_ph22_clk);
        hp85_bus_nLMA <= '1';
        wait until falling_edge(hp85_ph22_clk);
        hp85_bus_data <= address(7 downto 0); -- Little Endian

        wait until falling_edge(hp85_ph1_clk);
        hp85_bus_data <=  (others => 'Z'); -- always
        hp85_bus_nLMA <= '0';
        wait until rising_edge(hp85_ph22_clk);
        hp85_bus_nLMA <= '1';
        wait until falling_edge(hp85_ph22_clk);
        hp85_bus_data <= address(15 downto 8); -- Little Endian
 
      end procedure;

  

   -- Start the transmission of 1 char and add it to the tb_fifo
   procedure WriteRegister(constant address : std_logic_vector(15 downto 0); constant data : std_logic_vector(7 downto 0)) is
    begin
      report "Write " & integer'image(to_integer(unsigned(address))) & "==> " & integer'image(to_integer(unsigned(data)));
      WriteAddress(address);
      wait until falling_edge(hp85_ph1_clk);
      hp85_bus_data <=  (others => 'Z'); -- always
      hp85_bus_nWR <= '0';
      wait until rising_edge(hp85_ph22_clk);
      hp85_bus_nWR <= '1';
      wait until falling_edge(hp85_ph22_clk);
      hp85_bus_data <= data;
      wait until falling_edge(hp85_ph1_clk);
      hp85_bus_data <=  (others => 'Z'); -- always

    end procedure;

    procedure ReadRegister(constant address : std_logic_vector(15 downto 0) ) is
      begin
        WriteAddress(address);
        wait until falling_edge(hp85_ph1_clk);
        hp85_bus_data <=  (others => 'Z'); -- always
        hp85_bus_nRD <= '0';
        wait until rising_edge(hp85_ph22_clk);
        hp85_bus_nRD <= '1';
        wait until falling_edge(hp85_ph22_clk);
        read_data <= hp85_bus_data;
  
        report "Read " & integer'image(to_integer(unsigned(address))) & "==> " & integer'image(to_integer(unsigned(read_data)));

      end procedure;

    begin
  
    -- Reset strobe
    wait for 10 * clock_period;
    rst <= '0';

    wait for 4 * clock_period;

    report "Write control register";
 
    WriteRegister(TAPE_REGISTER_ADDRESS, "11001010");
    wait for 10 * clock_period;
    WriteRegister(TAPE_DATA_ADDRESS, "11000101");
    wait for 10 * clock_period;
    WriteRegister(TAPE_REGISTER_ADDRESS, "01010101");
    wait for 10 * clock_period;
    WriteRegister(TAPE_DATA_ADDRESS, "10101010");
    wait for 10 * clock_period;
    ReadRegister(TAPE_DATA_ADDRESS);
    wait for 10 * clock_period;
    ReadRegister(TAPE_REGISTER_ADDRESS);

    wait for 16000 * clock_period;

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
  

  PROC_HP_85_BUS : process

    begin

      bus_phase <= 0;
      clock_slower_downer <= 0;

      wait for 10 * clock_period;

      loop
        wait on clk;

        case bus_phase is
          when 0 =>   -- rising edge of ph1 clk
            hp85_ph1_clk <= '1';
          when 1 =>   -- falling edge of ph1 clk
            hp85_ph1_clk <= '0';
          when 2 =>   -- rising edge of ph1.2 clk
            hp85_ph12_clk <= '1';
          when 3 =>   -- falling edge of ph1.2 clk
            hp85_ph12_clk <= '0';
          when 4 =>   -- rising edge of ph2 clk
            hp85_ph2_clk <= '1';
          when 5 =>   -- falling edge of ph2 clk
            hp85_ph2_clk <= '0';
          when 6 =>   -- rising edge of ph2.2 clk
            hp85_ph22_clk <= '1';
          when 7 =>   -- falling edge of ph2.2 clk
            hp85_ph22_clk <= '0';
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