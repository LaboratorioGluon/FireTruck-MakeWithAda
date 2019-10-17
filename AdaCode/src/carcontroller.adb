with STM32.Device;

package body CarController is


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
                                    Frequency => 50);
		
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
      
      STM32.PWM.Configure_PWM_Timer(Generator => LEFT_Timer,
                                    Frequency => 50);
		
      LEFT_Modulator.Attach_PWM_Channel(Generator => LEFT_Timer,
                                        Channel   => LEFT_Channel,
                                        Point     => LEFT_PWM_Pin,
                                        PWM_AF    => LEFT_Af);
							 
      LEFT_Modulator.Enable_Output;
      LEFT_FWD_Pin.set;
      LEFT_BCK_Pin.Clear;
      STM32.GPIO.Set(LEFT_FWD_Pin);
   end InitLeftMotor;
   
   procedure UpdateMotors_Old is
      
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
      
   end UpdateMotors_Old;

   procedure setDirection(DIR: in Direction) is
   begin
      currentDirection := DIR;
      case DIR is
      when NONE => 
         LEFT_FWD_Pin.Clear;
         LEFT_BCK_Pin.Clear;
         RIGHT_FWD_Pin.Clear;
         RIGHT_BCK_Pin.Clear;
         LEFT_Modulator.Set_Duty_Cycle(0);
         RIGHT_Modulator.Set_Duty_Cycle(0);
      when FORWARD => 
         LEFT_FWD_Pin.Set;
         LEFT_BCK_Pin.Clear;
         RIGHT_FWD_Pin.Set;
         RIGHT_BCK_Pin.Clear;
         LEFT_Modulator.Set_Duty_Cycle(Integer(currentSpeed));
         RIGHT_Modulator.Set_Duty_Cycle(Integer(currentSpeed));
      when BACKWARDS => 
         LEFT_FWD_Pin.Clear;
         LEFT_BCK_Pin.Set;
         RIGHT_FWD_Pin.Clear;
         RIGHT_BCK_Pin.Set;
         LEFT_Modulator.Set_Duty_Cycle(Integer(currentSpeed));
         RIGHT_Modulator.Set_Duty_Cycle(Integer(currentSpeed));	
      when LEFT =>
         LEFT_FWD_Pin.Clear;
         LEFT_BCK_Pin.Set;
         RIGHT_FWD_Pin.Set; -- Set
         RIGHT_BCK_Pin.Clear;
         LEFT_Modulator.Set_Duty_Cycle(Integer(currentSpeed)); -- 0
         RIGHT_Modulator.Set_Duty_Cycle(Integer(currentSpeed));
      when RIGHT =>
         LEFT_FWD_Pin.Set; -- Set
         LEFT_BCK_Pin.Clear;
         RIGHT_FWD_Pin.Clear;
         RIGHT_BCK_Pin.Set;
         LEFT_Modulator.Set_Duty_Cycle(Integer(currentSpeed));
         RIGHT_Modulator.Set_Duty_Cycle(Integer(Integer(currentSpeed))); -- 0
      end case;

   end setDirection;
   
   
   procedure setSpeed( SPD: in Speed) is

   begin
	
      currentSpeed := SPD;

   end setSpeed;
   
end CarController;
