with Ada.Real_Time;

with STM32.GPIO; use STM32.GPIO;
with STM32.Device;
with STM32.Board; use STM32.Board;
with HAL;
with Console;
with rf24;
with STM32.SPI;
with STM32.PWM;
with STM32.Timers;

with MainComms;
with CarController;


procedure Main is
   use type Ada.Real_Time.Time;
   use type HAL.Uint8;
   Next_execution: Ada.Real_Time.Time;
   Period: constant Ada.Real_Time.Time_Span:= Ada.Real_Time.To_Time_Span(0.5);

   reg : HAL.UInt8;
   data:  HAL.UInt8_Array(0..32);
   count : Integer := 0;

   RF24Dev : RF24.RF24_Device(STM32.Device.SPI_2'Access);

   last_command : MainComms.Command;

   pwm_mod : STM32.PWM.PWM_Modulator;



begin

   STM32.Board.Initialize_LEDs;
   STM32.Board.Configure_User_Button_GPIO;

   -- PWM
   CarController.InitLeftMotor(LEFT_FWD     => STM32.Device.PE0,
                               LEFT_BCK     => STM32.Device.PE2,
                               LEFT_PWM     => STM32.Device.PB8,
                               LEFT_Timer   => STM32.Device.Timer_4'Access,
                               LEFT_Channel => STM32.Timers.Channel_3,
                               LEFT_Af      => STM32.Device.GPIO_AF_TIM4_2);

   CarController.InitRightMotor(RIGHT_FWD     => STM32.Device.PE1,
                                RIGHT_BCK     => STM32.Device.PE3,
                                RIGHT_PWM     => STM32.Device.PB9,
                                RIGHT_Timer   => STM32.Device.Timer_4'Access,
                                RIGHT_Channel => STM32.Timers.Channel_4,
                                RIGHT_Af      => STM32.Device.GPIO_AF_TIM4_2);

--     STM32.PWM.Configure_PWM_Timer(Generator => STM32.Device.Timer_4'Access,
--                                   Frequency => 50_000);
--
--
--     pwm_mod.Attach_PWM_Channel(Generator => STM32.Device.Timer_4'Access,
--                                Channel   => STM32.Timers.Channel_3,
--                                Point     => STM32.Device.PB8,
--                                PWM_AF    => STM32.Device.GPIO_AF_TIM4_2);
--
--
--     pwm_mod.Enable_Output;
   --CarController.UpdateMotors;
   -- end PWM
   Console.init(9600);

   RF24Dev.Init(MOSI_Pin => STM32.Device.PB15,
               MISO_Pin => STM32.Device.PB14,
               NSS_Pin  => STM32.Device.PB12,
               CLK_Pin  => STM32.Device.PB13,
               CE_Pin   => STM32.Device.PB11);

   if STM32.Device.SPI_2.Enabled and not STM32.Device.SPI_2.Mode_Fault_Indicated then
      Console.putLine("Bien!");
   end if;


   STM32.Device.Enable_Clock (STM32.Device.PA1);
   STM32.GPIO.Configure_IO (STM32.Device.PA1,
                            (Mode_Out,
                             Resistors   => Floating,
                             Output_Type => Push_Pull,
                             Speed       => Speed_100MHz
                            ));

   STM32.Device.Enable_Clock (STM32.Device.PD10);
   STM32.GPIO.Configure_IO (STM32.Device.PD10,
                            (Mode_In,
                             Resistors   => Floating
                            ));

   RF24Dev.powerUp;
   delay 0.01;

   RF24Dev.setRxMode;
   delay 0.01;

   if RF24.InitOK then
      STM32.GPIO.Set(Green_LED);
   else
      STM32.GPIO.Set(Red_LED);
   end if;

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

      --reg := RF24Dev.ReadWaitBlocking;
      --Console.putLine("Fin lectura!");
                      --        Console.putLine("Fin lectura... : ");
	  
      --RF24Dev.getData(data, count);
      --Console.putLine("Get Data!");
      --Console.putLine("Data: " & data(2)'Img);
      --last_command := MainComms.parseCommand(data);
      --Console.putLine("Tag: " & last_command.Tag'Img);
      --Console.putLine("Len: " & last_command.Len'Img);
      --Console.putLine("Data: " & last_command.Data(0)'Img);

      MainComms.updateCommands(RF24Dev);
      
--        case last_command.Tag is
--           when MainComms.TEST_LED =>
--              if last_command.Data(0) = 0 then
--                 STM32.GPIO.Clear(Green_LED);
--              else
--                 STM32.GPIO.Set(Green_LED);
--              end if;
--           when MainComms.SET_DIRECTION =>
--              CarController.setDirection(CarController.Direction'Val(last_command.Data(0)));
--           when MainComms.SET_SPEED =>
--              CarController.setSpeed(CarController.Speed(last_command.Data(0)));
--           when others =>
--              null;
--        end case;

      if MainComms.getLastCommand(Tag => MainComms.TEST_LED).Data(0) = 1 then
         STM32.GPIO.Set(Green_LED);
      else
         STM32.GPIO.Clear(Green_LED);
      end if;
      
      CarController.setDirection(
                                 CarController.Direction'Val(
                                   MainComms.getLastCommand(Tag => MainComms.SET_DIRECTION).Data(0))
                                );
      CarController.setSpeed(CarController.Speed(MainComms.getLastCommand(Tag => MainComms.SET_SPEED).Data(0)));
      STM32.GPIO.Set(Blue_LED);
--        Console.putLine("Count: " & count'Img);
--  --      Console.putLine("Data " & reg'Img);
--        for I in 1 .. count loop
--           Console.put(data(I)'img & '_');
--        end loop;
--        Console.put(""&ASCII.CR);

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
--        delay until Next_execution;
--        Next_execution:= Ada.Real_Time.clock + Period;
   end loop;
end Main;
