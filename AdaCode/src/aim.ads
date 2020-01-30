with Servo;

package Aim is
   
   use type servo.degree;
   type Distance is range 0 .. 200;
   
   -- Current aiming information
   Current_Distance : Distance := 0;
   Curernt_Angle : Servo.degree := 0;
   Current_Achieved: Boolean := False;
   
   type Aim_data_item is 
      record
         Dist: Distance;
         Angle : Servo.degree;
      end record;
   
   
   -- This is the experimental data
   type Aim_data_table_type is array (0..2) of Aim_data_item;
   Aim_data_table : Aim_data_table_type := ( (107, -20),
                                             (95, -30),
                                             (75, -40)
                                            );
   
   
  -------------------------------------------------------------------
   --
   -- Aim: Set the servo position to aim the tower to the target 
   --      based in the distance and yaw from the truck front
   -- 
   -- params:
   --    - Angle: Horizontal angle to the target
   --    - Dist : Distance to the objective
   --    - ServoH/V : Servo of the Horizontal and Vertical aiming
   --    -            so the function can set their value.
   -------------------------------------------------------------------
   procedure Aim( Angle: in  Servo.degree;
                  Dist: in Distance;
                  ServoH : in out Servo.Servo;
                  ServoV : in out Servo.Servo) ;
                  

   -------------------------------------------------------------------
   --
   -- DistanceToDegree: Use the table Aim_data_table to calculate the 
   --        vertical servo to aim to given distance
   -- 
   -- params:
   --    - Dist: Distance to the target
   --    - deg : Degrees calculated
   --
   -- return:
   --    - true if the calculation could be made, so the target is in range
   -------------------------------------------------------------------
   function DistanceToDegree(Dist : in Distance;
                             deg: out Servo.degree)
                             return Boolean;
   
   
end Aim;
