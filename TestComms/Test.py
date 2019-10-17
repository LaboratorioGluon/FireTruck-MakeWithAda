import keyboard  # using module keyboard
import serial
import struct

TEST_LED = 0
SET_DIRECTION = 1
SET_SPEED = 2

def getCmd(tag, data):
    return struct.pack("BB%sB" % len(data), tag, len(data), *data)
    

ser = serial.Serial('\\COM5', 9600) 
last_cmd = False
def sendCommand(e):
    global ser, last_cmd
    if keyboard.is_pressed('a') and  not last_cmd:
        ser.write(getCmd(TEST_LED, [0]))
        last_cmd = True
    elif not keyboard.is_pressed('a'):
        ser.write(getCmd(TEST_LED, [1]))
        last_cmd = False
    else:
        pass
        

    
last_move = False
def moveCommand(e):
    global ser, last_move
    if e.name=='t' and not last_move:
        last_move = True
        ser.write(b't\3')
        print("Fwd!")
    elif e.name == 'g' and not last_move:
        last_move = True
        ser.write(b't\0')
        print("Fwd2!")
    else:
        last_move = False
        
keyboard.hook_key('a', sendCommand)
#keyboard.hook_key('t', moveCommand)
#keyboard.hook_key('g', moveCommand)
while True:  # making a loop
    try:  # used try so that if user pressed other than the given key error will not be shown
        
        if ser.inWaiting() > 0:
            tot = ser.read(1)
            while ser.inWaiting():
                tot = tot + ser.read(1)
            print(tot)
        if keyboard.is_pressed('q'):  # if key 'q' is pressed 
            print('You Pressed A Key!')
            break  # finishing the loop
        #if keyboard.is_pressed('a'):
        #    sendCommand(0)
        else:
            pass
    except:
        print("Exception!")
        break  # if user pressed a key other than the given key the loop will break
ser.close()