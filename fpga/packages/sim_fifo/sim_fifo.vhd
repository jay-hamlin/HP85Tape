package sim_fifo is
  type sim_fifo is protected
   -- Add a new element to the list
  procedure push(constant data : in integer);

  -- Return the oldest element from the list without removing it
  impure function peek return integer;

  -- Remove oldest element from the list
  impure function pop return integer;

  -- return true if there are zero elements in the list
  impure function empty return boolean;

  end protected;
end package;


package body sim_fifo is

  type sim_fifo is protected body
  -- A linked list node.
  type item; -- an incomplete type. just create the name for now, definition 2 lines below.
  type ptr is access item;
  type item is record
      data : integer;
      next_item : ptr;
    end record;
      -- root of the linked list
      variable root : ptr;
    procedure push(constant data : in integer) is
      variable new_item : ptr;
      variable node : ptr;
      begin
        new_item := new item;
        new_item.data := data;

        if root = null then
            root := new_item;
         else
            node := root;

            while node.next_item /= null loop
              node := node.next_item;
            end loop;

            node.next_item := new_item;
        end if;
      end procedure;

      impure function peek return integer is

      begin
          return root.data;
       end function;

      impure function pop return integer is
        variable node : ptr;
        variable ret_val : integer;
      begin
        node := root;
        root := root.next_item;

        ret_val := node.data;
        deallocate(node);

        return ret_val;
      end function;

 
      impure function empty return boolean is
      begin
        return root = null;
      end function;
 
  end protected body;
end package body;
