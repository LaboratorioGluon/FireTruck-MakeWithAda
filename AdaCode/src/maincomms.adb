--with Console;
with STM32.Board; use STM32.Board;
with STM32.GPIO;
package body MainComms is

   function parseCommand(raw_data: HAL.UInt8_Array) 
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
      ret_command.NewData := True;
      return ret_command;
   end parseCommand;
   
   procedure updateCommands ( dev: in out RF24.RF24_Device ) is
      reg : HAL.UInt8;
      data:  HAL.UInt8_Array(0..32);
      cmd : Command;
      count : Integer := 0;
   begin
	
      while dev.newDataAvailable loop
         STM32.GPIO.Set(Red_LED);
         reg := dev.ReadWaitBlocking;
         dev.getData(data, count);
         cmd := parseCommand(data);
         Last_Command_array(cmd.Tag) := cmd;
        end loop;
   end updateCommands;

   
   function getLastCommand(Tag: Command_type) return Command is
   begin
      Last_Command_Array(Tag).NewData := False;
      return Last_Command_Array(Tag);
   end getLastCommand;
   
end MainComms;
