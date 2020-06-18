library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library tape_control;
use tape_control.constants.all;

--    Tape Control Chip Protocol Machine
--    This is the glue between the hp85bus module front end and the uart module back end.
--    OPERATION
--
--    We have a very simple protocol with 2 byte packets.
--    Packets from the uart (external computer)
--    'S',0x00    --> Read status register.
--    's',0xnn    --> Write status register. second byte it write value
--    'C',0x00    --> Read control register.
--    'c',0xnn    --> Write control register. second byte it write value
--    'D',0x00    --> Read data register.
--    'd',0xnn    --> Write data register. second byte it write value
--    'M',0x00    --> Read misc. status and error codes. TBD
--    'm',0x00    --> write misc. contorl codes. TBD
--    'T',0x00    --> Read tachometer
--    't',0x00    --> write tachometer
--
--    Read commands will return the same packet but with 0x00 filled in with the register's value.
--    Also:
--        1- A data register write should set the STATUS_READY_BIT bit in status. 
--        2- Any write to the control register from the HP85 will produce a Read control register packet
--        3- Any write to the data register from the HP85 will produce a Read data register packet
--
--    This is a very siple "starter" protcol. Lets see how it works.
--
--     Tape Control Chip status register
--     HP-85 bus address 0xFF08  // Octal 177410
--     This register is read only from the HP-85
--     
--     STATUS_CASSETTE_IN_BIT = 0,  // Cassette in
--     STATUS_STALL_BIT = 1,        // Tape stalled
--     STATUS_ILIM_BIT = 2,         // Overcurrent
--     STATUS_WRITE_EN_BIT = 3,     // Write enabled
--     STATUS_HOLE_BIT = 4,         // Hole detected
--     STATUS_GAP_BIT = 5,          // Gap detected
--     STATUS_TACH_BIT = 6,         // Tachometer tick
--     STATUS_READY_BIT = 7         // Ready -meaning, there is a DATA byte available to read.
--
--
--     Tape Control Chip control register
--     HP-85 bus address 0xFF08  // Octal 177410
--     This register is write only from the HP-85
--
--     CONTROL_TRACK_NO_BIT = 0,     // Track selection
--     CONTROL_POWER_UP_BIT = 1,     // Tape controller power up
--     CONTROL_MOTOR_ON_BIT = 2,     // Motor control
--     CONTROL_DIR_FWD_BIT = 3,      // Tape direction = forward
--     CONTROL_FAST_BIT = 4,         // Speed = fast
--     CONTROL_WRITE_DATA_BIT = 5,   // Write data
--     CONTROL_WRITE_SYNC_BIT = 6,   // Write SYNC
--     CONTROL_WRITE_GAP_BIT = 7     // Write gap
--
--
-- 
-- protocol_machine PARAMETER USEAGE
-- status_register    OUTPUT[7:0]  -- this is read only from the hp85
-- control_register   INPUT[7:0]  --  this is write only from the hp85
-- control_reg_avail  INPUT  -- asserts when the control register has been written from the hp85 (available to read here)
-- data_register_from INPUT[7:0]  -- register read data from the hp85
-- data_register_to   OUTPUT[7:0]  -- register write data to the hp85
-- data_reg_avail     INPUT  -- asserts when the data register has been written from the hp85. (available to read here)
-- uart_tx            OUTPUT  -- uart data to outside world 
-- uart_rx            INPUT  -- uart data from outside world
-- 

entity protocol_machine is
  port (
    clk : in std_logic;
    rst : in std_logic;
    
    -- signals to the front end (HP85bus) module
    status_register  : buffer std_logic_vector(7 downto 0);
    status_reg_was_read : in std_logic;  -- asserts when the status register was read from the HP-85
    control_register  : in std_logic_vector(7 downto 0);
    control_reg_avail : in std_logic;  -- asserts when the control register has been written
    data_register_from  : in std_logic_vector(7 downto 0);
    data_register_to  : buffer std_logic_vector(7 downto 0);
    data_reg_avail : in std_logic;  -- asserts when the data register has been writte
    -- uart rx, tx through TOP
    uart_tx : out std_logic;
    uart_rx : in std_logic;
    -- tachometer debug
    tach_flag    : out std_logic;
    hole_flag    : out std_logic
  );
