import numpy as np
import cv2

grid_X = 6
grid_Y = 9

# termination criteria
criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)

# prepare object points, like (0,0,0), (1,0,0), (2,0,0) ....,(6,5,0)
objp = np.zeros((grid_X*grid_Y,3), np.float32)
objp[:,:2] = np.mgrid[0:grid_Y,0:grid_X].T.reshape(-1,2)
objp = objp*20
print(objp)
# Arrays to store object points and image points from all the images.
objpoints = [] # 3d point in real world space
imgpoints = [] # 2d points in image plane.


webcam = cv2.VideoCapture(0)

while True:
    #img = cv2.imread(fname)
    check, img = webcam.read()
    gray = cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)
    cv2.imshow("captura", gray)
    # Find the chess board corners
    ret, corners = cv2.findChessboardCorners(gray, (grid_Y,grid_X),None)

    # If found, add object points, image points (after refining them)
    key = cv2.waitKey(1)
    if ret == True and key == ord('t'):
        objpoints.append(objp)

        corners2 = cv2.cornerSubPix(gray,corners,(11,11),(-1,-1),criteria)
        imgpoints.append(corners2)

        # Draw and display the corners
        img = cv2.drawChessboardCorners(img, (grid_Y,grid_X), corners2,ret)
        cv2.imshow('img',img)
        cv2.waitKey(500)

    key = cv2.waitKey(1)
    if key == ord('c'):
        ret, mtx, dist, rvecs, tvecs = cv2.calibrateCamera(objpoints, imgpoints, gray.shape[::-1],None,None)
        print("MTX: " + str(mtx))
        print("DIST: " + str(dist))
        print("RVECS: " + str(rvecs))
        print("TVECS: " + str(tvecs)) 
    key = cv2.waitKey(1)
    if key == ord('q'):
        print("Turning off camera.")
        webcam.release()
        cv2.destroyAllWindows()
        break