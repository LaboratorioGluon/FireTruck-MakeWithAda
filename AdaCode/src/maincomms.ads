with HAL;

package MainComms is

   
   type Command_type is (
                TEST_LED
                );
   
   type Len_type is range 1 .. 30; 
   type Command_data_type is new  HAL.UInt8_Array(0 .. 30);
   
   type Command is record
      Tag      : Command_Type;
      Len      : Len_type;
      Data     : Command_data_type;
   end record;
   
   function getLastCommand(raw_data: HAL.UInt8_Array) return Command;
   

end MainComms;
