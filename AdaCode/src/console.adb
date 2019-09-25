with STM32.GPIO; use STM32.GPIO;
with HAL;

package body Console is

   procedure Init( baudRate: STM32.USARTs.Baud_Rates) is
      config: STM32.GPIO.GPIO_Port_Configuration(STM32.GPIO.Mode_AF);
   begin
      
      -- Configure GPIOs
      config.Resistors := STM32.GPIO.Pull_Up;
      config.AF_Output_Type := STM32.GPIO.Open_Drain;
      config.AF_Speed := STM32.GPIO.Speed_50MHz;
      config.AF := gpio_af;
      
      STM32.device.Enable_Clock(tx_pin & rx_Pin);
      STM32.GPIO.Configure_IO(tx_pin & rx_pin,
                              config);
        
      -- Configure USART
      STM32.device.Enable_Clock(dev);
      STM32.USARTS.Enable(dev);
      
      STM32.USARTS.Set_Mode(This => dev,
                            To   => STM32.USARTs.Tx_Rx_Mode);
      
      STM32.USARTS.Set_Baud_Rate(dev, baudRate);
      
      STM32.USARTS.Enable_Interrupts(This   => dev,
                                     Source => STM32.USARTs.Received_Data_Not_Empty);
      
   end Init;

   procedure putChar(c : Character) is
   begin
      -- Block until transmiter is ready.
      while not STM32.USARTs.Tx_Ready(dev) loop
         null;
      end loop;
      STM32.USARTs.Transmit(This => dev,
                            Data => Character'Pos(c));
   end putChar;
   
   procedure put(s: String) is
   begin
      for i in s'Range loop
         putChar(s(i));
      end loop;
   end put;
   
   
   procedure putLine(s: String) is
   begin
      put(s &  ASCII.CR & ASCII.LF);
   end putLine;
   
   procedure getChar(c: out Character) is
      data: HAL.Uint9;
   begin
      -- Block until receiver is ready.
      while not STM32.USARTs.Rx_Ready(dev) loop
         null;
      end loop;
      STM32.USARTs.Receive(This => dev,
                           Data => data);
      c := Character'Val(data);
   end getChar;
      
  procedure getString(s: out String; l: out Integer) is
   begin 
      DataManager.getString(s => s,
                            l => l);
   end getString;
   
   function isStringReady return Boolean is
   begin
      return DataManager.isStringReady;
   end isStringReady;
   
   protected body IRQManager is 
      
      function isStringReady return Boolean is
      begin
         return stringReady;
         
      end isStringReady;
        
      procedure getString(s: out String; l: out Integer) is 
      begin
         s := lastString;
         l := lenString;
         stringReady := False;
         STM32.USARTs.Enable_Interrupts(dev, STM32.USARTS.Received_Data_Not_Empty);
         lenString := 0;
      end getString;
      
      procedure IRQHandler is
      begin
         -- Only interrupt from new data
         lenString := lenString + 1;
         lastString(lenString) := Character'Val(STM32.USARTS.Current_Input(dev));
         if lastString(lenString) = ASCII.CR or lenString = lastString'Length then
            stringReady := True;
            STM32.USARTs.Disable_Interrupts(dev, STM32.USARTS.Received_Data_Not_Empty);
         end if;
         STM32.USARTs.Clear_Status(dev, STM32.USARTs.Read_Data_Register_Not_Empty);
      end IRQHandler;
      
   end IRQManager;   
     
end Console;