end protocol_machine; 

architecture rtl of protocol_machine is
  
  -- TX signals
  signal tx_start : std_logic := '0';
  signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
  signal tx_busy : std_logic;

  -- RX signals
  signal rx_data : std_logic_vector(7 downto 0);
  signal rx_valid : std_logic;
  signal rx_stop_bit_error : std_logic;

  -- Internal registers
  signal tachometer    : std_logic_vector(7 downto 0);
  signal misc_register : std_logic_vector(7 downto 0);
  signal pkt_byte_0    : std_logic_vector(7 downto 0);
  signal pkt_byte_1    : std_logic_vector(7 downto 0);
  signal hole_counter  : std_logic_vector(7 downto 0);
  -- Flags
  signal control_reg_serviced : std_logic;
  signal data_reg_serviced    : std_logic;
  signal rx_valid_serviced    : std_logic;


  -- debug Flags
  signal  tach_toggle_state : std_logic;

  -- For counting tachometer periods. 35us
  constant clock_cycles_per_tach : integer := integer(clock_frequency * real(0.000035));
  subtype tach_counter_type is integer range 0 to clock_cycles_per_tach - 1;
  signal tach_counter : tach_counter_type;
  subtype tach_downcount_type is integer range 0 to 255;
  signal tach_downcount : tach_downcount_type;

  type state_type is (
    IDLE,
    PKT_RD_STATUS,  --    'S',0x00    --> Read status register.
    PKT_WR_STATUS,  --    's',0xnn    --> Write status register. second byte it write value
    PKT_RD_CONTROL, --    'C',0x00    --> Read control register.
    PKT_WR_CONTROL, --    'c',0xnn    --> Write control register. second byte it write value
    PKT_RD_DATA,    --    'D',0x00    --> Read data register.
    PKT_WR_DATA,    --    'd',0xnn    --> Write data register. second byte it write value
    PKT_RD_MISC,    --    'M',0x00    --> Read misc. status and error codes. TBD
    PKT_WR_MISC,    --    'm',0x00    --> write misc. contorl codes. TBD
    PKT_RD_TACH,    --    'T',0x00    --> read tachomter.  2nd byte is speed - 0 is off   
    PKT_WR_TACH,    --    't',0x00    --> write tachomter.  2nd byte is speed - 0 is off   
    PKT_RD_HOLE,    --    'T',0x00    --> read hole counter.  2nd byte is speed - 0 is off   
    PKT_WR_HOLE,    --    't',0x00    --> write hole counter.  2nd byte is speed - 0 is off   
    BAD_PACKET);
  signal state : state_type;

  type tx_pkt_state_type is (
    PKT_IDLE,
    PKT_PUSH_BYTE_0,  --    
    PKT_PUSH_BYTE_1,  --   
    PKT_FINISH);
  signal tx_pkt_state : tx_pkt_state_type;

begin

  
  UART_TX_INST : entity tape_control.uart_tx(rtl)
  port map (
    clk  => clk,
    rst  => rst,
    push_pulse  => tx_start,
    data  => tx_data,
    busy  => tx_busy,
    tx => uart_tx
  );

  UART_RX_INST : entity tape_control.uart_rx(rtl)
  port map (
      clk => clk,
      rst => rst,
      rx  => uart_rx,
      data => rx_data,
      valid => rx_valid, 
      stop_bit_error => rx_stop_bit_error
    );
  

PROTOCOL_PROCESS : process(clk)

