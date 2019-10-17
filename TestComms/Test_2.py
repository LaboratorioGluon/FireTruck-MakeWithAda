import serial
import struct

TEST_LED = 0
SET_DIRECTION = 1
SET_SPEED = 2

def getCmd(tag, data):
    return struct.pack("BB%sB" % len(data), tag, len(data), *data)
    
    

ser = serial.Serial('\\COM5', 19200)


datain = input("Cmd: ").replace("\n","").split(" ")
print(datain)

while not "q" in datain[0]:
    ser.write(getCmd(int(datain[0]), [int(datain[1])]))
    datain = input("Cmd: ").replace("\n","").split(" ")
    print(datain)


ser.close()