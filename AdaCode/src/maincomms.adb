--with Console;
with STM32.Board; use STM32.Board;
with STM32.GPIO;
package body MainComms is

   function parseCommand(raw_data: HAL.UInt8_Array) 
                           return Command is
      ret_command : Command;
      
   begin
      -- Generate the Command from raw data
      ret_command.Tag := Command_type'Val(raw_data(0));
      ret_command.Len := Len_type(raw_data(1));

      -- Fill the Data array
      for i in 0 .. raw_data(1) loop
         ret_command.Data(Standard.Integer(i)) := raw_data(Standard.Integer(i) + 2);
      end loop;

      -- Set the newData so we process this command in this loop
      ret_command.NewData := True;

      return ret_command;
   end parseCommand;
   
   procedure updateCommands ( dev: in out RF24.RF24_Device ) is
      reg : HAL.UInt8;
      data:  HAL.UInt8_Array(0..32);
      cmd : Command;
      count : Integer := 0;
   begin
      -- Read all the data until there are no more data-packets
      while dev.newDataAvailable loop
         -- In order to control that everything goes right
         -- we set the RED Led
         STM32.GPIO.Set(Red_LED);

         -- We already know that there is new data so this call is not really blocking
         reg := dev.ReadWaitBlocking;
         dev.getData(data, count);

         -- Convert from raw to Command.
         cmd := parseCommand(data);

         -- Store the command
         Last_Command_array(cmd.Tag) := cmd;
        end loop;
   end updateCommands;

   
   function getLastCommand(Tag: Command_type) return Command is
   begin
      return Last_Command_Array(Tag);
   end getLastCommand;
   
   procedure endCommand(Tag: Command_type) is
   begin
      Last_Command_Array(Tag).NewData := False;
   end endCommand;
   
end MainComms;