begin
  if rising_edge(clk) then
    if rst = '1' then
      pkt_byte_0 <= (others => '0'); 
      pkt_byte_1 <= (others => '0'); 
      tx_pkt_state <= PKT_IDLE;
      status_register <= (others => '0'); 
      data_register_to <= (others => '0');
      misc_register <= (others => '0');
      tachometer <= (others => '0');
      hole_counter <= (others => '0');
      tach_downcount <= 0;
      -- debugging flags
      hole_flag <= '0'; -- bit 4 status reg
      tach_flag <= '0'; -- bit 6 status reg
    else
      --
      -- Tachometer information
      -- The tape runs at 10 in/s low speed or 60in/s high speed.
      -- There are 500 pulses per revolution of the capstan motor and about 1"of tape per revolution
      -- Measured tach pulses are:
      --    210us per tick low speed
      --    35us per tick high speed
      -- We will set 35us as our tach clock and use the 2nd byte of the packeet as speed
      --  0 = off
      --  1 = 35us
      --  6 = 210us
      -- I have been told that the controller chip does a 1/16 divide of the tach. So we probably
      -- use these slower speeds
      --  0 = off
      --  16 = 560us = 0.56ms
      --  96 = 3360us = 3.36ms

      if (status_reg_was_read = '1') then  -- the status register was read so we clear tach
        tach_flag <= '0';
        status_register(6) <= '0';  -- TACH bit
      end if;

      -- first we make the 35us counter
      if tach_counter = tach_counter_type'high then
        -- we get here once every 35us
        if tachometer /=  b"00000000" then  -- is it even running?
          if (tach_downcount = 0) then
            -- set the tach bit in the status register
            -- and set or clear the hole bit as needed
            -- hole_counter says to set the hole for x tach counts
            tach_flag <= '1';   
            status_register(6) <= '1';  -- TACH bit

            if(hole_counter =  b"00000000") then
              hole_flag <= '0';     
              status_register(4) <= '0';  -- HOLE bit  
            else    
              hole_counter <= std_logic_vector(unsigned(hole_counter)-1);
              hole_flag <= '1';
              status_register(4) <= '1';  -- HOLE bit
            end if;

            tach_downcount <= tach_downcount_type(to_integer(unsigned(tachometer))-1);
          else
            tach_downcount <= tach_downcount - 1;
          end if;
        end if;
        tach_counter <= 0;
      else
        tach_counter <= tach_counter + 1;
      end if;

      -- Handle incoming uart packets
      case tx_pkt_state is
        -- push 2 bytes onto the tx uart fifo over 4 clock cycles
        when PKT_IDLE =>   -- IDLE
          if pkt_byte_0 /= B"00000000" then -- we have a packet to send
            tx_pkt_state <= PKT_PUSH_BYTE_0; -- begin
            tx_start <= '1';
            tx_data <= pkt_byte_0;
          end if;
        when PKT_PUSH_BYTE_0 =>
          tx_start <= '0';
          tx_pkt_state <= PKT_PUSH_BYTE_1; -- next char
        when PKT_PUSH_BYTE_1 =>
          tx_pkt_state <= PKT_FINISH;
          tx_start <= '1';
          tx_data <= pkt_byte_1; -- char 2
        when PKT_FINISH =>
          tx_start <= '0';
          tx_pkt_state <= PKT_IDLE; -- done
          pkt_byte_0 <= (others => '0'); 
          pkt_byte_1 <= (others => '0');     
      end case;

      if (control_reg_avail = '1') then  -- the control register was written
        if (control_reg_serviced = '0') then
          pkt_byte_0 <= std_logic_vector(to_unsigned(PKT_HDR_RD_CONTROL, 8));
          pkt_byte_1 <= control_register;  -- read control register packet
          control_reg_serviced <= '1';
          -- we clear the READY bit in the status register
          -- the next write to status will set it.
          status_register(7) <= '0';  -- STATUS_READY_BIT = 
        end if;
      else
        control_reg_serviced <= '0';
      end if;

      if (data_reg_avail = '1') then 
        if (data_reg_serviced = '0') then 
          -- read data register packet
          pkt_byte_0 <= std_logic_vector(to_unsigned(PKT_HDR_RD_DATA, 8));
          pkt_byte_1 <= data_register_from;  -- read data register packet
          data_reg_serviced <= '1';
        end if;
      else
        data_reg_serviced <= '0';
      end if;

      if (rx_valid = '1') then 
        if (rx_valid_serviced = '0') then 
          rx_valid_serviced <= '1';
          case state is
            when IDLE =>
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_RD_STATUS, 8))) then
                state <= PKT_RD_STATUS;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_WR_STATUS, 8))) then
                state <= PKT_WR_STATUS;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_RD_CONTROL, 8))) then
                state <= PKT_RD_CONTROL;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_WR_CONTROL, 8))) then
                state <= PKT_WR_CONTROL;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_RD_DATA, 8))) then
                state <= PKT_RD_DATA;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_WR_DATA, 8))) then
                state <= PKT_WR_DATA;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_RD_MISC, 8))) then
                state <= PKT_RD_MISC;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_WR_MISC, 8))) then
                state <= PKT_WR_MISC;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_RD_TACH, 8))) then
                state <= PKT_RD_TACH;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_WR_TACH, 8))) then
                state <= PKT_WR_TACH;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_RD_HOLE, 8))) then
                state <= PKT_RD_HOLE;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_WR_HOLE, 8))) then
                state <= PKT_WR_HOLE;
              end if;
              if (rx_data = std_logic_vector(to_unsigned(PKT_HDR_BAD_PACKET, 8))) then
                state <= BAD_PACKET;
              end if;
            when   PKT_RD_STATUS =>  --    'S',0x00    --> Read status register.
              -- read status register packet
              pkt_byte_0 <= std_logic_vector(to_unsigned(PKT_HDR_RD_STATUS, 8));
              pkt_byte_1 <= status_register; 
              state <= IDLE;
            when   PKT_WR_STATUS =>  --    's',0xnn    --> Write status register. second byte it write value
              status_register(0) <= rx_data(0);
              status_register(1) <= rx_data(1);
              status_register(2) <= rx_data(2);
              status_register(3) <= rx_data(3);
        --      status_register(4) <= rx_data(4);  -- HOLE bit
              status_register(5) <= rx_data(5);
        --      status_register(6) <= rx_data(6);  -- TACH bit
              status_register(7) <= rx_data(7);  -- DATA ready bit
             
              state <= IDLE;
            when   PKT_RD_CONTROL => --    'C',0x00    --> Read control register.
              -- read control register packet
              pkt_byte_0 <= std_logic_vector(to_unsigned(PKT_HDR_RD_CONTROL, 8));
              pkt_byte_1 <= control_register; 
              state <= IDLE;
            when   PKT_WR_CONTROL => --    'c',0xnn    --> Write control register. second byte it write value
            -- control register is read only, this would be illegal
            --  control_register <= rx_data;
              state <= IDLE;
            when   PKT_RD_DATA =>    --    'D',0x00    --> Read data register.
              -- read data register packet
              pkt_byte_0 <= std_logic_vector(to_unsigned(PKT_HDR_RD_DATA, 8));
              pkt_byte_1 <= data_register_from; 
              state <= IDLE;
            when   PKT_WR_DATA =>    --    'd',0xnn    --> Write data register. second byte it write value
              data_register_to <= rx_data;
              state <= IDLE;
            when   PKT_RD_MISC =>    --    'X',0x00    --> Read misc. status and error codes. TBD
              -- read misc register packet
              pkt_byte_0 <= std_logic_vector(to_unsigned(PKT_HDR_RD_MISC, 8));
              pkt_byte_1 <= misc_register; 
              state <= IDLE;
            when   PKT_WR_MISC =>    --    'x',0x00    --> write misc. control codes. TBD
              misc_register <= rx_data;
              state <= IDLE;
            when   PKT_RD_TACH =>    --    'X',0x00    --> Read misc. status and error codes. TBD
              -- read misc register packet
              pkt_byte_0 <= std_logic_vector(to_unsigned(PKT_HDR_RD_TACH, 8));
              pkt_byte_1 <= tachometer; 
              state <= IDLE;
            when   PKT_WR_TACH =>    --    'x',0x00    --> write tachometer
              tachometer <= rx_data;
              state <= IDLE;
            when   PKT_RD_HOLE =>    --    'X',0x00    --> Read misc. status and error codes. TBD
              -- read misc register packet
              pkt_byte_0 <= std_logic_vector(to_unsigned(PKT_HDR_RD_HOLE, 8));
              pkt_byte_1 <= hole_counter; 
              state <= IDLE;
            when   PKT_WR_HOLE =>    --    'x',0x00    --> write tachometer
              hole_counter <= rx_data;
              state <= IDLE;
            when   BAD_PACKET =>
              pkt_byte_0 <= std_logic_vector(to_unsigned(PKT_HDR_BAD_PACKET, 8));
              pkt_byte_1 <= (others => '0'); 
              state <= IDLE;
          end case;
        end if;
      else
        rx_valid_serviced <= '0';
      end if;
    end if; -- not reset
  end if;  -- clk rising
end process;

end architecture;