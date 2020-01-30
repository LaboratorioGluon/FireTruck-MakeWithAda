import serial
import struct


# List of commands
TEST_LED = 0
SET_DIRECTION = 1
SET_SPEED = 2
SET_SERVO = 3
SET_INFO = 6



class Comms:

    # Init the serial communication with Arduino
    def __init__(self):
        self.ser = serial.Serial('COM35', 19200) 
        self.ser.write(self.getCmd(SET_SPEED, [20]))
        
    def close(self):
        self.ser.close()
        
    # Creates the data packet with the correct format
    # Which is:
    # 1st:  Tag: Id of the commands
    # 2nd:  Len: Len of the data in the packets (without the Tag and Len)
    # 3rd: Data: Data to be send with the command.
    def getCmd(self, tag, data):
        print(struct.pack("BB%sb" % len(data), tag, len(data), *data))
        return struct.pack("BB%sb" % len(data), tag, len(data), *data)
        
    # Creates the command packet and send it through serial
    def sendCmd(self, tag, data):
        self.ser.write(self.getCmd(tag, data))
        
    # Custom function for different commands...
    def setDirection(self, dir):
       self.ser.write(self.getCmd(SET_SPEED, [35]))
       self.ser.write(self.getCmd(SET_DIRECTION, [dir]))
       
    def setServos(self, hor, ver):
       self.ser.write(self.getCmd(SET_SERVO, [int(hor), int(ver)]))
       
    def setTarget(self, angle, dist):
        self.ser.write(self.getCmd(SET_INFO, [ int(angle), int(dist)]))
          
          
# Testbench. You can run this program with 'python Comms.py' 
# and send data to the truck
if __name__ == "__main__":
    print('Test de comms')
    Com = Comms()
    data = ''
    while not 'q' in data:
        data = input("Cmd: ")
        datas = [int(x) for x in data.split(" ") if len(x) > 0]
        Com.sendCmd(datas[0], datas[1:])
    Com.close()
    
    