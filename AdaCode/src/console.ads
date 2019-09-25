with STM32.USARTs;
with STM32.Device;
with Ada.Interrupts;
with Ada.Interrupts.Names;
with STM32.GPIO;

package Console is

   -- Console configuration
   tx_Pin : STM32.GPIO.GPIO_Point := STM32.device.PA2;
   rx_Pin : STM32.GPIO.GPIO_Point := STM32.device.PA3;

   --   dev: aliased STM32.USARTs.USART(STM32.device.USART_2'Access);
   dev : STM32.USARTs.USART renames STM32.device.USART_2;
   gpio_af: STM32.GPIO_Alternate_Function := STM32.Device.GPIO_AF_USART2_7;
   irq_num: Ada.Interrupts.Interrupt_ID := Ada.Interrupts.Names.USART2_Interrupt;



   -- Init the GPIO and USART module.
   procedure init( baudRate: STM32.USARTs.Baud_Rates);

   -- Put char over USART.
   procedure putChar( c: Character );

   -- Put string over USART.
   procedure put(s: String);
   procedure putLine(s: String);

   -- Get one character from serial port.
   -- Blocking call until character arrives.
   procedure getChar(c: out Character);


   -- Get characters until a <newline> is received
   -- or until max string size.
   -- Blocking call.
   procedure getString(s: out String; l: out Integer);

   function isStringReady return Boolean;

private

   protected type IRQManager is
      pragma Interrupt_Priority;

      function isStringReady return Boolean;
      procedure getString(s: out String; l: out Integer);

   private
      lastString : String(1..20);
      lenString  : Integer := 0;
      stringReady : Boolean := False;

      procedure IRQHandler with Attach_Handler => irq_num;
   end IRQManager;

   DataManager : IRQManager;

end Console;
