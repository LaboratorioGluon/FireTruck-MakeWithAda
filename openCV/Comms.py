import serial
import struct

TEST_LED = 0
SET_DIRECTION = 1
SET_SPEED = 2
SET_SERVO = 3

class Comms:

    def __init__(self):
        self.ser = serial.Serial('\\COM5', 19200) 
        self.ser.write(self.getCmd(SET_SPEED, [20]))
        
    def close(self):
        self.ser.close()
        
    def getCmd(self, tag, data):
        print(struct.pack("BB%sb" % len(data), tag, len(data), *data))
        return struct.pack("BB%sb" % len(data), tag, len(data), *data)
        
    def sendCmd(self, tag, data):
        self.ser.write(self.getCmd(tag, data))
        
    def setDirection(self, dir):
       self.ser.write(self.getCmd(SET_SPEED, [18]))
       self.ser.write(self.getCmd(SET_DIRECTION, [dir]))
          
if __name__ == "__main__":
    print('Test de comms')
    Com = Comms()
    data = ''
    while not 'q' in data:
        data = input("Cmd: ")
        datas = [int(x) for x in data.split(" ") if len(x) > 0]
        Com.sendCmd(datas[0], datas[1:])
    Com.close()
    
    hacer_algo()