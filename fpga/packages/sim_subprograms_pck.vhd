library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.finish;
use std.textio.all;

library tape_control;
library tape_control_sim;
use tape_control_sim.sim_constants.all;

use tape_control.types.all;

package sim_subprograms is

  -- Generate clock signal
  procedure gen_clock(signal clk : inout std_logic);

  -- print "TEST OK" message
  procedure print_test_ok;


end package;


package body sim_subprograms is

  procedure gen_clock(signal clk : inout std_logic) is
    begin
      clk <= not clk after clock_period/2;
  end procedure;


  procedure print_test_ok is
    variable str : line;
  begin
    write(str,string'("Test OK"));
    writeline(output,str);
  end procedure;

end package body;
