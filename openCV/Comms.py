import serial
import struct

TEST_LED = 0
SET_DIRECTION = 1
SET_SPEED = 2

class Comms:

    def __init__(self):
        self.ser = serial.Serial('\\COM5', 19200) 
        self.ser.write(self.getCmd(SET_SPEED, [20]))
    def getCmd(self, tag, data):
        return struct.pack("BB%sB" % len(data), tag, len(data), *data)
        
    def setDirection(self, dir):
       self.ser.write(self.getCmd(SET_SPEED, [18]))
       self.ser.write(self.getCmd(SET_DIRECTION, [dir]))
            