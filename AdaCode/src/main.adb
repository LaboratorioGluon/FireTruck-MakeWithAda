with Ada.Real_Time;

with STM32.GPIO; use STM32.GPIO;
with STM32.Device;
with STM32.Board; use STM32.Board;
with HAL;
with Console;
with rf24;
with STM32.SPI;
with STM32.Timers;

with MainComms;
with CarController;
with Servo;
with Unchecked_Conversion;
with Commander;

procedure Main is
   use type Ada.Real_Time.Time;
   use type HAL.Uint8;
   use type Servo.degree;
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
   
   
   servo1.Init(Pin            => STM32.Device.PB5,
               Alternate_func => STM32.Device.GPIO_AF_TIM3_2,
               Servo_Timer    => STM32.Device.Timer_3'access,
               TimerChan      => STM32.Timers.Channel_2);
   
   servo1.setCalibration(Zero   => 1500,
                         Top    => 2500,
                         Bottom => 600);
   
   servo1.setLimits(Max_Degree => 45,
                    Min_Degree => -30);
   
   servo2.Init(Pin            => STM32.Device.PB4,
               Alternate_func => STM32.Device.GPIO_AF_TIM3_2,
               Servo_Timer    => STM32.Device.Timer_3'access,
               TimerChan      => STM32.Timers.Channel_1);
   
   servo2.setCalibration(Zero   => 1600,
                         Top    => 2600,
                         Bottom => 600);
   
   servo2.setLimits(Max_Degree => 15,
                    Min_Degree => -30);
   

--     declare
--        Arg       : Long_Float := 0.0;
--        Value     : Integer;
--        Increment : constant Long_Float := 0.1;
--        Step : Integer := 400;
--        Last_Step : Integer := -180;
--        --  The Increment value controls the rate at which the brightness
--        --  increases and decreases. The value is more or less arbitrary, but
--        --  note that the effect of compiler optimization is observable.
--     begin
--        loop
--  --           if STM32.Device.PA0.Set then
--  --              --Value := Integer (180.0*Sine (Arg));
--  --              Value := -180;
--  --           else
--  --              Value := 180;
--  --           end if;
--  
--           if STM32.Device.PA0.Set and Last_Step = Step then
--              if Step /= 0 then
--                 Step := 0;
--              else
--                 Step := 1;
--              end if;
--              STM32.GPIO.Set(Green_LED);
--           end if;
--           
--           if not STM32.Device.PA0.Set and Last_Step /= Step then
--              Last_Step := Step;
--              STM32.GPIO.Clear(Green_LED);
--           end if;
--           
--           if Step > 2700 then
--              Step := 400;
--           end if;
--           Value := Integer (90.0*Sine (Arg));
--           if Step = 0 then
--              servo1.setValue(Integer(servo1.calibration_zero));
--           else
--              servo1.setDegrees(Servo.degree(Value));
--           end if;
--           
--           Value := Integer (90.0*Sine (Arg*2.0));
--           if Step = 0 then
--              servo2.setValue(Integer(servo2.calibration_zero));
--           else
--              servo2.setDegrees(Servo.degree(Value));
--           end if;
--           --servo1.setValue(400);
--           Arg := Arg + Increment;
--           
--           delay 0.1;
--        end loop;
--     end;
--        

   
   -- PWM
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

--     STM32.PWM.Configure_PWM_Timer(Generator => STM32.Device.Timer_4'Access,
--                                   Frequency => 50_000);
--
--
--     pwm_mod.Attach_PWM_Channel(Generator => STM32.Device.Timer_4'Access,
--                                Channel   => STM32.Timers.Channel_3,
--                                Point     => STM32.Device.PB8,
--                                PWM_AF    => STM32.Device.GPIO_AF_TIM4_2);
--
--
--     pwm_mod.Enable_Output;
   --CarController.UpdateMotors;
   -- end PWM
   Console.init(9600);

   RF24Dev.Init(MOSI_Pin => STM32.Device.PB15,
               MISO_Pin => STM32.Device.PB14,
               NSS_Pin  => STM32.Device.PB12,
               CLK_Pin  => STM32.Device.PB13,
               CE_Pin   => STM32.Device.PB11);

   if STM32.Device.SPI_2.Enabled and not STM32.Device.SPI_2.Mode_Fault_Indicated then
      Console.putLine("Bien!");
   end if;


  

   STM32.Device.Enable_Clock (STM32.Device.PD10);
   STM32.GPIO.Configure_IO (STM32.Device.PD10,
                            (Mode_In,
                             Resistors   => Floating
                            ));

   RF24Dev.powerUp;
   delay 0.01;

   RF24Dev.setRxMode;
   delay 0.01;

   if RF24.InitOK then
      STM32.GPIO.Set(Green_LED);
   else
      STM32.GPIO.Set(Red_LED);
   end if;

   Next_execution:= Ada.Real_Time.Clock + Period;
   loop

--        if STM32.Device.PA0.Set then
--           STM32.GPIO.Set(Orange_LED);
--           STM32.GPIO.Clear(PumpPin);
--           STM32.GPIO.Set(PumpPinNot);
--        else
--           STM32.GPIO.Set(PumpPin);
--           STM32.GPIO.Clear(PumpPinNot);
--           STM32.GPIO.Clear (Orange_LED);
--        end if;

      MainComms.updateCommands(RF24Dev);

--        if MainComms.getLastCommand(Tag => MainComms.TEST_LED).Data(0) = 1 then
--           STM32.GPIO.Set(Green_LED);
--        else
--           STM32.GPIO.Clear(Green_LED);
--        end if;
--        
--        CarController.setDirection(
--                                   CarController.Direction'Val(
--                                     MainComms.getLastCommand(Tag => MainComms.SET_DIRECTION).Data(0))
--                                  );
--        CarController.setSpeed(CarController.Speed(MainComms.getLastCommand(Tag => MainComms.SET_SPEED).Data(0)));
      
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
            when others => null;
         end case;
      end loop;
--        
--        servo1.setDegrees(toDeg(MainComms.getLastCommand(Tag =>  MainComms.SET_SERVO).Data(0)));
--        servo2.setDegrees(toDeg(MainComms.getLastCommand(Tag =>  MainComms.SET_SERVO).Data(1)));
--        STM32.GPIO.Set(Blue_LED);

   end loop;
end Main;
