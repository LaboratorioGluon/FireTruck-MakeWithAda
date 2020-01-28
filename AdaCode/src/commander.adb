with Unchecked_Conversion;
with HAL;
with CarController;
with Aim;
with STM32.Board;

package body Commander is
  
   
   function CommandServo(Ser1  : in out Servo.Servo;
                         Ser2  : in out Servo.Servo;
                         Cmd  : in MainComms.Command) 
                            return CommandStatus is
      use type Servo.degree;
      use type MainComms.Command_type;
      use type MainComms.Len_type;
      -- Excepted 2 bytes: <degrees servo1> <degrees servo2>
      ExceptedLen : constant MainComms.Len_type := 2;
      ExpectedTag : constant MainComms.Command_type := MainComms.SET_SERVO;

      -- Read data
      Degrees1 : Servo.degree := 0;
      Degrees2 : Servo.degree := 0;

      ReturnStatus: CommandStatus := FAILED;

      function toDeg is new Unchecked_Conversion
        (Source => HAL.UInt8,
         Target => Servo.degree);

      function isValidDeg(value: in HAL.UInt8) return Boolean is
         function toInt is new Unchecked_Conversion
           (Source => HAL.UInt8,
            Target => Servo.degree);
         LocalInt : Servo.degree := 0;
      begin
         LocalInt := toInt(value);
         if LocalInt >= Servo.degree'First and
           LocalInt <= Servo.degree'Last then
            return True;
         else
            return False;
         end if;
      end isValidDeg;

   begin
      -- Check that the TAG is correct
      if Cmd.Tag /= ExpectedTag then
         ReturnStatus := WRONG_TAG;
         return ReturnStatus;
      end if;

      -- Check the data len
      if Cmd.Len /= ExceptedLen then
         ReturnStatus := WRONG_LEN;
         return ReturnStatus;
      end if;

      if isValidDeg(Cmd.Data(0)) and isValidDeg(Cmd.Data(1)) then
         Degrees1 := toDeg(Cmd.Data(0));
         Degrees2 := toDeg(Cmd.Data(1));
         Ser1.setDegrees(Degrees1);
         Ser2.setDegrees(Degrees2);
         ReturnStatus := OK;
         return ReturnStatus;
      else
         ReturnStatus := ARGS_NOT_VALID;
         return ReturnStatus;
      end if;    

   end CommandServo;


   function CommandCarControllerSpeed( Cmd: in MainComms.Command)
                                         return CommandStatus is
      use type HAL.Uint8;
      use type MainComms.Command_type;
      use type MainComms.Len_type;
      ExceptedLen : constant MainComms.Len_type := 1;
      ExpectedTag : constant MainComms.Command_type := MainComms.SET_SPEED;

      LocalSpeed : CarController.Speed;

      ReturnStatus: CommandStatus := FAILED;
   begin
      -- Check that the TAG is correct
      if Cmd.Tag /= ExpectedTag then
         ReturnStatus := WRONG_TAG;
         return ReturnStatus;
      end if;

      -- Check the data len
      if Cmd.Len /= ExceptedLen then
         ReturnStatus := WRONG_LEN;
         return ReturnStatus;
      end if;

      if Cmd.Data(0) >= HAL.Uint8(CarController.Speed'First) and
        Cmd.Data(0) <= HAL.Uint8(CarController.Speed'Last) then
         LocalSpeed := CarController.Speed(Cmd.Data(0));
         CarController.setSpeed(LocalSpeed);
         ReturnStatus := OK;
         return ReturnStatus;
      else
         ReturnStatus := ARGS_NOT_VALID;
         return ReturnStatus;
      end if;           
   end CommandCarControllerSpeed;

   function CommandCarControllerDir( Cmd: in MainComms.Command)
                                       return CommandStatus is
      use type Hal.Uint8;
      use type MainComms.Command_type;
      use type MainComms.Len_type;
      ExceptedLen : constant MainComms.Len_type := 1;
      ExpectedTag : constant MainComms.Command_type := MainComms.SET_DIRECTION;

      LocalDir : CarController.Direction;

      ReturnStatus: CommandStatus := FAILED;
   begin
      -- Check that the TAG is correct
      if Cmd.Tag /= ExpectedTag then
         ReturnStatus := WRONG_TAG;
         return ReturnStatus;
      end if;

      -- Check the data len
      if Cmd.Len /= ExceptedLen then
         ReturnStatus := WRONG_LEN;
         return ReturnStatus;
      end if;

      if Cmd.Data(0) >= Hal.Uint8(CarController.Direction'Pos(CarController.NONE)) and
        Cmd.Data(0) < Hal.Uint8(CarController.Direction'Pos(CarController.DIR_END)) then
         LocalDir := CarController.Direction'Val(Cmd.Data(0));
         CarController.setDirection(LocalDir);
         ReturnStatus := OK;
         return ReturnStatus;
      else
         ReturnStatus := ARGS_NOT_VALID;
         return ReturnStatus;
      end if;           
   end CommandCarControllerDir;
   
   function CommandState( Cmd: in MainComms.Command;
                          State: out MainState.State)
                         return CommandStatus is
      
      use type Hal.Uint8;
      use type MainComms.Command_type;
      use type MainComms.Len_type;
      ExceptedLen : constant MainComms.Len_type := 1;
      ExpectedTag : constant MainComms.Command_type := MainComms.SET_MAIN_STATUS;

      ReturnStatus: CommandStatus := FAILED;
      
   begin
      -- Check that the TAG is correct
      if Cmd.Tag /= ExpectedTag then
         ReturnStatus := WRONG_TAG;
         return ReturnStatus;
      end if;

      -- Check the data len
      if Cmd.Len /= ExceptedLen then
         ReturnStatus := WRONG_LEN;
         return ReturnStatus;
      end if;
      
      if Cmd.Data(0) >= Hal.Uint8(MainState.State'Pos(MainState.OFF)) and
        Cmd.Data(0) < Hal.Uint8(MainState.State'Pos(MainState.ENDING)) then
         State := MainState.State'Val(Cmd.Data(0));
         ReturnStatus := OK;
      else
         ReturnStatus := ARGS_NOT_VALID;
      end if;
      return ReturnStatus;
      
   end CommandState;
   
   function CommandAim(Cmd : in MainComms.Command;
                       SerH  : in out Servo.Servo;
                       SerV  : in out Servo.Servo)  
                       return CommandStatus is
      use type Servo.degree;
      use type MainComms.Command_type;
      use type MainComms.Len_type;
      use type HAL.UInt8;
      
      ExceptedLen : constant MainComms.Len_type := 2;
      ExpectedTag : constant MainComms.Command_type := MainComms.INFO_TARGET;
      
      ReturnStatus: CommandStatus := FAILED;
      
      function toDeg is new Unchecked_Conversion
        (Source => HAL.UInt8,
         Target => Servo.degree);

      function isValidDeg(value: in HAL.UInt8) return Boolean is
         function toInt is new Unchecked_Conversion
           (Source => HAL.UInt8,
            Target => Servo.degree);
         LocalInt : Servo.degree := 0;
      begin
         LocalInt := toInt(value);
         if LocalInt >= Servo.degree'First and
           LocalInt <= Servo.degree'Last then
            return True;
         else
            return False;
         end if;
      end isValidDeg;
      
   begin
      
      if Cmd.Tag /= ExpectedTag then
         ReturnStatus := WRONG_TAG;
         return ReturnStatus;
      end if;
      
      -- Check the data len
      if Cmd.Len /= ExceptedLen then
         ReturnStatus := WRONG_LEN;
         return ReturnStatus;
      end if;
      
      if isValidDeg(Cmd.Data(0)) then
         Aim.Curernt_Angle := toDeg(Cmd.Data(0));
      else
         Aim.Curernt_Angle := 0;
         ReturnStatus := ARGS_NOT_VALID;
      end if;
      
      if Cmd.Data(1) >= Hal.UInt8( Aim.Distance'First ) and
        Cmd.Data(1) <= Hal.UInt8( Aim.Distance'Last ) then
         Aim.Current_Distance := Aim.Distance(Cmd.Data(1));
      else
         Aim.Current_Distance := 0;
         ReturnStatus := ARGS_NOT_VALID;
      end if;
      
      if ReturnStatus /= ARGS_NOT_VALID then
         
         Aim.Aim(Angle    => Aim.Curernt_Angle,
                 Dist     => Aim.Current_Distance,
                 ServoH   => SerH,
                 ServoV   => SerV);
      end if;
                                              
      return ReturnStatus;
   end CommandAim;

end Commander;
