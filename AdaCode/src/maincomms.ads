with HAL;
with RF24;

package MainComms is

   -- Command's definition
   type Command_type is (
                         TEST_LED,
                         SET_DIRECTION,
                         SET_SPEED,
                         SET_SERVO,
                         SET_PUMP,
                         SET_MAIN_STATUS,
                         INFO_TARGET,
                         NULL_CMD
                        );
   
   type Len_type is range 1 .. 30; 
   type Command_data_type is new  HAL.UInt8_Array(0 .. Integer(Len_type'Last));
   
   type Command is record
      Tag      : Command_Type;
      Len      : Len_type;
      Data     : Command_data_type;
      NewData  : Boolean;
   end record;
   
   
   -- Default commands
   null_Command      : Command := (Tag => NULL_CMD, Len => 1, Data => (others => 0), NewData => True);
   default_test_led  : Command := (Tag => TEST_LED, Len => 1, Data => (0 => 1, others => 0), NewData => True);
   default_direction : Command := (Tag => SET_DIRECTION, Len => 1, Data => (0 => 0, others => 0), NewData => True);
   default_speed     : Command := (Tag => SET_SPEED, Len => 1, Data => (0 => 25, others => 0), NewData => True);
   default_servo     : Command := (Tag => SET_SERVO, Len => 2, DATA => ( 0 => 0, 1 => 0, others => 0), NewData => True);
   default_mainStatus: Command := (Tag => SET_MAIN_STATUS, Len => 1, DATA => ( 0 => 0, 1 => 0, others => 0), NewData => True);  
   default_pump      : Command := (Tag => SET_PUMP, Len => 1, DATA => ( 0 => 0, others => 0), NewData => True);
   default_infoTarget: Command := (Tag => INFO_TARGET, Len => 2, DATA => (others => 0), NewData => False);

   
   -- Storing the last command of each type
   type Command_array is array (Command_Type) of Command;
   Last_Command_Array : Command_array := (TEST_LED => default_test_led,
                                          SET_DIRECTION => default_direction,
                                          SET_SPEED=> default_speed,
                                          SET_SERVO => default_servo,
                                          SET_PUMP => default_pump,
                                          SET_MAIN_STATUS => default_mainStatus,
                                          INFO_TARGET => default_infoTarget,
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
   

   -------------------------------------------------------------------
   --
   -- endCommand: Clear the newData flag in the Command so it will not
   --     be procesed again
   -- 
   -- params:
   --    - Tag: Identifier of the command 
   -------------------------------------------------------------------
   procedure endCommand(Tag: Command_type);

end MainComms;
