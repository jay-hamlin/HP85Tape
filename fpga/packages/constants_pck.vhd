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

  -- constant PKT_HDR_RD_STATUS : std_logic_vector(7 downto 0) := X"41"; 
  -- constant PKT_HDR_WR_STATUS : std_logic_vector(7 downto 0) := X"42";
  -- constant PKT_HDR_RD_CONTROL : std_logic_vector(7 downto 0) := X"43";
  -- constant PKT_HDR_WR_CONTROL : std_logic_vector(7 downto 0) := X"44";
  -- constant PKT_HDR_RD_DATA : std_logic_vector(7 downto 0) := X"45";
  -- constant PKT_HDR_WR_DATA : std_logic_vector(7 downto 0) := X"46";
  -- constant PKT_HDR_RD_MISC : std_logic_vector(7 downto 0) := X"47";
  -- constant PKT_HDR_WR_MISC : std_logic_vector(7 downto 0) := X"48";
  -- constant PKT_HDR_BAD_PACKET : std_logic_vector(7 downto 0) := X"49";
  constant PKT_HDR_RD_STATUS : integer := 16#41#; 
  constant PKT_HDR_WR_STATUS : integer := 16#42#;
  constant PKT_HDR_RD_CONTROL : integer := 16#43#;
  constant PKT_HDR_WR_CONTROL : integer := 16#44#;
  constant PKT_HDR_RD_DATA : integer := 16#45#;
  constant PKT_HDR_WR_DATA : integer := 16#46#;
  constant PKT_HDR_RD_MISC : integer:= 16#47#;
  constant PKT_HDR_WR_MISC : integer := 16#48#;
  constant PKT_HDR_BAD_PACKET : integer := 16#49#;

end package;