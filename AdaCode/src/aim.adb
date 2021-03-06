with STM32.Board;

package body Aim is


   procedure Aim( Angle: in  Servo.degree;
                  Dist: in Distance;
                  ServoH : in out Servo.Servo;
                  ServoV : in out Servo.Servo) is
      
      VertAngle: Servo.degree;
      Achieved : Boolean := False;
   begin

      -- Debug purposes
      STM32.Board.Blue_LED.Toggle;
      
      -- Calculate the vertical servo and check that 
      -- the target is in range
      Current_Achieved := DistanceToDegree(Dist => Dist,
                       deg  => VertAngle);
      
      -- If target is in range, then set the values of the servos
      if Current_Achieved then
         ServoH.setDegrees(Angle);
         ServoV.setDegrees(VertAngle);
      else
      -- Else set 0 degrees for both
         ServoH.setDegrees(0);
         ServoV.setDegrees(0);
      end if;
            
   end Aim;
   
   function DistanceToDegree(Dist : in Distance;
                             deg: out Servo.degree)
                             return Boolean is

      dDist: Float;
      dAngl: Float;
      TempF: Float;
      achieved : Boolean := False;
      
      -- Function to interpolate between two values
      function Interp(X0, Y0, X1, Y1, Xin: in Float) return Float is
         dX : constant Float := X1-X0;
         dY : constant Float := Y1-Y0;
         div : constant Float := dY/dX;
         res : constant Float := Y0 + (Xin - X0)*div;
      begin
         return res;
      end Interp;
                       
      
   begin
      
      -- Check that the target is not too far away
      if Dist > Aim_data_table(0).Dist then
         deg := 0;
         return False;
      end if;
      
      -- Check if the target is between the first 2 data
      if Dist > Aim_data_table(1).Dist and
        Dist < Aim_data_table(0).Dist then
         deg := Servo.degree(Interp(X0 => Float(Aim_data_table(1).Dist),
                       Y0 => Float(Aim_data_table(1).Angle),
                       X1 => Float(Aim_data_table(0).Dist),
                       Y1 => Float(Aim_data_table(0).Angle),
                       Xin =>Float(Dist)));
         return True;
      end if;

      -- Check if the target is between the next 2 data.
      if Dist > Aim_data_table(2).Dist and
        Dist < Aim_data_table(1).Dist then
         deg :=  Servo.degree(Interp(X0 => Float(Aim_data_table(2).Dist),
                       Y0 => Float(Aim_data_table(2).Angle),
                       X1 => Float(Aim_data_table(1).Dist),
                       Y1 => Float(Aim_data_table(1).Angle),
                       Xin =>Float(Dist)));
         return True;
      end if;
         
      deg := 0;
      return False;
end DistanceToDegree;

end Aim;
