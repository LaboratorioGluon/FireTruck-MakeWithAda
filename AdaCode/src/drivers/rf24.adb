
with HAL.SPI;
with STM32.Device;
with Console;


package body RF24 is

   procedure Init(This: in out RF24_Device;
                  MOSI_Pin: in STM32.GPIO.GPIO_Point;
                  MISO_Pin: in STM32.GPIO.GPIO_Point;
                  NSS_Pin: in out STM32.GPIO.GPIO_Point;
                  CLK_Pin: in STM32.GPIO.GPIO_Point;
                  CE_Pin: in out STM32.GPIO.GPIO_Point) is
      
      Config_AF : STM32.GPIO.GPIO_Port_Configuration (Mode => STM32.GPIO.Mode_AF);
      Config_GPIO: STM32.GPIO.GPIO_Port_Configuration( Mode=> STM32.GPIO.Mode_Out);
      
            
      send2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      status: HAL.SPI.SPI_Status;
      return_status : Status_Register;
      
      ret : HAL.UInt8;
      
      
   begin
      This.MOSI := MOSI_Pin;
      This.MISO := MISO_Pin;
      This.NSS := NSS_Pin;
      This.CLK := CLK_Pin;
      This.CE := CE_Pin;
      
      STM32.Device.Enable_Clock(This.MOSI);
      STM32.Device.Enable_Clock(This.MISO);
      STM32.Device.Enable_Clock(This.NSS);
      STM32.Device.Enable_Clock(This.CLK);
      STM32.Device.Enable_Clock(This.CE);
      
      Config_AF := (Mode => STM32.GPIO.Mode_AF,
                    Resistors =>  STM32.GPIO.Floating,
                    AF_Output_Type => STM32.GPIO.Push_Pull,
                    AF_Speed  => STM32.GPIO.Speed_25MHz,
                    AF => STM32.Device.GPIO_AF_SPI2_5
                   );
      
      This.MOSI.Configure_IO(Config_AF);
      This.MISO.Configure_IO(Config_AF);
      This.CLK.Configure_IO(Config_AF);
      
      -- Configure the CE pin      
      Config_GPIO := (Mode => STM32.GPIO.Mode_Out,
                 Resistors => STM32.GPIO.Pull_Up,
                 Output_Type => STM32.GPIO.Push_Pull,
                 Speed => STM32.GPIO.Speed_50MHz
                );
                 
      This.CE.Configure_IO(Config_GPIO);
      This.NSS.Configure_IO(Config_GPIO);
      
      This.CE.Clear;
      This.NSS.Set;
      
      -- Configure the SPI
      Configure(This.SPI_Port.all);
      
      delay 0.1;
      
      This.writeRegister(RF24.CONFIG, 16#0C#);
      This.writeRegister(RF24.SETUP_RETR, 16#65#);
      This.writeRegister(RF24.RF_SETUP, 2#00100110#);
      -- Activate
      
      Console.putLine(" -------- ACTIVATE -------- ");
      Console.putLine("Setting ACTIVATE");
      This.NSS.Clear;
      send2(0) := 16#50#;
      send2(1) := 16#73#;
      This.SPI_Port.all.Transmit( HAL.SPI.SPI_Data_8b(send2), status);
      Console.putline("SPI status: " & status'Img);
      This.NSS.Set;
      
      Console.putLine(" -------- Feature -------- ");
      Console.putLine("Setting FEATURE");
      This.writeRegister(FEATURE, 0);
      Console.putLine("Status :" & FROM_Register(return_status)'Img);
      

      Console.putLine(" -------- Dynamic pay -------- ");
      Console.putLine("Setting DYNPay");
      This.writeRegister(DYNPD, 0);
      
      This.writeRegister(RF24.STATUS, 16#70#);
      
      
      This.writeRegister(RF24.RF_CH, 76);
      
      This.NSS.Clear;
      Console.putLine(" -------- Channel Data -------- ");
      Console.putLine("Checking Channel data ");
      ret := This.readRegister(RF24.RF_CH);
      Console.putLine("Channel Data: " & ret'Img);
      This.NSS.Set;
      
      
      
      This.NSS.Clear;
      Console.putLine(" -------- FLUSH TX -------- ");
      Console.putLine("Flushing TX");
      send2(0) := 2#11100010#;
      This.SPI_Port.all.Transmit( send2(0));
      Console.putline("SPI status: " & status'Img);
      This.NSS.Set;
      
      This.NSS.Clear;
      Console.putLine(" -------- FLUSH RX -------- ");
      Console.putLine("Flushing RX");
      send2(0) := 2#11100011#;
      This.SPI_Port.all.Transmit( send2(0));
      Console.putline("SPI status: " & status'Img);
      This.NSS.Set;
      delay 0.5;
      
      
      delay 1.0;
        
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
      ret: HAL.UInt8;
      config_reg: Config_Register;      
   begin
      
      ret := This.readRegister(RF24.CONFIG);
      config_reg := TO_Register(ret);
      config_reg.PWR_UP := True;
      This.writeRegister(RF24.CONFIG, FROM_Register(config_reg));
      delay 1.0;
      
   end powerUp;
   
   procedure setRxMode(This: in out RF24_Device) is
      use type HAL.UInt8;
      data : HAL.SPI.SPI_Data_8b(0..1) := ( 0 => 32, 1 => 2);
     
--        pipe_set_data : HAL.SPI.SPI_Data_8b(0..5) := 
--          ( 16#2C#, 16#DE#, 16#AD#, 16#BE#, 16#EF#, 16#00#);
      pipe_set_data       : constant  HAL.SPI.SPI_Data_8b(0..5) :=
        ( 16#2B#, 16#00#, 16#EF#, 16#BE#, 16#AD#, 16#DE#);
      pipe_payload_size   : constant HAL.SPI.SPI_Data_8b(0..1) := (16#32#, 32);
      
      channel_data : constant HAL.SPI.SPI_Data_8b(0..1) := (16#25#,76);
      
      setup_aw : constant HAL.SPI.SPI_Data_8b(0..1) := (16#23#,16#03#);
      rx_setup_data: HAL.SPI.SPI_Data_8b(0..1) := (16#26#,2#00100110#);
      status: HAL.SPI.SPI_Status;
      config_reg: Config_Register;
      
      ret : HAL.UInt8;
      
      send2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      recv2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      
      send5 : STM32.SPI.UInt8_Buffer(0 .. 4);
      recv5 : STM32.SPI.UInt8_Buffer(0 .. 4);
      
      read_cmd : Read_Command;      
      
   begin
            
      ret := This.readRegister(CONFIG);
      Console.putLine("Config leido: " & ret'Img);
      
      config_reg := TO_Register(ret);
      config_reg.PWR_UP := True;
      config_reg.PRIM_RX := False;
      This.writeRegister(CONFIG, FROM_Register(config_reg));
      ret := This.readRegister(CONFIG);
      Console.putLine("Config leido: " & ret'Img);
      delay 0.1;
      -- RX Setup and check
      Console.putLine(" -------- RX -------- ");
      Console.putLine("Setting RX("& rx_setup_data(0)'Img & ") to " & rx_setup_data(1)'Img);
      
      
      This.NSS.Clear;

      This.SPI_Port.all.Transmit( rx_setup_data, status);
      Console.putline("SPI status: " & status'Img);
      This.NSS.Set;
      
      This.NSS.Clear;
      read_cmd.Register := 16#06#;
      Console.putLine("Checking RX " & FROM_Command(read_cmd)'Img);
      rx_setup_data(0) := 16#06#;
      rx_setup_data(1) := 16#FF#;
      
      This.SPI_Port.all.Transmit_Receive(STM32.SPI.UInt8_Buffer(rx_setup_data),
                                          recv2,
                                          Positive(2));

      Console.putLine("Status: " & recv2(0)'Img);
      Console.putLine("RX: " & recv2(1)'Img);
      
      if recv2(1) = 2#00100110# then
         Console.putLine("RX Correct!");
         InitOK := True;
      else
         Console.putLine("[ERROR] RX Correct!");
         InitOK := False;
      end if;
      This.NSS.Set;
      delay 0.1;
      
      -- AW Setup and check
            
      This.NSS.Clear;
      This.SPI_Port.all.Transmit(setup_aw, status);
      This.NSS.Set;
      
      This.NSS.Clear;
      read_cmd.Register := 16#03#;
      
      Console.putLine(" -------- AW -------- ");
      Console.putLine("Checking AW " & FROM_Command(read_cmd)'Img);
      send2(0) := 16#03#;
      send2(1) := 16#FF#;
      This.SPI_Port.all.Transmit_Receive(send2,
                                          recv2,
                                          Positive(2));
      Console.putLine("Status: " & recv2(0)'Img);
      Console.putLine("AW: " & recv2(1)'Img);
      This.NSS.Set;
      
      
      -- Pipe setup and check
           
      This.NSS.Clear;
      This.SPI_Port.all.Transmit(pipe_set_data, status);
      This.NSS.Set;
      
      This.NSS.Clear;
      read_cmd.Register := 16#0B#;
      
      Console.putLine(" -------- PIPE 1 -------- ");
      Console.putLine("Checking Pipe 1" & FROM_Command(read_cmd)'Img);
      send5(0) := 16#0B#;
      send5(1) := 16#FF#;
      send5(2) := 16#FF#;
      send5(3) := 16#FF#;
      send5(4) := 16#FF#;
      This.SPI_Port.all.Transmit_Receive(send5,
                                          recv5,
                                          Positive(5));
      Console.putLine("Status: " & recv5(0)'Img);
      Console.putLine("Pipe 1: " & recv5(1)'Img);
      Console.putLine("Pipe 2: " & recv5(2)'Img);
      Console.putLine("Pipe 3: " & recv5(3)'Img);
      Console.putLine("Pipe 4: " & recv5(4)'Img);
      
      This.NSS.Set;
      
      delay 0.1;      
      
      This.NSS.Clear;
      This.SPI_Port.all.Transmit(pipe_payload_size, status);
      This.NSS.Set;
      
      This.NSS.Clear;
      read_cmd.Register := 16#12#;
      
      Console.putLine(" -------- Pipe payload size -------- ");
      Console.putLine("Checking payload size " & FROM_Command(read_cmd)'Img);
      send2(0) := 16#12#;
      send2(1) := 16#FF#;
      This.SPI_Port.all.Transmit_Receive(send2,
                                          recv2,
                                          Positive(2));
      Console.putLine("Status: " & recv2(0)'Img);
      Console.putLine("Size: " & recv2(1)'Img);
      This.NSS.Set;

      delay 0.1;
      This.NSS.Clear;
      Console.putLine("Setting RX mode!");
      config_reg.PWR_UP := True;
      config_reg.PRIM_RX := True;
      data(1) := FROM_Register(config_reg);
      This.SPI_Port.all.Transmit(data, status);
      This.NSS.Set;
      
      delay 0.2;
      
      
      This.CE.set;
      delay 0.1;
   end setRxMode;
   

   
   function ReadWaitBlocking(This: in out RF24_Device) return HAL.UInt8 is
      
      read_payload_cmd : constant STM32.SPI.UInt8_Buffer(0 .. 31) := (0 => HAL.UInt8(97), 
                                                                      others => HAL.UInt8(16#FF#));
      
      status_reg : FIFO_Status_Register;
      
   begin
      
      This.readBuffer := (others => 0);                           
      
      
      status_reg := TO_Register(This.readRegister(RF24.FIFO_STATUS));
         
      while status_reg.RX_EMPTY loop
         status_reg := TO_Register(This.readRegister(RF24.FIFO_STATUS));
         delay 0.1;
      end loop;

      This.NSS.Clear;
           
      This.SPI_Port.all.Transmit_Receive(read_payload_cmd,
                                          This.readBuffer,
                                         Positive(32));
      This.last_status := TO_Register(This.readBuffer(0));
      This.readBuffer(0..31) := This.readBuffer(1..32);
      
      This.NSS.Set;
      
      return Hal.UInt8(0);
   end ReadWaitBlocking;
   
   
   function newDataAvailable(This: in out RF24_Device) return Boolean is
   begin 
      return not (TO_Register(This.readRegister(RF24.FIFO_STATUS)).RX_EMPTY);
   end newDataAvailable;
   
   procedure getData(This: in out RF24_Device;
                     data: out  HAL.UInt8_Array;
                     count: out Integer) is
      index : Integer := 0;
   begin
      for K of data loop
         K := This.readBuffer(index);
         index := index + 1;
      end loop;
   end getData;
   
   procedure writeRegister(This: in out RF24_Device;
                          Reg: in HAL.UInt5;
                          Value: in HAL.UInt8) is
      
      
      send2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      recv2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      
      cmd: Write_Command;
   begin
      cmd.Register := Reg;
      This.NSS.Clear;
      send2(0) := FROM_Command(cmd);
      send2(1) := Value;
      This.SPI_Port.all.Transmit_Receive( send2,
                                           recv2,
                                           Positive(2));
      This.NSS.Set;
      
      This.last_status := TO_Register(recv2(0));


   end writeRegister;
  
   
     function readRegister(This: in out RF24_Device;
                           Reg: in HAL.UInt5) return HAL.Uint8 is
      
      send2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      recv2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      
      cmd : Read_Command;
      
   begin
      cmd.Register := Reg;
      
      This.NSS.Clear;      
      send2(0) := FROM_Command(cmd);
      send2(1) := 16#FF#;
      This.SPI_Port.all.Transmit_Receive(send2,
                                          recv2,
                                          Positive(2));
      This.NSS.Set;
      
      This.last_status := TO_Register(recv2(0));
      --data := recv2(1);
      return recv2(1);
   end readRegister;
   
end RF24;
