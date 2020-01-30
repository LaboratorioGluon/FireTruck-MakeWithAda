import cv2
import numpy as np
import imutils
import Comms
from Detector import Detector


webcam = cv2.VideoCapture(0)

# Configure camera parameters
webcam.set(cv2.CAP_PROP_AUTO_EXPOSURE, 0)   
webcam.set(cv2.CAP_PROP_EXPOSURE, -0.5) 

# Create the detector
detect = Detector()
detect.setMode("normal")
cycles = 0

#Main loop
while True:

    # Read the frame
    check, frame = webcam.read()
    if frame is None:
        break
        
    # Show the captured image
    cv2.imshow("captura", frame)
    
    # Run the main loop of the detector
    # This will run one algortihm or another
    # dependin on its mode
    detect.Loop(frame)
    
    # Read the keys to change the mode,
    # capture background, send command to the truck
    # or quit
    key = cv2.waitKey(1)
    if key == ord('q'):
        print("Turning off camera.")
        webcam.release()
        cv2.destroyAllWindows()
        break
    elif key == ord('t'):
        detect.setMode("test")
    elif key == ord('n'):
        detect.setMode("normal")
    elif key == ord('s'):
        detect.setMode("simple")
    elif key == ord('b'):
        detect.setBack(frame)
    elif key == ord('m'):
        detect.setMove()
    elif key == ord('p'):
        detect.setPump()
    