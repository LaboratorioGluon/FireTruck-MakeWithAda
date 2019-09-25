import cv2
import numpy as np
import imutils

def nothing(x):
    pass

webcam = cv2.VideoCapture(0)


print("Empezando bucle")

cv2.namedWindow('image')
cv2.createTrackbar('HH','image',0,255,nothing)
cv2.createTrackbar('HL','image',0,255,nothing)
cv2.createTrackbar('S_H','image',0,255,nothing)
cv2.createTrackbar('S_L','image',0,255,nothing)
cv2.createTrackbar('VH','image',0,255,nothing)
cv2.createTrackbar('VL','image',0,255,nothing)
cv2.createTrackbar('Focus','image',0,255,nothing)


cv2.setTrackbarPos('HH','image',255)
cv2.setTrackbarPos('HL','image',130)
cv2.setTrackbarPos('S_H','image',244)
cv2.setTrackbarPos('S_L','image',144)
cv2.setTrackbarPos('V','image',0)
cv2.setTrackbarPos('VL','image',255)
kernel = np.ones((5,5), np.uint8)


hsv_azul_high = (100,197,255)
hsv_azul_low = (88,120,180)
hsv_verde = ( (69,244,255), (42,42,154))

dist =np.array([[ -3.18719375e-01,2.83329630e+00 ,  3.21768674e-03,   9.56285595e-03,
   -9.96029344e+00]],dtype="double")
Cam_Matrix = np.array([[876.84,0      ,220.74],
                       [0     ,862.826 ,316.71],
                       [0     ,0      ,  1]],dtype="double")

Inv_Cam_Matrix = np.linalg.inv(Cam_Matrix)

angle = -45
rcos = np.cos(angle*np.pi/180.0)
rsin = np.sin(angle*np.pi/180.0)
R_mat = np.array([[1, 0, 0],
                  [0,  rcos, -rsin],
                  [0,  rsin,  rcos]])
                  
Inv_R_mat = np.linalg.inv(R_mat)


def calculate_M(u,v):
    global Inv_Cam_Matrix
    uv_1 = np.array([[u,v,1]], dtype=np.float32)
    uv_1 = uv_1.T
    xyz_c=Inv_Cam_Matrix.dot(uv_1)
    print(xyz_c)
    return xyz_c
    
def calculate_XYZ(u,v):
    global Inv_Cam_Matrix, Inv_R_mat
    """
    print("Inicio----------------")
    print("INV_CAM:" + str(Inv_Cam_Matrix))
    print("Inv_R_mat:" + str(Inv_R_mat))
    """
    tvec1 = np.array([[0,0,50]]).T
    scalingfactor = 1                    
    #Solve: From Image Pixels, find World Points
    uv_1=np.array([[u,v,1]], dtype=np.float32)
    print("uv_1: " + str(uv_1))
    uv_1=uv_1.T
    suv_1=scalingfactor*uv_1
    """print("suv_1: " + str(suv_1))"""
    xyz_c=Inv_Cam_Matrix.dot(suv_1)
    #xyz_c=suv_1.dot(Inv_Cam_Matrix)
   
    xyz_c=xyz_c-tvec1
    #print("xyz_c: " + str(xyz_c))
    XYZ=Inv_R_mat.dot(xyz_c)
    #XYZ=xyz_c.dot(Inv_R_mat)
    #print("XYZ: " + str(XYZ))
    #print("------------------------")
    return XYZ
                       
def getEllipse(mask):
    
    #key = cv2.waitKey()
    M = cv2.moments(mask)
    cnts = cv2.findContours(mask.copy(), cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE)
    cnts = imutils.grab_contours(cnts)
    center = None
    if len(cnts) > 0:
        c = max(cnts, key=cv2.contourArea)
        ((x, y), radius) = cv2.minEnclosingCircle(c)
        try:
            ellip = cv2.fitEllipse(c)
        except:
            return (-1, -1)
        else: 
            M = cv2.moments(c)
            center = (int(M["m10"] / M["m00"]), int(M["m01"] / M["m00"]))
            if radius > 10:
               return ( center, ellip)
            else:
               return (-1, -1)
               
               
def Filtrar(mask):
    img_dilation = cv2.dilate(mask, kernel, iterations=3)
    img_erosion = cv2.erode(img_dilation, kernel, iterations=3)
    img_after = img_erosion
    return img_after
    
