with STM32.Device;

package body CarController is

--     
--     procedure Init(RIGHT_FWD: STM32.GPIO.GPIO_Point;
--                    RIGHT_BCK: STM32.GPIO.GPIO_Point;
--                    LEFT_FWD : STM32.GPIO.GPIO_Point;
--                    LEFT_BCK : STM32.GPIO.GPIO_Point;
--  				  ) is
--     begin
--        RIGHT_FWD_Pin := RIGHT_FWD;
--        RIGHT_BCK_Pin := RIGHT_BCK;
--        LEFT_FWD_Pin  := LEFT_FWD;
--        LEFT_BCK_Pin  := LEFT_BCK;
--     end Init;
--     
   procedure InitRightMotor(RIGHT_FWD: in STM32.GPIO.GPIO_Point;
                            RIGHT_BCK: in STM32.GPIO.GPIO_Point;
                            RIGHT_PWM: in STM32.GPIO.GPIO_Point;
                            RIGHT_Timer: access STM32.Timers.Timer;
                            RIGHT_Channel: in STM32.Timers.Timer_Channel;
                            RIGHT_Af: in STM32.GPIO_Alternate_Function)  is
							 
							 
   begin
      RIGHT_FWD_Pin := RIGHT_FWD;
      RIGHT_BCK_Pin := RIGHT_BCK;
      RIGHT_PWM_Pin := RIGHT_PWM;
		
      STM32.Device.Enable_Clock(RIGHT_FWD_Pin);
      STM32.Device.Enable_Clock(RIGHT_BCK_Pin);
      
      RIGHT_FWD_Pin.Configure_IO((STM32.GPIO.Mode_Out,
                                Resistors   => STM32.GPIO.Floating,
                                Output_Type => STM32.GPIO.Push_Pull,
                                Speed       => STM32.GPIO.Speed_100MHz
                                ));
      
      RIGHT_BCK_Pin.Configure_IO((STM32.GPIO.Mode_Out,
                                Resistors   => STM32.GPIO.Floating,
                                Output_Type => STM32.GPIO.Push_Pull,
                                Speed       => STM32.GPIO.Speed_100MHz
                                ));
      
      STM32.PWM.Configure_PWM_Timer(Generator => RIGHT_Timer,
                                    Frequency => 50_000);
		
      RIGHT_Modulator.Attach_PWM_Channel(Generator => RIGHT_Timer,
                                        Channel   => RIGHT_Channel,
                                        Point     => RIGHT_PWM_Pin,
                                        PWM_AF    => RIGHT_Af);
							 
      RIGHT_Modulator.Enable_Output;
      RIGHT_FWD_Pin.set;
      RIGHT_BCK_Pin.Clear;
   end InitRightMotor;
   
   
   procedure InitLeftMotor(LEFT_FWD: in STM32.GPIO.GPIO_Point;
                           LEFT_BCK: in STM32.GPIO.GPIO_Point;
                           LEFT_PWM: in STM32.GPIO.GPIO_Point;
                           LEFT_Timer: access STM32.Timers.Timer;
                           LEFT_Channel: in STM32.Timers.Timer_Channel;
                           LEFT_Af: in STM32.GPIO_Alternate_Function) is
							 
							 
   begin
      LEFT_FWD_Pin := LEFT_FWD;
      LEFT_BCK_Pin := LEFT_BCK;
      LEFT_PWM_Pin := LEFT_PWM;
		
      STM32.Device.Enable_Clock(LEFT_FWD_Pin);
      STM32.Device.Enable_Clock(LEFT_BCK_Pin);
      --STM32.Device.Enable_Clock(LEFT_PWM_Pin);
      
      LEFT_FWD_Pin.Configure_IO((STM32.GPIO.Mode_Out,
                                Resistors   => STM32.GPIO.Floating,
                                Output_Type => STM32.GPIO.Push_Pull,
                                Speed       => STM32.GPIO.Speed_100MHz
                               ));
      LEFT_BCK_Pin.Configure_IO((STM32.GPIO.Mode_Out,
                                Resistors   => STM32.GPIO.Floating,
                                Output_Type => STM32.GPIO.Push_Pull,
                                Speed       => STM32.GPIO.Speed_100MHz
                               ));
      --Configure_IO (User_Button_Point, (Mode_In, Resistors => Floating));
      
      
      STM32.PWM.Configure_PWM_Timer(Generator => LEFT_Timer,
                                    Frequency => 50_000);
		
      LEFT_Modulator.Attach_PWM_Channel(Generator => LEFT_Timer,
                                        Channel   => LEFT_Channel,
                                        Point     => LEFT_PWM_Pin,
                                        PWM_AF    => LEFT_Af);
							 
      LEFT_Modulator.Enable_Output;
      LEFT_FWD_Pin.set;
      LEFT_BCK_Pin.Clear;
      STM32.GPIO.Set(LEFT_FWD_Pin);
   end InitLeftMotor;
   
   procedure UpdateMotors is
      
      function Sine (Input : Long_Float) return Long_Float is
         Pi : constant Long_Float := 3.14159_26535_89793_23846;
         X  : constant Long_Float := Long_Float'Remainder (Input, Pi * 2.0);
         B  : constant Long_Float := 4.0 / Pi;
         C  : constant Long_Float := (-4.0) / (Pi * Pi);
         Y  : constant Long_Float := B * X + C * X * abs (X);
         P  : constant Long_Float := 0.225;
      begin
         return P * (Y * abs (Y) - Y) + Y;
      end Sine;
      
   begin
      
      declare
         Arg       : Long_Float := 0.0;
         Value     : Integer;
         Increment : constant Long_Float := 0.00003;
         --  The Increment value controls the rate at which the brightness
         --  increases and decreases. The value is more or less arbitrary, but
         --  note that the effect of compiler optimization is observable.
      begin
         loop
            Value := Integer (50.0 * (1.0 + Sine (Arg)));
            LEFT_Modulator.Set_Duty_Cycle (Value);
            RIGHT_Modulator.Set_Duty_Cycle (Value);
            Arg := Arg + Increment;
         end loop;
      end;
      
   end UpdateMotors;

end CarController;
