with Ada.Real_Time;

with STM32.GPIO; use STM32.GPIO;
with STM32.Device;
with STM32.Board; use STM32.Board;

with Console;

procedure Main is
   use type Ada.Real_Time.Time;

   Next_execution: Ada.Real_Time.Time;
   Period: constant Ada.Real_Time.Time_Span:= Ada.Real_Time.To_Time_Span(0.1); -- 100ms
begin
   Console.init(115200);
   STM32.Board.Initialize_LEDs;
   STM32.Board.Configure_User_Button_GPIO;

   STM32.Device.Enable_Clock (STM32.Device.PA1);
   STM32.GPIO.Configure_IO (STM32.Device.PA1,
                            (Mode_Out,
                             Resistors   => Floating,
                             Output_Type => Push_Pull,
                             Speed       => Speed_100MHz
                            ));

   Next_execution:= Ada.Real_Time.Clock + Period;
   loop
      if STM32.Device.PA0.Set then
         STM32.GPIO.Set(Green_LED);
         STM32.GPIO.Clear(STM32.Device.PA1);
      else
         STM32.GPIO.Set(STM32.Device.PA1);
         STM32.GPIO.Clear (Green_LED);
      end if;
      --cONSOLE.putLine("Test!");
      delay until Next_execution;
      Next_execution:= Ada.Real_Time.clock + Period;
   end loop;
end Main;
