library tape_control;
use tape_control.constants.all;

package sim_constants is

-- Lattice iCEStick has a 12MHz oscillator
constant clock_period : time := 1 sec / clock_frequency; -- 83.33ns

end package;