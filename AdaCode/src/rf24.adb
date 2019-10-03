
with HAL.SPI;
with STM32.Device;

with Console;

package body RF24 is

   procedure Init(This: RF24_Device;
                  MOSI_Pin: in STM32.GPIO.GPIO_Point;
                  MISO_Pin: in STM32.GPIO.GPIO_Point;
                  NSS_Pin: in out STM32.GPIO.GPIO_Point;
                  CLK_Pin: in STM32.GPIO.GPIO_Point;
                  CE_Pin: in out STM32.GPIO.GPIO_Point) is
      
      Config_AF : STM32.GPIO.GPIO_Port_Configuration (Mode => STM32.GPIO.Mode_AF);
      Config_GPIO: STM32.GPIO.GPIO_Port_Configuration( Mode=> STM32.GPIO.Mode_Out);
      
   begin
      MOSI := MOSI_Pin;
      MISO := MISO_Pin;
      NSS := NSS_Pin;
      CLK := CLK_Pin;
      CE := CE_Pin;
      
      STM32.Device.Enable_Clock(MOSI);
      STM32.Device.Enable_Clock(MISO);
      STM32.Device.Enable_Clock(NSS);
      STM32.Device.Enable_Clock(CLK);
      STM32.Device.Enable_Clock(CE);
      
      Config_AF := (Mode => STM32.GPIO.Mode_AF,
                 Resistors =>  STM32.GPIO.Floating,
                 AF_Output_Type => STM32.GPIO.Push_Pull,
                 AF_Speed  => STM32.GPIO.Speed_25MHz,
                 AF => STM32.Device.GPIO_AF_SPI2_5
                   );
      
      MOSI.Configure_IO(Config_AF);
      MISO.Configure_IO(Config_AF);
      CLK.Configure_IO(Config_AF);
      
      -- Configure the CE pin      
      Config_GPIO := (Mode => STM32.GPIO.Mode_Out,
                 Resistors => STM32.GPIO.Pull_Up,
                 Output_Type => STM32.GPIO.Push_Pull,
                 Speed => STM32.GPIO.Speed_50MHz
                );
                 
      CE.Configure_IO(Config_GPIO);
      NSS.Configure_IO(Config_GPIO);
      
      CE.Clear;
      NSS.Set;
      
      -- Configure the SPI
      Configure(This.SPI_Port.all);
      
        
   end Init;
   
   procedure Init(SPI_port:  access STM32.SPI.SPI_Port;
                  MOSI_Pin: in STM32.GPIO.GPIO_Point;
                  MISO_Pin: in STM32.GPIO.GPIO_Point;
                  NSS_Pin: in out STM32.GPIO.GPIO_Point;
                  CLK_Pin: in STM32.GPIO.GPIO_Point;
                  CE_Pin: in out STM32.GPIO.GPIO_Point) is
      
      Config : STM32.GPIO.GPIO_Port_Configuration (Mode => STM32.GPIO.Mode_AF);
      Config_CE: STM32.GPIO.GPIO_Port_Configuration( Mode=> STM32.GPIO.Mode_Out);
   begin
      
      MOSI := MOSI_Pin;
      SPI := SPI_port;
      
      STM32.Device.Enable_Clock(MOSI_Pin);
      STM32.Device.Enable_Clock(MISO_Pin);
      STM32.Device.Enable_Clock(NSS_Pin);
      STM32.Device.Enable_Clock(CLK_Pin);
      STM32.Device.Enable_Clock(CE_Pin);
      
      -- Configure the SPI related GPIOs
      Config := (Mode => STM32.GPIO.Mode_AF,
                 Resistors =>  STM32.GPIO.Floating,
                 AF_Output_Type => STM32.GPIO.Push_Pull,
                 AF_Speed  => STM32.GPIO.Speed_100MHz,
                 AF => STM32.Device.GPIO_AF_SPI2_5
                );
      
      
      MOSI_Pin.Configure_IO(Config);
      MISO_Pin.Configure_IO(Config);
      CLK_Pin.Configure_IO(Config);
      
      -- Configure the CE pin      
      Config_CE := (Mode => STM32.GPIO.Mode_Out,
                 Resistors => STM32.GPIO.Pull_Up,
                 Output_Type => STM32.GPIO.Push_Pull,
                 Speed => STM32.GPIO.Speed_50MHz
                );
                 
      CE_Pin.Configure_IO(Config_CE);
      NSS_Pin.Configure_IO(Config_CE);
      
      CE_Pin.Clear;
      NSS_Pin.Set;
      -- Configure the SPI
      Configure(SPI.all);
      
   end Init;
   
   
   procedure Configure(SPI_port: in out STM32.SPI.SPI_Port) is
      Config : STM32.SPI.SPI_Configuration;
   begin
      STM32.Device.Enable_Clock(SPI_Port);
      SPI_port.Disable;
      Config.Direction := STM32.SPI.D2Lines_FullDuplex;
      Config.Mode := STM32.SPI.Master;
      Config.Data_Size := HAL.SPI.Data_Size_8b;
      Config.Clock_Polarity := STM32.SPI.Low;
      Config.Clock_Phase := STM32.SPI.P1Edge;
      Config.Slave_Management := STM32.SPI.Software_Managed;
      Config.Baud_Rate_Prescaler := STM32.SPI.BRP_64;
      Config.First_Bit := STM32.SPI.MSB;
      Config.CRC_Poly := 7; 
      SPI_port.Configure(Conf => Config);
      SPI_port.Enable;
   end Configure;

   procedure powerUp(This: in out RF24_Device) is
      data : HAL.SPI.SPI_Data_8b(0..1) := ( 0 => 32, 1 => 2);
      status: HAL.SPI.SPI_Status;
      ret: HAL.UInt8;
      
      status_reg: Status_Register;
      config_reg: Config_Register;
      
      read_cmd: Read_Command := (Fixed => 0, Register => 0);
      
   begin
      STM32.Device.PB12.Clear;
      Console.putLine("Pre transmit!");
      STM32.Device.SPI_2.Transmit(data, status);
      Console.putLine("Post transmit!");
      STM32.Device.PB12.Set;
   end powerUp;
   
   procedure setRxMode(This: in out RF24_Device) is
      data : HAL.SPI.SPI_Data_8b(0..1) := ( 0 => 32, 1 => 2);
     
