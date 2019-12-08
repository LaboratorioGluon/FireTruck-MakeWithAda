with Servo;
with MainComms;
with MainState;

package Commander is

   type CommandStatus is (FAILED,
                          WRONG_TAG,
                          WRONG_LEN,
                          ARGS_NOT_VALID,
                          OK);
   
   function CommandServo(Ser1  : in out Servo.Servo;
                         Ser2  : in out Servo.Servo;
                         Cmd  : in MainComms.Command)
                         return CommandStatus;

   function CommandCarControllerSpeed( Cmd: in MainComms.Command)
                                      return CommandStatus;

   function CommandCarControllerDir( Cmd: in MainComms.Command)
                                    return CommandStatus;

   function CommandState( Cmd: in MainComms.Command;
                          State: out MainState.State)
                         return CommandStatus;
   
end Commander;
