with Ada.Real_Time;

with STM32.GPIO; use STM32.GPIO;
with STM32.Device;
with STM32.Board; use STM32.Board;
with HAL;
with Console;
with rf24;
with STM32.SPI;


procedure Main is
   use type Ada.Real_Time.Time;

   Next_execution: Ada.Real_Time.Time;
   Period: constant Ada.Real_Time.Time_Span:= Ada.Real_Time.To_Time_Span(2.0); -- 100ms

   reg : HAL.UInt8;
   data:  STM32.SPI.UInt8_Buffer(1..10);
   count : Integer := 0;

   RF24Dev : RF24.RF24_Device(STM32.Device.SPI_2'Access);

begin


   Console.init(9600);
--     RF24.Init(SPI_port => STM32.Device.SPI_2'Access,
--               MOSI_Pin => STM32.Device.PB15,
--               MISO_Pin => STM32.Device.PB14,
--               NSS_Pin  => STM32.Device.PB12,
--               CLK_Pin  => STM32.Device.PB13,
--               CE_Pin   => STM32.Device.PB11);


   RF24Dev.Init(MOSI_Pin => STM32.Device.PB15,
               MISO_Pin => STM32.Device.PB14,
               NSS_Pin  => STM32.Device.PB12,
               CLK_Pin  => STM32.Device.PB13,
               CE_Pin   => STM32.Device.PB11);

   if STM32.Device.SPI_2.Enabled and not STM32.Device.SPI_2.Mode_Fault_Indicated then
      Console.putLine("Bien!");
   end if;

   STM32.Board.Initialize_LEDs;
   STM32.Board.Configure_User_Button_GPIO;

   STM32.Device.Enable_Clock (STM32.Device.PA1);
   STM32.GPIO.Configure_IO (STM32.Device.PA1,
                            (Mode_Out,
                             Resistors   => Floating,
                             Output_Type => Push_Pull,
                             Speed       => Speed_100MHz
                            ));

   RF24Dev.powerUp;
   delay 0.01;


--
--     STM32.Device.PB12.Clear;
--     STM32_SVD.SPI.SPI2_Periph.DR.DR := HAL.Uint16(11);
--     while not STM32_SVD.SPI.SPI2_Periph.SR.TXE loop
--           null;
--     end loop;
--     STM32_SVD.SPI.SPI2_Periph.DR.DR := HAL.Uint16(16#FF#);
--     while not STM32_SVD.SPI.SPI2_Periph.SR.TXE loop
--        null;
--     end loop;
--     while not STM32_SVD.SPI.SPI2_Periph.SR.RXNE loop
--        null;
--     end loop;
--
--     reg := HAL.UInt8 (STM32_SVD.SPI.SPI2_Periph.DR.DR);
--     Console.putLine("Dato crudo 1... : " & reg'Img);
--     while not STM32_SVD.SPI.SPI2_Periph.SR.RXNE loop
--        null;
--     end loop;
--
--     reg := HAL.UInt8 (STM32_SVD.SPI.SPI2_Periph.DR.DR);
--     Console.putLine("Dato crudo 2... : " & reg'Img);
--     STM32.Device.PB12.Set;
--     --STM32.Device.SPI_2.Periph;
--    --


   RF24Dev.setRxMode;
   delay 0.01;

   Next_execution:= Ada.Real_Time.Clock + Period;
   loop
--        if STM32.Device.PA0.Set then
--           STM32.GPIO.Set(Green_LED);
--           STM32.GPIO.Clear(STM32.Device.PA1);
--        else
--           STM32.GPIO.Set(STM32.Device.PA1);
--           STM32.GPIO.Clear (Green_LED);
--        end if;
      --Console.putLine("Esperando..");

--        Console.put("Data: ");
--        Console.putLine(ret'img);

      reg := RF24Dev.ReadWaitBlocking;

--        Console.putLine("Fin lectura... : ");
--        RF24Dev.getData(data, count);

--        Console.putLine("Count: " & count'Img);
--  --      Console.putLine("Data " & reg'Img);
--        for I in 1 .. count loop
--           Console.put(data(I)'img & '_');
--        end loop;
--        Console.put(""&ASCII.CR);
      STM32.GPIO.Set(Green_LED);
--        if RF24Dev.newDataAvailable then
--
--           STM32.GPIO.Toggle(Green_LED);
--           RF24Dev.getData(data, count);
--           Console.put("Data: ");
--           for I in 1 .. count loop
--              Console.put(data(I)'img & '_');
--           end loop;
--        end if;



      --cONSOLE.putLine("Test!");
      delay until Next_execution;
      Next_execution:= Ada.Real_Time.clock + Period;
   end loop;
end Main;
