import serial
import struct
import time

TEST_LED = 0
SET_DIRECTION = 1
SET_SPEED = 2

def getCmd(tag, data):
    return struct.pack("BB%sB" % len(data), tag, len(data), *data)
    
    

ser = serial.Serial('\\COM5', 19200)

time.sleep(2)
while not ser.is_open:
    pass
    
for i in range(10):
    ser.write(getCmd(TEST_LED, [1]))

print(getCmd(TEST_LED, [0]))
ser.write(getCmd(TEST_LED, [0]))

ser.close()