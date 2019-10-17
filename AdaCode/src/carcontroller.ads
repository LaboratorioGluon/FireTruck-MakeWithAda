with STM32.Timers;
with STM32.GPIO;
with STM32.PWM;

package CarController is
   

   
   type Direction is (NONE,
                      RIGHT,
                      LEFT,
                      FORWARD,
                      BACKWARDS);
  
   type Speed is range 0 .. 100;
   currentDirection : Direction := NONE;
   currentSpeed : Speed := 0;
   
   RIGHT_FWD_Pin : aliased STM32.GPIO.GPIO_Point;
   RIGHT_BCK_Pin : aliased STM32.GPIO.GPIO_Point;
   RIGHT_PWM_Pin : aliased STM32.GPIO.GPIO_Point;
   RIGHT_Modulator : STM32.PWM.PWM_Modulator;
   LEFT_FWD_Pin  : aliased STM32.GPIO.GPIO_Point;
   LEFT_BCK_Pin  : aliased STM32.GPIO.GPIO_Point;
   LEFT_PWM_Pin : aliased STM32.GPIO.GPIO_Point;
   LEFT_Modulator : STM32.PWM.PWM_Modulator;							 
   
   procedure InitRightMotor(RIGHT_FWD: in STM32.GPIO.GPIO_Point;
                            RIGHT_BCK: in STM32.GPIO.GPIO_Point;
                            RIGHT_PWM: in STM32.GPIO.GPIO_Point;
                            RIGHT_Timer: access STM32.Timers.Timer;
                            RIGHT_Channel: in STM32.Timers.Timer_Channel;
                            RIGHT_Af: in STM32.GPIO_Alternate_Function) ;
   
   
   procedure InitLeftMotor(LEFT_FWD: in STM32.GPIO.GPIO_Point;
                           LEFT_BCK: in STM32.GPIO.GPIO_Point;
                           LEFT_PWM: in STM32.GPIO.GPIO_Point;
                           LEFT_Timer: access STM32.Timers.Timer;
                           LEFT_Channel: in STM32.Timers.Timer_Channel;
                           LEFT_Af: in STM32.GPIO_Alternate_Function) ;
   
   procedure UpdateMotors_Old;
   
     
   procedure setDirection(DIR: in Direction);
   procedure setSpeed( SPD: in Speed);
   
end CarController;
