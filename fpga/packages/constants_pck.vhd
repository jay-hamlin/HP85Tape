library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package constants is

  constant clock_frequency : real := 12.0e6;
  
  constant baud_rate : natural := 115200;

  -- uart fifo depth on chars
  constant uart_fifo_depth : natural := 8;  

  -- HP-85 bus addresses
  constant  TAPE_REGISTER_ADDRESS : std_logic_vector :=  X"FF08";  --16#FF08#; -- 0xFF08 , octal 177410
  constant  TAPE_DATA_ADDRESS     : std_logic_vector :=  X"FF09";  -- 16#FF09#; -- 0xFF09 , octal 177411

  constant PKT_HDR_RD_STATUS  : integer := 16#53#; -- 'S'
  constant PKT_HDR_WR_STATUS  : integer := 16#73#; -- 's'
  constant PKT_HDR_RD_CONTROL : integer := 16#43#; -- 'C'
  constant PKT_HDR_WR_CONTROL : integer := 16#63#; -- 'c'
  constant PKT_HDR_RD_DATA    : integer := 16#44#; -- 'D'
  constant PKT_HDR_WR_DATA    : integer := 16#64#; -- 'd'
  constant PKT_HDR_RD_MISC    : integer := 16#4D#; -- 'M'
  constant PKT_HDR_WR_MISC    : integer := 16#6D#; -- 'm'
  constant PKT_HDR_RD_TACH    : integer := 16#54#; -- 'T'
  constant PKT_HDR_WR_TACH    : integer := 16#74#; -- 't'
  constant PKT_HDR_BAD_PACKET : integer := 16#42#; -- 'B'

end package;