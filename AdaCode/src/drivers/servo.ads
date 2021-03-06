with STM32.Timers;
with STM32.GPIO;
with STM32.PWM;
with STM32.Device;

package Servo is
   
   type degree is range -90 .. 90;
   for degree'Size use 8;

   type Servo is 
     tagged limited record
      modulator:  STM32.PWM.PWM_Modulator;
      calibration_zero: STM32.PWM.Microseconds := 1500; -- Default and standard values
      calibration_top: STM32.PWM.Microseconds  := 2000; -- Calibration for -90 degrees
      calibration_bot: STM32.PWM.Microseconds  := 1000; -- Calibration for  90 degrees 
      degree_limit_top: degree := 90;                   -- The servo will not move more than this
      degree_limit_bottom: degree := -90;               -- The servo will not move less than this
   end record;

   
   ----------------------------------------------------------
   -- Initialize the modules for the Servo communication
   -- Mainly PWM and Timers.
   ----------------------------------------------------------
   procedure Init( This: in out Servo;
                   Pin: STM32.GPIO.GPIO_Point;
                   Alternate_func: STM32.GPIO_Alternate_Function;
                   Servo_Timer: access STM32.Timers.Timer;
                   TimerChan: in STM32.Timers.Timer_Channel);
   

   ----------------------------------------------------------
   -- If the Servo is calibrated, this function calculates
   -- the value of the PWM signal to get the Degrees.
   -- It takes into account the limits and the calibration
   -----------------------------------------------------------
   procedure setDegrees(This : in out Servo;
                        Degrees: in degree);
   
   ----------------------------------------------------------
   -- This procedure set the value in us of the width
   -- of the PWM, directly  
   ---------------------------------------------------------- 
   procedure setValue(This: in out Servo;
                      Value: in Integer);
   
   ----------------------------------------------------------
   -- This procedure is used to calibrate the servos when they
   -- do not work with the standard:
   -- - 1000us => -90 degrees
   -- - 1500us => 0 degrees
   -- - 2000us => 90 degrees
   ---------------------------------------------------------- 
   procedure setCalibration(This: in out Servo;
                            Zero: in STM32.PWM.Microseconds;
                            Top : in STM32.PWM.Microseconds;
                            Bottom: in STM32.PWM.Microseconds);
   
   ----------------------------------------------------------
   -- Set the limits of the servo movement so if the value
   -- of the servo in degrees is out of this range, the servo
   -- will move to the limit.
   ---------------------------------------------------------- 
   procedure setLimits(This: in out Servo;
                       Max_Degree : in Degree;
                       Min_Degree : in Degree);
end Servo;
