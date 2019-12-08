with Servo;

package Aim is

   type Distance is range 0 .. 100;
   
   procedure Aim( Angle: in  Servo.degree;
                  Distance: in Distance;
                  ServoH : int out Servo.Servo;
                  ServoV : int out Servo.Servo;
                  Acquired: out Boolean) ;
                  

end Aim;
