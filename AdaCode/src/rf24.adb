
with HAL.SPI;
with STM32.Device;
with Console;

with STM32_SVD.SPI;

package body RF24 is

   procedure Init(This: RF24_Device;
                  MOSI_Pin: in STM32.GPIO.GPIO_Point;
                  MISO_Pin: in STM32.GPIO.GPIO_Point;
                  NSS_Pin: in out STM32.GPIO.GPIO_Point;
                  CLK_Pin: in STM32.GPIO.GPIO_Point;
                  CE_Pin: in out STM32.GPIO.GPIO_Point) is
      
      Config_AF : STM32.GPIO.GPIO_Port_Configuration (Mode => STM32.GPIO.Mode_AF);
      Config_GPIO: STM32.GPIO.GPIO_Port_Configuration( Mode=> STM32.GPIO.Mode_Out);
      
            
      send2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      recv2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      status: HAL.SPI.SPI_Status;
      return_status : Status_Register;
      
      ret : HAL.UInt8;
      
      
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
      
      delay 0.1;
      
      return_status := writeRegister(RF24.CONFIG, 16#0C#);
      return_status := writeRegister(RF24.SETUP_RETR, 16#65#);
      return_status := writeRegister(RF24.RF_SETUP, 2#00100110#);
      -- Activate
      
      Console.putLine(" -------- ACTIVATE -------- ");
      Console.putLine("Setting ACTIVATE");
      STM32.Device.PB12.Clear;
      send2(0) := 16#50#;
      send2(1) := 16#73#;
      STM32.Device.SPI_2.Transmit( HAL.SPI.SPI_Data_8b(send2), status);
      Console.putline("SPI status: " & status'Img);
      STM32.Device.PB12.Set;
      
      Console.putLine(" -------- Feature -------- ");
      Console.putLine("Setting FEATURE");
      return_status := writeRegister(FEATURE, 0);
      Console.putLine("Status :" & FROM_Register(return_status)'Img);
      

      Console.putLine(" -------- Dynamic pay -------- ");
      Console.putLine("Setting DYNPay");
      return_status := writeRegister(DYNPD, 0);
      
      return_status := writeRegister(RF24.STATUS, 16#70#);
      
      
      return_status := writeRegister(RF24.RF_CH, 76);
      
      STM32.Device.PB12.Clear;
      Console.putLine(" -------- Channel Data -------- ");
      Console.putLine("Checking Channel data ");
      return_status := readRegister(RF24.RF_CH, ret);
      Console.putLine("Channel Data: " & ret'Img);
      STM32.Device.PB12.Set;
      
      
      
      STM32.Device.PB12.Clear;
      Console.putLine(" -------- FLUSH TX -------- ");
      Console.putLine("Flushing TX");
      send2(0) := 2#11100010#;
      STM32.Device.SPI_2.Transmit( send2(0));
      Console.putline("SPI status: " & status'Img);
      STM32.Device.PB12.Set;
      
      STM32.Device.PB12.Clear;
      Console.putLine(" -------- FLUSH RX -------- ");
      Console.putLine("Flushing RX");
      send2(0) := 2#11100011#;
      STM32.Device.SPI_2.Transmit( send2(0));
      Console.putline("SPI status: " & status'Img);
      STM32.Device.PB12.Set;
      delay 0.5;
      
      
      delay 1.0;
        
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
      
      --read_cmd: Read_Command(Reg => 0);
      
   begin
      status_reg := readRegister(RF24.CONFIG, ret);
      config_reg := TO_Register(ret);
      config_reg.PWR_UP := True;
      status_reg := writeRegister(RF24.CONFIG, FROM_Register(config_reg));
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
      
      setup_aw : HAL.SPI.SPI_Data_8b(0..1) := (16#23#,16#03#);
      rx_setup_data: HAL.SPI.SPI_Data_8b(0..1) := (16#26#,2#00100110#);
      status: HAL.SPI.SPI_Status;
      config_reg: Config_Register;
      
      ret : HAL.UInt8;
      
      send2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      recv2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      
      send5 : STM32.SPI.UInt8_Buffer(0 .. 4);
      recv5 : STM32.SPI.UInt8_Buffer(0 .. 4);
      
      read_cmd : Read_Command;
      
      radio_status : Status_Register;
      
      
   begin
      
      
      
--        
--        radio_status := readRegister(RF24.STATUS, ret);
--        Console.putLine("Status leido: " & ret'Img);
      
      radio_status := readRegister(CONFIG, ret);
      Console.putLine("Config leido: " & ret'Img);
      
      config_reg := TO_Register(ret);
      config_reg.PWR_UP := True;
      config_reg.PRIM_RX := False;
      radio_status := writeRegister(CONFIG, FROM_Register(config_reg));
      radio_status := readRegister(CONFIG, ret);
      Console.putLine("Config leido: " & ret'Img);
      delay 10.0;
      -- RX Setup and check
      Console.putLine(" -------- RX -------- ");
      Console.putLine("Setting RX("& rx_setup_data(0)'Img & ") to " & rx_setup_data(1)'Img);
      
      
      STM32.Device.PB12.Clear;

      STM32.Device.SPI_2.Transmit( rx_setup_data, status);
      Console.putline("SPI status: " & status'Img);
      STM32.Device.PB12.Set;
      
      STM32.Device.PB12.Clear;
      read_cmd.Register := 16#06#;
      Console.putLine("Checking RX " & FROM_Command(read_cmd)'Img);
      rx_setup_data(0) := 16#06#;
      rx_setup_data(1) := 16#FF#;
      
      STM32.Device.SPI_2.Transmit_Receive(STM32.SPI.UInt8_Buffer(rx_setup_data),
                                          recv2,
                                          Positive(2));

      Console.putLine("Status: " & recv2(0)'Img);
      Console.putLine("RX: " & recv2(1)'Img);
      
      if recv2(1) = 2#00100110# then
         Console.putLine("RX Correct!");
      else
         Console.putLine("[ERROR] RX Correct!");
      end if;
      STM32.Device.PB12.Set;
      delay 0.1;
      
      -- AW Setup and check
            
      STM32.Device.PB12.Clear;
      STM32.Device.SPI_2.Transmit(setup_aw, status);
      STM32.Device.PB12.Set;
      
      STM32.Device.PB12.Clear;
      read_cmd.Register := 16#03#;
      
      Console.putLine(" -------- AW -------- ");
      Console.putLine("Checking AW " & FROM_Command(read_cmd)'Img);
      send2(0) := 16#03#;
      send2(1) := 16#FF#;
      STM32.Device.SPI_2.Transmit_Receive(send2,
                                          recv2,
                                          Positive(2));
      Console.putLine("Status: " & recv2(0)'Img);
      Console.putLine("AW: " & recv2(1)'Img);
      STM32.Device.PB12.Set;
      
      
      -- Pipe setup and check
           
      STM32.Device.PB12.Clear;
      STM32.Device.SPI_2.Transmit(pipe_set_data, status);
      STM32.Device.PB12.Set;
      
      STM32.Device.PB12.Clear;
      read_cmd.Register := 16#0B#;
      
      Console.putLine(" -------- PIPE 1 -------- ");
      Console.putLine("Checking Pipe 1" & FROM_Command(read_cmd)'Img);
      send5(0) := 16#0B#;
      send5(1) := 16#FF#;
      send5(2) := 16#FF#;
      send5(3) := 16#FF#;
      send5(4) := 16#FF#;
      STM32.Device.SPI_2.Transmit_Receive(send5,
                                          recv5,
                                          Positive(5));
      Console.putLine("Status: " & recv5(0)'Img);
      Console.putLine("Pipe 1: " & recv5(1)'Img);
      Console.putLine("Pipe 2: " & recv5(2)'Img);
      Console.putLine("Pipe 3: " & recv5(3)'Img);
      Console.putLine("Pipe 4: " & recv5(4)'Img);
      
      STM32.Device.PB12.Set;
      
      delay 0.1;      
      
      STM32.Device.PB12.Clear;
      STM32.Device.SPI_2.Transmit(pipe_payload_size, status);
      STM32.Device.PB12.Set;
      
      STM32.Device.PB12.Clear;
      read_cmd.Register := 16#12#;
      
      Console.putLine(" -------- Pipe payload size -------- ");
      Console.putLine("Checking payload size " & FROM_Command(read_cmd)'Img);
      send2(0) := 16#12#;
      send2(1) := 16#FF#;
      STM32.Device.SPI_2.Transmit_Receive(send2,
                                          recv2,
                                          Positive(2));
      Console.putLine("Status: " & recv2(0)'Img);
      Console.putLine("Size: " & recv2(1)'Img);
      STM32.Device.PB12.Set;

      delay 0.1;
      STM32.Device.PB12.Clear;
      Console.putLine("Setting RX mode!");
      config_reg.PWR_UP := True;
      config_reg.PRIM_RX := True;
      data(1) := FROM_Register(config_reg);
      STM32.Device.SPI_2.Transmit(data, status);
      STM32.Device.PB12.Set;
      
      delay 1.0;
      
      
      
      

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
      
      read_payload_cmd : STM32.SPI.UInt8_Buffer(0 .. 31) := (0 => HAL.UInt8(97), 
                                                            others => HAL.UInt8(16#FF#));
      received_data : STM32.SPI.UInt8_Buffer(0 .. 31) := ( others => HAL.UInt8(0));
      
      send2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      recv2 : STM32.SPI.UInt8_Buffer(0 .. 1);
   begin
      STM32.Device.PB12.Clear;
      
--        This.SPI_Port.all.Transmit(Outgoing => HAL.UInt8(97));
--        while not STM32_SVD.SPI.SPI2_Periph.SR.TXE loop
--              null;
--           end loop;
--        --This.SPI_Port.all.Transmit(Outgoing => 16#00#);
--  
--  --        while not STM32_SVD.SPI.SPI2_Periph.SR.RXNE loop
--  --           null;
--  --        end loop;
--  --  
--  --        ret := HAL.UInt8 (STM32_SVD.SPI.SPI2_Periph.DR.DR);
--        --while not This.SPI_Port.all.Rx_Is_Empty loop
--        Console.putLine("Inside :" );
--        for I in 0..31 loop
--           --This.SPI_Port.all.Receive(Incoming => This.readBuffer(0));
--           --Console.putChar(Character'Val(This.readBuffer(0)));
--           
--           -- Directly the hardware
--           STM32_SVD.SPI.SPI2_Periph.DR.DR := HAL.Uint16(16#FF#);
--           while not STM32_SVD.SPI.SPI2_Periph.SR.TXE loop
--              null;
--           end loop;
--           STM32_SVD.SPI.SPI2_Periph.DR.DR := HAL.Uint16(16#FF#);
--           while not STM32_SVD.SPI.SPI2_Periph.SR.TXE loop
--              null;
--           end loop;
--           
--           while not STM32_SVD.SPI.SPI2_Periph.SR.RXNE loop
--              null;
--           end loop;
--  
--           ret := HAL.UInt8 (STM32_SVD.SPI.SPI2_Periph.DR.DR);
--           Console.putLine("Dato crudo... : " & Character'Val(ret) & " (" & ret'Img  & ")");
--  
--           
--        end loop;
      
      STM32.Device.SPI_2.Transmit_Receive(read_payload_cmd,
                                          received_data,
                                          Positive(32));
      
      
      for k of received_data loop
         Console.putLine("Dato crudo... : " & Character'Val(k) & " (" & k'Img  & ")");
      end loop;
      STM32.Device.PB12.Set;
      
      
      
      STM32.Device.PB12.Clear;
      send2(0) := 16#17#;
      send2(0) := 16#FF#;
      STM32.Device.SPI_2.Transmit_Receive(send2,
                                          recv2,
                                          Positive(2));
      Console.putLine("Status: " & recv2(0)'Img);
      Console.putLine("FIFO Status: " & recv2(1)'Img);
      STM32.Device.PB12.Set;
      
      STM32.Device.PB12.Clear;
      send2(0) := 16#27#;
      send2(0) := 16#00#;
      STM32.Device.SPI_2.Transmit_Receive(send2,
                                          recv2,
                                          Positive(2));
      Console.putLine("Status: " & recv2(0)'Img);
      Console.putLine("Status 2?: " & recv2(1)'Img);
      STM32.Device.PB12.Set;
      
      
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
   
   function writeRegister(Reg: in HAL.UInt5;
                          Value: in HAL.UInt8) return Status_Register is
      
      
      send2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      recv2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      
      cmd: Write_Command;
      --status: HAL.SPI.SPI_Status;
      ret_status : Status_Register;
   begin
      cmd.Register := Reg;
      STM32.Device.PB12.Clear;
      send2(0) := FROM_Command(cmd);
      send2(1) := Value;
      STM32.Device.SPI_2.Transmit_Receive( send2,
                                           recv2,
                                           Positive(2));
      STM32.Device.PB12.Set;
      
      ret_status := TO_Register(recv2(0));

        
--        if status /= HAL.SPI.Ok then
--           Console.putLine("[ERROR] WriteRegister " & Reg'Img);
--        end if;
      return ret_status;
   end writeRegister;
   
   function readRegister(Reg: in HAL.UInt5;
                         status_reg: out Status_Register) return Status_Register is
      send2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      recv2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      
      cmd : Read_Command;
      
      ret_status : Status_Register;
   begin
      cmd.Register := Reg;
      
      STM32.Device.PB12.Clear;      
      send2(0) := FROM_Command(cmd);
      send2(1) := 16#FF#;
      STM32.Device.SPI_2.Transmit_Receive(send2,
                                          recv2,
                                          Positive(2));
      STM32.Device.PB12.Set;
      
      ret_status := TO_Register(recv2(0));
      status_reg := TO_Register(recv2(1));
      
      return ret_status;
   end readRegister;
   
   
   function readRegister(Reg: in HAL.UInt5;
                         data: out HAL.Uint8) return Status_Register is
            
      send2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      recv2 : STM32.SPI.UInt8_Buffer(0 .. 1);
      
      cmd : Read_Command;
      
      ret_status : Status_Register;
   begin
      cmd.Register := Reg;
      
      STM32.Device.PB12.Clear;      
      send2(0) := FROM_Command(cmd);
      send2(1) := 16#FF#;
      STM32.Device.SPI_2.Transmit_Receive(send2,
                                          recv2,
                                          Positive(2));
      STM32.Device.PB12.Set;
      
      ret_status := TO_Register(recv2(0));
      data := recv2(1);
      
      return ret_status;
   end readRegister;
   
end RF24;
