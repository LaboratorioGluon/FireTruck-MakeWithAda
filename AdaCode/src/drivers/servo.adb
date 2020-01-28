with HAL;
package body Servo is

   procedure Init( This: in out Servo;
                   Pin: STM32.GPIO.GPIO_Point;
                   Alternate_func: STM32.GPIO_Alternate_Function;
                   Servo_Timer: access STM32.Timers.Timer;
                   TimerChan: in STM32.Timers.Timer_Channel) is
   begin
      STM32.Device.Enable_Clock(Pin);
      
      Pin.Configure_IO((STM32.GPIO.Mode_Out,
                                Resistors   => STM32.GPIO.Floating,
                                Output_Type => STM32.GPIO.Push_Pull,
                                Speed       => STM32.GPIO.Speed_100MHz
                                ));
      
      -- Configure the PWM to 50 Hz (20ms period)
      STM32.PWM.Configure_PWM_Timer(Generator => Servo_Timer,
                                    Frequency => 50);
		

      This.modulator.Attach_PWM_Channel(Generator => Servo_Timer,
                                        Channel   => TimerChan,
                                        Point     => Pin,
                                        PWM_AF    => Alternate_func);
							 
      This.modulator.Enable_Output;
   end Init;
   
   procedure setDegrees(This : in out Servo;
                        Degrees: in degree) is
      use type HAL.UInt32;
      top: constant Integer := Integer(This.calibration_top-This.calibration_zero);
      bottom: constant Integer := Integer(This.calibration_zero-This.calibration_bot);
      value: STM32.PWM.Microseconds;
      local_degree : degree := Degrees;
   begin
      
      -- Limit to the servo bounds set by 'setLimits'
      if Degrees > This.degree_limit_top then
         local_degree := This.degree_limit_top;
      elsif Degrees < This.degree_limit_bottom then
         local_degree := This.degree_limit_bottom;
      end if;

      -- Convert the degree to a duty cycle value, using the calibration
      if local_degree >= 0 then
         value := STM32.PWM.Microseconds(top/90*Integer(local_degree)) + This.calibration_zero;
      else
         value := -STM32.PWM.Microseconds(bottom/90*Integer(-local_degree)) + This.calibration_zero;
      end if;

      -- Set the servo Duty cycle time
      This.modulator.Set_Duty_Time(Value => value);
   end setDegrees;
   
   
   procedure setValue(This: in out Servo;
                      Value: in Integer) is
   begin
      This.modulator.Set_Duty_Time(Value => STM32.PWM.Microseconds(Value));
   end setValue;
   
   procedure setCalibration(This: in out Servo;
                            Zero: in STM32.PWM.Microseconds;
                            Top : in STM32.PWM.Microseconds;
                            Bottom: in STM32.PWM.Microseconds) is
   begin
      This.calibration_zero := Zero;
      This.calibration_top := Top;
      This.calibration_bot := Bottom;
   end setCalibration;
   
   procedure setLimits(This: in out Servo;
                       Max_Degree : in Degree;
                       Min_Degree : in Degree) is
   begin
      This.degree_limit_top := Max_Degree;
      This.degree_limit_bottom := Min_Degree;
   end setLimits;

end Servo;
