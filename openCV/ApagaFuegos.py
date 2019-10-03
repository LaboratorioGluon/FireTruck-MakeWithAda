import cv2
import numpy as np
import imutils

from Detector import Detector


webcam = cv2.VideoCapture(0)
webcam.set(cv2.CAP_PROP_AUTO_EXPOSURE, True)
detect = Detector()

while True:

    check, frame = webcam.read()
    if frame is None:
        break
        
        
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