while True:
     
    check, frame = webcam.read()
    if frame is None:
        break
        
        
    
    hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV) 
    hsv = cv2.GaussianBlur(hsv, (5,5),cv2.BORDER_DEFAULT)
                      
    hh = cv2.getTrackbarPos('HH','image')
    hl = cv2.getTrackbarPos('HL','image')
    sh = cv2.getTrackbarPos('S_H','image')
    sl = cv2.getTrackbarPos('S_L','image')
    vh = cv2.getTrackbarPos('VH','image')
    vl = cv2.getTrackbarPos('VL','image')
    
    lower_white = np.array([hl,sl,vl], dtype=np.uint8)
    upper_white = np.array([hh,sh,vh], dtype=np.uint8)
    
    mask = cv2.inRange(hsv, lower_white, upper_white)
    mask_azul = cv2.inRange(hsv, hsv_azul_low, hsv_azul_high)
    mask_verde = cv2.inRange(hsv, hsv_verde[1], hsv_verde[0])
    mask_azul  = Filtrar(mask_azul)
    cv2.imshow("Debug", mask)
    mask_verde = Filtrar(mask_verde)
    
    try:
    #if True:
        (cAzul, eAzul) = getEllipse(mask_azul)
        (cVerde, eVerde) = getEllipse(mask_verde)

        if not cAzul == -1:
            cv2.ellipse(frame, eAzul, (255,0,0), 2)
            cv2.circle(frame, cAzul, 5, (0, 0, 255), -1)
        
        if not cVerde == -1:
            cv2.ellipse(frame, eVerde, (0,255,0), 2)
            cv2.circle(frame, cVerde, 5, (0, 0, 255), -1)
            
        cv2.line(frame, cAzul, cVerde, (0,0,255), 2)
        #print(str(cAzul))
        print(type(np.array([(0,0,0),(90,0,0)], dtype="double")))
        """
        ret,rv, tv = cv2.solvePnP(np.array([(0,0,0),(90,0,0)], dtype="double"), 
                                  np.array([[cAzul[0], cAzul[1]], [cVerde[0], cVerde[1]]], dtype="double"), 
                                  Cam_Matrix, 
                                  dist,
                                  rvec = np.array(  [[1,0,0], 
                                                     [0, np.cos(-45*np.pi/180), -np.sin(-45*np.pi/180)],
                                                    [0, np.sin(-45*np.pi/180),  np.cos(-45*np.pi/180)]], dtype="double"),
                                  tvec = np.array([0,0,50]),
                                  useExtrinsicGuess  = True
                                  )
        """
        XYZ_azul = calculate_XYZ(cAzul[0], cAzul[1])
        m_azul = calculate_M(cAzul[0], cAzul[1])
        m_verde = calculate_M(cVerde[0], cVerde[1])  
        XYZ_verde = calculate_XYZ(cVerde[0], cVerde[1])
        
        dy = m_verde[2] - m_azul[2]
        dx = m_verde[0] - m_azul[0]
        d = 90
        print("C: " + str( np.sqrt(dy*dy / (d*d - dx*dx))))
        
        # print(str(np.linalg.norm((XYZ_verde-XYZ_azul))))
        
        cv2.putText(frame, str(cv2.norm(cAzul, cVerde)), (10,30), cv2.FONT_HERSHEY_SIMPLEX,1 , (0,0,0), 2, cv2.LINE_AA)
    except Exception as e: print(e)
    
    """
    if False:
        img_erosion = cv2.erode(mask, kernel, iterations=2)
        img_dilation = cv2.dilate(img_erosion, kernel, iterations=2)
        img_after = img_dilation
    else:
        img_dilation = cv2.dilate(mask, kernel, iterations=3)
        img_erosion = cv2.erode(img_dilation, kernel, iterations=3)
        img_after = img_erosion
    """
    
    

    #result = cv2.bitwise_and(frame, frame, mask = mask_azul) 
    result = frame
    #result = cv2.bitwise_and(result, result, mask = mask_verde) 
    
    
    """
    M = cv2.moments(img_after)
    cnts = cv2.findContours(img_after.copy(), cv2.RETR_EXTERNAL,
        cv2.CHAIN_APPROX_SIMPLE)
    cnts = imutils.grab_contours(cnts)
    center = None
    if len(cnts) > 0:
        c = max(cnts, key=cv2.contourArea)
        ((x, y), radius) = cv2.minEnclosingCircle(c)
        try:
            ellip = cv2.fitEllipse(c)
        except:
            pass
        else: 
            M = cv2.moments(c)
            center = (int(M["m10"] / M["m00"]), int(M["m01"] / M["m00"]))
            if radius > 10:
                cv2.ellipse(result, ellip, (0,255,255), 2)
                #cv2.circle(result, (int(x), int(y)), int(radius),
                #    (0, 255, 255), 2)
                cv2.circle(result, center, 5, (0, 0, 255), -1)
    """
    
    
     
    cv2.imshow("Capturing", frame)
    #cv2.imshow("Dilation", img_erosion)
    cv2.imshow("Result", result)
    
    key = cv2.waitKey(1)
    if key == ord('q'):
        print("Turning off camera.")
        webcam.release()
        cv2.destroyAllWindows()
        break