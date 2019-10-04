with STM32.SPI;
with STM32.GPIO;
with HAL;
with HAL.GPIO;
with Unchecked_Conversion;
with System;
package RF24 is
   
   -- temp
   pipe: HAL.UInt64 := 16#DEADBEEF00#;
   
   MOSI: aliased STM32.GPIO.GPIO_Point;
   MISO: aliased STM32.GPIO.GPIO_Point;
   NSS: aliased STM32.GPIO.GPIO_Point;
   CLK: aliased STM32.GPIO.GPIO_Point;
   CE: aliased STM32.GPIO.GPIO_Point;
   
   SPI : aliased access STM32.SPI.SPI_Port;
   --SPI: aliased STM32.SPI.SPI_Port;
   
   
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
   
   function FROM_Command is new
     Unchecked_Conversion(Read_Command, HAL.UInt8 );
   
   
--     for Read_Command  use record
--        Register at 0 range 0..4;
--        Fixed    at 0 range 5..7;
--     end record;
   
   
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
   

   function TO_Register is new
     Unchecked_Conversion(HAL.UInt8, Status_Register);
   function TO_Register is new
     Unchecked_Conversion(HAL.UInt8, Config_Register);
   
   function FROM_Register is new
     Unchecked_Conversion(Config_Register, HAL.UInt8 );
   
   type RF24_Device( SPI_Port : access STM32.SPI.SPI_Port) is 
     tagged limited record
      readBuffer: STM32.SPI.UInt8_Buffer(0 .. 10) := (others => 0);
      readPointer: Integer := 0;
   end record;
   
   procedure powerUp(This: in out RF24_Device);
   
   procedure setRxMode(This: in out RF24_Device);

   procedure Init(This: RF24_Device;
                  MOSI_Pin: in STM32.GPIO.GPIO_Point;
                  MISO_Pin: in STM32.GPIO.GPIO_Point;
                  NSS_Pin: in out STM32.GPIO.GPIO_Point;
                  CLK_Pin: in STM32.GPIO.GPIO_Point;
                  CE_Pin: in out STM32.GPIO.GPIO_Point);

   procedure Init(SPI_port: access STM32.SPI.SPI_Port;
                  MOSI_Pin: in STM32.GPIO.GPIO_Point;
                  MISO_Pin: in STM32.GPIO.GPIO_Point;
                  NSS_Pin: in out STM32.GPIO.GPIO_Point;
                  CLK_Pin: in STM32.GPIO.GPIO_Point;
                  CE_Pin: in out STM32.GPIO.GPIO_Point);
   
   procedure Configure(SPI_port: in out STM32.SPI.SPI_Port);
      
   function ReadWaitBlocking(This: in out RF24_Device) return HAL.UInt8;
   
   function newDataAvailable(This: RF24_Device) return Boolean;
   
   procedure getData(This: in out RF24_Device;
                     data: out STM32.SPI.UInt8_Buffer;
                     count: out Integer);

   function writeRegister(Reg: in HAL.UInt8;
                          Value: in HAL.UInt8) return Status_Register;
   
   
   
end RF24;