--        pipe_set_data : HAL.SPI.SPI_Data_8b(0..5) := 
--          ( 16#2C#, 16#DE#, 16#AD#, 16#BE#, 16#EF#, 16#00#);
      pipe_set_data       : constant  HAL.SPI.SPI_Data_8b(0..5) :=
        ( 16#2B#, 16#00#, 16#EF#, 16#BE#, 16#AD#, 16#DE#);
      pipe_payload_size   : constant HAL.SPI.SPI_Data_8b(0..1) := (16#32#, 32);
      
      channel_data : HAL.SPI.SPI_Data_8b(0..1) := (16#25#,76);
      
      rx_setup_data: HAL.SPI.SPI_Data_8b(0..1) := (16#26#,2#00100110#);
      status: HAL.SPI.SPI_Status;
      config_reg: Config_Register;
      
      ret : HAL.UInt8;
   begin
      
      STM32.Device.PB12.Clear;
      STM32.Device.SPI_2.Transmit(rx_setup_data, status);
      STM32.Device.PB12.Set;
      
      delay 0.1;
      
      STM32.Device.PB12.Clear;
      STM32.Device.SPI_2.Transmit(pipe_set_data, status);
      STM32.Device.PB12.Set;
      delay 0.1;      
      
      STM32.Device.PB12.Clear;
      STM32.Device.SPI_2.Transmit(pipe_payload_size, status);
      STM32.Device.PB12.Set;
      delay 0.1;
      STM32.Device.PB12.Clear;
      STM32.Device.SPI_2.Transmit(channel_data, status);
      STM32.Device.PB12.Set;
      delay 0.1;
      STM32.Device.PB12.Clear;
      Console.putLine("Setting RX mode!");
      config_reg.PWR_UP := True;
      config_reg.PRIM_RX := True;
      data(1) := FROM_Register(config_reg);
      STM32.Device.SPI_2.Transmit(data, status);
      STM32.Device.PB12.Set;
      
      delay 0.1;
      
      
      
      

--        STM32.Device.PB12.Clear;
--        STM32.Device.SPI_2.Transmit(HAL.Uint8(11));
--        STM32.Device.SPI_2.Receive(ret);
--        Console.putLine("ret: " & ret'Img);
--        STM32.Device.SPI_2.Receive(ret);
--        Console.putLine("ret: " & ret'Img);
--        STM32.Device.SPI_2.Receive(ret);
--        Console.putLine("ret: " & ret'Img);
--        STM32.Device.SPI_2.Receive(ret);
--        Console.putLine("ret: " & ret'Img);
--        STM32.Device.SPI_2.Receive(ret);
--        Console.putLine("ret: " & ret'Img);
--        STM32.Device.SPI_2.Receive(ret);
--        Console.putLine("ret: " & ret'Img);
--        
--        STM32.Device.PB12.Set;
      
      CE.set;
      delay 0.1;
   end setRxMode;
     
   
   function ReadWaitBlocking(This: in out RF24_Device) return HAL.UInt8 is
      ret: HAL.UInt8;
   begin
      STM32.Device.PB12.Clear;
      
      This.SPI_Port.all.Transmit(Outgoing => HAL.UInt8(97));
      --This.SPI_Port.all.Transmit(Outgoing => 16#00#);

      --while not This.SPI_Port.all.Rx_Is_Empty loop
      Console.putLine("Inside :" );
      for I in 0..32 loop
         This.SPI_Port.all.Receive(Incoming => This.readBuffer(0));
         Console.putChar(Character'Val(This.readBuffer(0)));
      end loop;
      Console.putChar(ASCII.CR);
--        This.SPI_Port.all.Receive(Incoming => This.readBuffer(1));
--        Console.putLine("Inside :" & This.readBuffer(1)'Img);
--              This.SPI_Port.all.Receive(Incoming => This.readBuffer(2));
--        Console.putLine("Inside :" & This.readBuffer(2)'Img);
--        This.readPointer := 3;
--        This.SPI_Port.all.Receive(Incoming => This.readBuffer(This.readPointer));
--        This.readPointer := This.readPointer + 1;
      --end loop;
      
--        This.SPI_Port.all.Receive(Incoming => This.readBuffer(This.readPointer));
--        This.readPointer := This.readPointer + 1;
      

      --This.SPI_Port.all.Transmit(Outgoing => 16#00#);
      --This.SPI_Port.all.Receive(Incoming => This.readBuffer(This.readPointer));
      --This.readPointer := 1;
      
      STM32.Device.PB12.Set;
--        if This.readPointer > 0 then
--           return This.readBuffer(This.readPointer-1);
--        else
--           return Hal.UInt8(0);
--        end if;
      return Hal.UInt8(0);
   end ReadWaitBlocking;
   
   
   function newDataAvailable(This: RF24_Device) return Boolean is
   begin 
      return (This.readPointer > 0);
   end newDataAvailable;
   
   procedure getData(This: in out RF24_Device;
                     data: out STM32.SPI.UInt8_Buffer;
                     count: out Integer) is
      index : Integer := 0;
   begin
      count := 0;
      
      Console.putLine("Count: " & This.readPointer'Img);
--        if This.readPointer > 0 then
--           for I in 0 .. This.readPointer-1 loop
--              data(I) := This.readBuffer(I);
--              count := count + 1;
--           end loop;
--        end if;
      for K of data loop
         K := This.readBuffer(index);
         index := index + 1;
         count := count + 1;
         if count = this.readPointer then
            exit;
         end if;
      end loop;
      This.readPointer := 0;
      
   end getData;
   
end RF24;
