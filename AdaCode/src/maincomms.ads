with HAL;
with RF24;

package MainComms is

   -- Command's definition
   type Command_type is (
                         TEST_LED,
                         SET_DIRECTION,
                         SET_SPEED,
                         NULL_CMD
                        );
   
   type Len_type is range 1 .. 30; 
   type Command_data_type is new  HAL.UInt8_Array(0 .. 30);
   
   type Command is record
      Tag      : Command_Type;
      Len      : Len_type;
      Data     : Command_data_type;
   end record;
   
   
   -- Default commands
   null_Command : Command := (Tag => NULL_CMD, Len => 1, Data => (others => 0));
   default_test_led: Command := (Tag => TEST_LED, Len => 1, Data => (0 => 1, others => 0));
   default_direction: Command := (Tag => SET_DIRECTION, Len => 1, Data => (0 => 0, others => 0));
   default_speed: Command := (Tag => SET_SPEED, Len => 1, Data => (0 => 25, others => 0));
   
   -- Storing the last command of each type
   type Command_array is array (Command_Type) of Command;
   Last_Command_Array : Command_array := (TEST_LED => default_test_led,
                                          SET_DIRECTION => default_direction,
                                          SET_SPEED=> default_speed,
                                          NULL_CMD => null_Command);
   
   -------------------------------------------------------------------
   --
   -- parseCommand: Parse a UInt8 array and generate Command record
   -- 
   -- params:
   --    - raw_data: Uint8 array with the received data 
   -------------------------------------------------------------------
   function parseCommand(raw_data: HAL.UInt8_Array) return Command;
   
   
   -------------------------------------------------------------------
   --
   -- updateCommands: Parse a UInt8 array and generate Command record
   -- 
   -- params:
   --    - dev: An already intialized RF24_Device from where the commands
   --           should be read
   -------------------------------------------------------------------
   procedure updateCommands( dev: in out  RF24.RF24_Device );
   
   -------------------------------------------------------------------
   --
   -- getLastCommand: get the last command received of a type
   -- 
   -- params:
   --    - Tag: Identifier of the requested command 
   -------------------------------------------------------------------
   function getLastCommand(Tag: Command_type) return Command;

end MainComms;
