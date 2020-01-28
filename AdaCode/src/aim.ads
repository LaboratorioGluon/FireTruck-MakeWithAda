with Servo;

package Aim is
   
   use type servo.degree;
   type Distance is range 0 .. 200;
   
   
   Current_Distance : Distance := 0;
   Curernt_Angle : Servo.degree := 0;
   Current_Achieved: Boolean := False;
   
   type Aim_data_item is 
      record
         Dist: Distance;
         Angle : Servo.degree;
      end record;
   
   
   
   type Aim_data_table_type is array (0..2) of Aim_data_item;
   Aim_data_table : Aim_data_table_type := ( (107, -20),
                                             (95, -30),
                                             (75, -40)
                                            );
   
   
   procedure Aim( Angle: in  Servo.degree;
                  Dist: in Distance;
                  ServoH : in out Servo.Servo;
                  ServoV : in out Servo.Servo) ;
                  

   function DistanceToDegree(Dist : in Distance;
                             deg: out Servo.degree)
                             return Boolean;
   
   
end Aim;
