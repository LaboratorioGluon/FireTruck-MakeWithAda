import cv2
import numpy as np
import imutils
import Comms
from Detector import Detector


webcam = cv2.VideoCapture(0)
webcam.set(cv2.CAP_PROP_AUTO_EXPOSURE, True)
detect = Detector()
detect.setMode("simple")
cycles = 0
while True:

    check, frame = webcam.read()
    if frame is None:
        break
    webcam.set(cv2.CAP_PROP_AUTO_EXPOSURE, 0.25)
        
    cv2.imshow("captura", frame)
    
    detect.Loop(frame)
    
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
    