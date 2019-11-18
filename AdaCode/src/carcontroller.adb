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
         RIGHT_Modulator.Set_Duty_Cycle(Integer(currentSpeed)); -- 0
      when others =>
         LEFT_FWD_Pin.Clear;
         LEFT_BCK_Pin.Clear;
         RIGHT_FWD_Pin.Clear;
         RIGHT_BCK_Pin.Clear;
         LEFT_Modulator.Set_Duty_Cycle(0);
         RIGHT_Modulator.Set_Duty_Cycle(0);
      end case;

   end setDirection;
   
   
   procedure setSpeed( SPD: in Speed) is

   begin
	
      currentSpeed := SPD;

   end setSpeed;
   
end CarController;
