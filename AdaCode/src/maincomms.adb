--with Console;

package body MainComms is

   function getLastCommand(raw_data: HAL.UInt8_Array) 
                           return Command is
      ret_command : Command;
      
   begin
--        Console.putLine("Data: ");
--        for i in 0 .. 10 loop
--           Console.put(raw_data(i)'Img & ", ");
--        end loop;
--        Console.putChar(ASCII.CR);
      ret_command.Tag := Command_type'Val(raw_data(0));
      ret_command.Len := Len_type(raw_data(1));
      for i in 0 .. raw_data(1) loop
         ret_command.Data(Standard.Integer(i)) := raw_data(Standard.Integer(i) + 2);
      end loop;
      
      return ret_command;
   end getLastCommand;

end MainComms;
