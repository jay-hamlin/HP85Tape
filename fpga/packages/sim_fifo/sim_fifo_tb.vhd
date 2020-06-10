library tape_control_sim;
use tape_control_sim.sim_fifo.all;
use tape_control_sim.sim_subprograms.all;

use std.textio.all;
use std.env.finish;


entity sim_fifo_tb is
end sim_fifo_tb; 

architecture arch of sim_fifo_tb is

  shared variable dut : sim_fifo;


  subtype test_range is integer range 0 to 5;

begin

  PROC_SEQUENCER : process
    variable val : integer;
    variable str : line;
  begin
    assert dut.empty
    report "List not empty at startup"
    severity failure;

    -- test push
    for i in test_range loop
      write(str, string'("Pushing " & integer'image(i)));
      writeline(output,str);
      dut.push(i);

      assert not dut.empty
      report "List empty after pushing element: " & integer'image(i)
      severity failure;  
    end loop;

     -- test pop
    for i in test_range loop
      assert not dut.empty
        report "List empty before expected: " & integer'image(i)
        severity failure; 

      assert dut.peek = i
        report "Peeked element differs from expected: " & integer'image(i)
        severity failure;
   
      val := dut.pop;
      write(str, string'("Popped " & integer'image(val)));
      writeline(output,str);

      assert val = i
        report "Popped element differs from expected: " & integer'image(i)
        severity failure;

    end loop;
    
    assert dut.empty
    report "List not empty after popping all elements"
    severity failure;

    print_test_ok;
    finish;
    wait;
  end process;

end architecture;