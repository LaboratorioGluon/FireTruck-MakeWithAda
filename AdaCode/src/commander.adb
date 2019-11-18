with Unchecked_Conversion;
with HAL;
with CarController;

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
            Target => Integer);
         LocalInt : Integer := 0;
      begin
         LocalInt := toInt(value);
         if LocalInt > Integer(Servo.degree'First) and
           LocalInt < Integer(Servo.degree'Last) then
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

      if Cmd.Data(0) > HAL.Uint8(CarController.Speed'First) and
        Cmd.Data(0) < HAL.Uint8(CarController.Speed'Last) then
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

      if Cmd.Data(0) > Hal.Uint8(CarController.Direction'Pos(CarController.NONE)) and
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

end Commander;
