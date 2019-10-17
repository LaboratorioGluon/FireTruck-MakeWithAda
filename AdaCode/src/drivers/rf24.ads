with STM32.SPI;
with STM32.GPIO;
with HAL;
with HAL.GPIO;
with Unchecked_Conversion;
with System;
package RF24 is
   
   -- temp
   pipe: HAL.UInt64 := 16#DEADBEEF00#;
   InitOK : Boolean := True;
   type Read_Command is record
      Register: HAL.UInt5 := 0;
      Fixed: HAL.UInt3 := 0;
   end record
     with  Size => 8,
     Bit_Order => System.Low_Order_First;
   
   for Read_Command use record
      Register at 0 range 0 .. 4;
      Fixed at 0 range 5 .. 7;
   end record;
   
   type Write_Command is record
      Register: HAL.UInt5 := 0;
      Fixed: HAL.UInt3 := 2#001#;
   end record
     with  Size => 8,
     Bit_Order => System.Low_Order_First;
   for Write_Command use record
      Register at 0 range 0 .. 4;
      Fixed at 0 range 5 .. 7;
   end record;
   
   function FROM_Command is new
     Unchecked_Conversion(Read_Command, HAL.UInt8 );
   function FROM_Command is new
     Unchecked_Conversion(Write_Command, HAL.UInt8 );
   
      
   
   type Status_Register is record
      TX_FULL        : Boolean := False;
      RX_P_NO        : HAL.UInt3 := 0;
      MAX_RT         : Boolean := False;
      TX_DS          : Boolean := False;
      RX_DR          : Boolean := False;
      Reserved_7_7   : Boolean := False;
   end record
     with  Size => 8,
     Bit_Order => System.Low_Order_First;

   for Status_Register use record
      TX_FULL           at 0 range 0 .. 0;
      RX_P_NO           at 0 range 1 .. 3;
      MAX_RT            at 0 range 4 .. 4;
      TX_DS             at 0 range 5 .. 5;
      RX_DR             at 0 range 6 .. 6;
      Reserved_7_7      at 0 range 7 .. 7;
   end record;
   
   Config_Register_Dir: HAL.UInt8 := 16#0#;
   
   type Config_Register is record
      PRIM_RX        : Boolean := False;
      PWR_UP         : Boolean := False;
      CRCO           : Boolean := False;
      EN_CRC         : Boolean := False;
      MASK_MAX_RT    : Boolean := False;
      MASK_TX_DS     : Boolean := False;
      MASK_RX_DR     : Boolean := False;
      Reserved_7_7   : Boolean := False;
   end record
     with  Size => 8,
     Bit_Order => System.Low_Order_First;

   for Config_Register use record
      PRIM_RX           at 0 range 0 .. 0;
      PWR_UP            at 0 range 1 .. 1;
      CRCO              at 0 range 2 .. 2;
      EN_CRC            at 0 range 3 .. 3;
      MASK_MAX_RT       at 0 range 4 .. 4;
      MASK_TX_DS        at 0 range 5 .. 5;
      MASK_RX_DR        at 0 range 6 .. 6;
      Reserved_7_7      at 0 range 7 .. 7;
   end record;
   
   type FIFO_Status_Register is record
      RX_EMPTY       : Boolean := False;
      RX_FULL        : Boolean := False;
      reserved_1     : HAL.UInt2 := 0;
      TX_EMPTY       : Boolean := False;
      TX_FULL        : Boolean := False;
      TX_REUSE       : Boolean := False;
      reserved_2     : Boolean := False;
   end record
     with  Size => 8,
     Bit_Order => System.Low_Order_First;

   for FIFO_Status_Register use record
      RX_EMPTY at 0 range 0 .. 0;
      RX_FULL   at 0 range 1 .. 1;
      reserved_1 at 0 range 2 .. 3;
      TX_EMPTY at 0 range 4 .. 4;
      TX_FULL at 0 range 5 .. 5;
      TX_REUSE at 0 range 6 .. 6;
      reserved_2 at 0 range 7 .. 7;
   end record;

   function TO_Register is new
     Unchecked_Conversion(HAL.UInt8, Status_Register);
   function TO_Register is new
     Unchecked_Conversion(HAL.UInt8, Config_Register);
   function TO_Register is new
     Unchecked_Conversion(HAL.UInt8, FIFO_Status_Register);
   
   function FROM_Register is new
     Unchecked_Conversion(Config_Register, HAL.UInt8 );
   function FROM_Register is new
     Unchecked_Conversion(Status_Register, HAL.UInt8 );
   function FROM_Register is new
     Unchecked_Conversion(FIFO_Status_Register, HAL.UInt8 );
   
   
   type RF24_Device( SPI_Port : access STM32.SPI.SPI_Port) is 
     tagged limited record
      readBuffer: STM32.SPI.UInt8_Buffer(0 .. 32) := (others => 0);
      readPointer: Integer := 0;
      MOSI: aliased STM32.GPIO.GPIO_Point;
      MISO: aliased STM32.GPIO.GPIO_Point;
      NSS: aliased STM32.GPIO.GPIO_Point;
      CLK: aliased STM32.GPIO.GPIO_Point;
      CE: aliased STM32.GPIO.GPIO_Point;
      
      last_status: Status_Register;
   end record;
   

   procedure powerUp(This: in out RF24_Device);
   
   procedure setRxMode(This: in out RF24_Device);

   procedure Init(This: in out RF24_Device;
                  MOSI_Pin: in STM32.GPIO.GPIO_Point;
                  MISO_Pin: in STM32.GPIO.GPIO_Point;
                  NSS_Pin: in out STM32.GPIO.GPIO_Point;
                  CLK_Pin: in STM32.GPIO.GPIO_Point;
                  CE_Pin: in out STM32.GPIO.GPIO_Point);

   
   procedure Configure(SPI_port: in out STM32.SPI.SPI_Port);
      
   function ReadWaitBlocking(This: in out RF24_Device) return HAL.UInt8;
   
   function newDataAvailable(This: in out RF24_Device) return Boolean;
   
   procedure getData(This: in out RF24_Device;
                     data: out HAL.UInt8_Array;
                     count: out Integer);

   procedure writeRegister(This: in out RF24_Device;
                           Reg: in HAL.UInt5;
                           Value: in HAL.UInt8);
   
   function readRegister(This: in out RF24_Device;
                         Reg: in HAL.UInt5) return HAL.Uint8;
   
  
   
   
   
   
   
   
   CONFIG :      HAL.Uint5 := 16#00#;
   EN_AA :       HAL.Uint5 := 16#01#;
   EN_RXADDR :   HAL.Uint5 := 16#02#;
   SETUP_AW :    HAL.Uint5 := 16#03#;
   SETUP_RETR :  HAL.Uint5 := 16#04#;
   RF_CH :       HAL.Uint5 := 16#05#;
   RF_SETUP :    HAL.Uint5 := 16#06#;
   STATUS :      HAL.Uint5 := 16#07#;
   OBSERVE_TX :  HAL.Uint5 := 16#08#;
   CD :          HAL.Uint5 := 16#09#;
   RX_ADDR_P0 :  HAL.Uint5 := 16#0A#;
   RX_ADDR_P1 :  HAL.Uint5 := 16#0B#;
   RX_ADDR_P2 :  HAL.Uint5 := 16#0C#;
   RX_ADDR_P3 :  HAL.Uint5 := 16#0D#;
   RX_ADDR_P4 :  HAL.Uint5 := 16#0E#;
   RX_ADDR_P5 :  HAL.Uint5 := 16#0F#;
   TX_ADDR:      HAL.Uint5 := 16#10#;
   RX_PW_P0:     HAL.Uint5 := 16#11#;
   RX_PW_P1:     HAL.Uint5 := 16#12#;
   RX_PW_P2:     HAL.Uint5 := 16#13#;
   RX_PW_P3:     HAL.Uint5 := 16#14#;
   RX_PW_P4:     HAL.Uint5 := 16#15#;
   RX_PW_P5:     HAL.Uint5 := 16#16#;
   FIFO_STATUS:  HAL.Uint5 := 16#17#;
   DYNPD :       Hal.Uint5 := 16#1C#;   
   FEATURE :     HAL.Uint5 := 16#1D#;
   
end RF24;
