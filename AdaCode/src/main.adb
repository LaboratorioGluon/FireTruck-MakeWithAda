with Ada.Real_Time;

with STM32.GPIO; use STM32.GPIO;
with STM32.Device;
with STM32.Board; use STM32.Board;
with HAL;
with Console;
with rf24;
with STM32.Timers;

with MainComms;
with CarController;
with Servo;
with Unchecked_Conversion;
with Commander;
with MainState;

procedure Main is
   use type Ada.Real_Time.Time;
   use type HAL.Uint8;
   use type Servo.degree;
   use type MainState.State;
   
   Next_execution: Ada.Real_Time.Time;
   Period: constant Ada.Real_Time.Time_Span:= Ada.Real_Time.To_Time_Span(0.5);


   RF24Dev : RF24.RF24_Device(STM32.Device.SPI_2'Access);

   last_command : MainComms.Command;
   last_command_status : Commander.CommandStatus;


   PumpPin    : STM32.GPIO.GPIO_Point := STM32.Device.PD4;
   PumpPinNot : STM32.GPIO.GPIO_Point := STM32.Device.PD3;
   
   servo1 : Servo.Servo;
   servo2 : Servo.Servo;
   
   servo_vertical: Servo.Servo renames servo2;
   
begin
   STM32.Board.Configure_User_Button_GPIO;
   STM32.Board.Initialize_LEDs;
   
   -- We need to enable and set to HIGH PumpPinNot ASAP.
   STM32.Device.Enable_Clock (PumpPin);
   STM32.GPIO.Configure_IO (PumpPin,
                            (Mode_Out,
                             Resistors   => Floating,
                             Output_Type => Push_Pull,
                             Speed       => Speed_100MHz
                            ));
   PumpPin.Set;
   STM32.Device.Enable_Clock (PumpPinNot);
   STM32.GPIO.Configure_IO (PumpPinNot,
                            (Mode_Out,
                             Resistors   => Floating,
                             Output_Type => Push_Pull,
                             Speed       => Speed_100MHz
                            ));
   PumpPinNot.Clear;
   
   
   -- Servos
   servo1.Init(Pin            => STM32.Device.PB5,
               Alternate_func => STM32.Device.GPIO_AF_TIM3_2,
               Servo_Timer    => STM32.Device.Timer_3'access,
               TimerChan      => STM32.Timers.Channel_2);
   
   servo1.setCalibration(Zero   => 1500,
                         Top    => 2500,
                         Bottom => 600);
   
   servo1.setLimits(Max_Degree => 90,
                    Min_Degree => -90);
   
   servo2.Init(Pin            => STM32.Device.PB4,
               Alternate_func => STM32.Device.GPIO_AF_TIM3_2,
               Servo_Timer    => STM32.Device.Timer_3'access,
               TimerChan      => STM32.Timers.Channel_1);
   
   servo2.setCalibration(Zero   => 1600,
                         Top    => 2600,
                         Bottom => 600);
   
   servo2.setLimits(Max_Degree => 90,
                    Min_Degree => -90);
   
   
   --- Car controller
   CarController.InitLeftMotor(LEFT_FWD     => STM32.Device.PE0,
                               LEFT_BCK     => STM32.Device.PE2,
                               LEFT_PWM     => STM32.Device.PB8,
                               LEFT_Timer   => STM32.Device.Timer_4'Access,
                               LEFT_Channel => STM32.Timers.Channel_3,
                               LEFT_Af      => STM32.Device.GPIO_AF_TIM4_2);

   CarController.InitRightMotor(RIGHT_FWD     => STM32.Device.PE1,
                                RIGHT_BCK     => STM32.Device.PE3,
                                RIGHT_PWM     => STM32.Device.PB9,
                                RIGHT_Timer   => STM32.Device.Timer_4'Access,
                                RIGHT_Channel => STM32.Timers.Channel_4,
                                RIGHT_Af      => STM32.Device.GPIO_AF_TIM4_2);

   --- Console for debug
   Console.init(9600);

   
   -- Comms with RF24
   RF24Dev.Init(MOSI_Pin => STM32.Device.PB15,
               MISO_Pin => STM32.Device.PB14,
               NSS_Pin  => STM32.Device.PB12,
               CLK_Pin  => STM32.Device.PB13,
               CE_Pin   => STM32.Device.PB11);

   
   -- Init comms
   RF24Dev.powerUp;
   delay 0.01;

   RF24Dev.setRxMode;
   delay 0.01;

   if RF24.InitOK then
      STM32.GPIO.Set(Green_LED);
   else
      STM32.GPIO.Set(Red_LED);
   end if;

   
   ------------------------
   --- Main Loop
   ------------------------
   Next_execution:= Ada.Real_Time.Clock + Period;
   loop
      
      -- Get all the new data from Comms      
      MainComms.updateCommands(RF24Dev);
      
      -- Update the system according to Commands.
      for cmd in MainComms.Command_type loop
         last_command := MainComms.getLastCommand(cmd);
         case last_command.Tag is
            when MainComms.TEST_LED => null;
            when MainComms.SET_DIRECTION => 
               last_command_status := Commander.CommandCarControllerDir(last_command);
            when MainComms.SET_SPEED => 
               last_command_status := Commander.CommandCarControllerSpeed(last_command);
            when MainComms.SET_SERVO => 
               last_command_status := Commander.CommandServo(Ser1 => servo1,
                                                             Ser2 => servo2,
                                                             Cmd  => last_command);
            when MainComms.SET_PUMP =>
               if MainComms.getLastCommand(MainComms.SET_PUMP).Data(0) = 0 then
                  PumpPinNot.clear;
               else
                  PumpPinNot.set;
               end if;
--              when MainComms.SET_MAIN_STATUS =>
--                 last_command_status := Commander.CommandState(Cmd   => last_command,
--                                                               State => MainState.currentState);
            when others => null;
         end case;
      end loop;
      
      if MainState.currentState = MainState.IN_RANGE then
         null;
      end if;


   end loop;
end Main;
