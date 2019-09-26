import cv2
import numpy as np
import imutils

class Detector:
    
    #hsv_azul = ((100,197,255),(88,120,180))
    #hsv_verde = ( (69,244,255), (42,42,154))
    
    hsv_verde = ((49,100,130),(102,255,255))    
    hsv_azul  = ((111,79,130),(149,208,255))
    hsv_rojo  = ((162,153,61),(193,255,178))
    paint_result = False
    
    object = np.array([[0,0,0],[5,0,0],[0,7,0],[5,7,0]], dtype=np.float64)
    
    is_tester_initialized = False
    
    dist =np.array([[ -3.18719375e-01,2.83329630e+00 ,  3.21768674e-03,   9.56285595e-03,-9.96029344e+00]],dtype="double")
   
    Cam_Matrix = np.array([[876.84,0      ,220.74],
                       [0     ,862.826 ,316.71],
                       [0     ,0      ,  1]],dtype=np.float64)
    # 
    modo = "normal"
    
    def __init__(self):
        self.Inv_Cam_Matrix = np.linalg.inv(self.Cam_Matrix)
        pass
       
    def setMode(self, modo):
        self.modo = modo
       
    # Main program loop
    def Loop(self, img):
        if self.modo == "normal":
            self.Detect(img)
        elif self.modo == "test":
            self.Tester(img)
            
            
    def calculate_XYZ(self,u,v, rvec, tvec):
        """
        scalingfactor = 1                    
        #Solve: From Image Pixels, find World Points
        uv_1=np.array([[u,v,1]], dtype=np.float32)
        uv_1=uv_1.T
        suv_1=scalingfactor*uv_1
        xyz_c=self.Inv_Cam_Matrix.dot(suv_1)
        xyz_c=xyz_c-tvec
        R_mat,_ = cv2.Rodrigues(rvec)
        Inv_R_mat = np.linalg.inv(R_mat)
        XYZ=Inv_R_mat.dot(xyz_c)
        """
        
        uv_1=np.array([[u,v,1]], dtype=np.float32).T
        R_mat,_ = cv2.Rodrigues(rvec)
        Inv_R_mat = np.linalg.inv(R_mat)
        leftSide = Inv_R_mat.dot(self.Inv_Cam_Matrix.dot(uv_1))
        rightSide = Inv_R_mat.dot(tvec)
        s = 0 + rightSide[2][0]/leftSide[2][0]
        #s = 1
        XYZ = Inv_R_mat.dot( s * self.Inv_Cam_Matrix.dot(uv_1) - tvec)
        """
        print("uv: " + str(uv_1))
        print("Inv_cam: " + str(self.Inv_Cam_Matrix))
        print("R_mat: " + str(R_mat))
        print("Inv_R_mat " + str(Inv_R_mat))
        print("left " + str(leftSide))
        print("right " + str(rightSide))
        """
        return XYZ            
        
        
        # Detect the items in the img
    def Detect(self, img):
        img_hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV) 
        mask_azul = cv2.inRange(img_hsv, self.hsv_azul[0], self.hsv_azul[1])
        mask_verde = cv2.inRange(img_hsv, self.hsv_verde[0], self.hsv_verde[1])
        mask_rojo = cv2.inRange(img_hsv, self.hsv_rojo[0], self.hsv_rojo[1])
        
        mask_azul  = self.FilterMask(mask_azul)
        mask_verde = self.FilterMask(mask_verde)
        mask_rojo  = self.FilterMask(mask_rojo)
        
        azul_ellipses = self.getEllipse(mask_azul)
        verde_ellipses = self.getEllipse(mask_verde)
        rojo_ellipses = self.getEllipse(mask_rojo)
        
        centros = []
        centros_a = []
        centros_v = []
        if len(azul_ellipses) > 0:
            for (cAzul, eAzul) in azul_ellipses:
                if not cAzul == None:
                    centros.append([cAzul[0], cAzul[1]])
                    centros_a.append(cAzul)
                    if not cAzul == -1:
                        cv2.ellipse(img, eAzul, (255,0,0), 2)
                        cv2.circle(img, cAzul, 5, (0, 0, 255), -1)

        if len(verde_ellipses) > 0:
            for (cVerde, eVerde) in verde_ellipses:
                if not cVerde == None:
                    centros.append([cVerde[0], cVerde[1]])
                    centros_v.append(cVerde)
                    if not cVerde == -1:
                        cv2.ellipse(img, eVerde, (0,255,0), 2)
                        cv2.circle(img, cVerde, 5, (0, 0, 255), -1)
            
        objetivo = None
        if len(rojo_ellipses) == 1:        
            objetivo = rojo_ellipses[0]
            cv2.circle(img, objetivo[0], 5, (255, 0, 0), -1)
       
        if len(centros) == 4 and len(centros_a) == 2 and len(centros_v) == 2:
            
            centros_ordenados = []
            
            
            cv2.line(img, centros_v[0], centros_v[1], (0,255,0),2)
            v = np.array(centros_v[1]) - np.array(centros_v[0])
            centro_linea_v = (centros_v[0] + v/2).astype(int)
            
            cv2.line(img, centros_a[0], centros_a[1], (0,255,0),2)
            v = np.array(centros_a[1]) - np.array(centros_a[0])
            centro_linea_a = (centros_a[0] + v/2).astype(int)

            if centro_linea_v[1] < centro_linea_a[1]:
                if centros_a[0][0] < centros_a[1][0]:
                    centros_ordenados.append(centros_a[0])
                    centros_ordenados.append(centros_a[1])
                else:
                    centros_ordenados.append(centros_a[1])
                    centros_ordenados.append(centros_a[0])
                    
                if centros_v[0][0] < centros_v[1][0]:
                    centros_ordenados.append(centros_v[0])
                    centros_ordenados.append(centros_v[1])
                else:
                    centros_ordenados.append(centros_v[1])
                    centros_ordenados.append(centros_v[0])
            """
            v_orto = np.array([v[1], -v[0]])
            cv2.line(img, 
                     (int(centros_v[0][0] + v[0]/2), int(centros_v[0][1] + v[1]/2)), 
                     (int(centros_v[0][0] + v[0]/2 + v_orto[0]), int(centros_v[0][1] + v[1]/2 + v_orto[1])),
                     (255,0,0),2)
            """
            ret, rvec, tvec = cv2.solvePnP(self.object,
                         np.array(centros_ordenados, dtype=np.float64),
                         self.Cam_Matrix,
                         self.dist)
            #print(tvec)
            #print(rvec)
            if not objetivo == None:
                print(objetivo)
                print(self.calculate_XYZ(objetivo[0][0], objetivo[0][1], rvec, tvec))
        cv2.imshow("Detecciones", img)
    
    # Filter the mask
    def FilterMask(self, mask):
        kernel = np.ones((5,5), np.uint8)
        img_dilation = cv2.dilate(mask, kernel, iterations=3)
        img_erosion = cv2.erode(img_dilation, kernel, iterations=3)
        return img_erosion

        
    def Tester(self, img):
        if self.is_tester_initialized == False:
            cv2.namedWindow('image')
            cv2.createTrackbar('HH','image',0,255,self.nothing)
            cv2.createTrackbar('HL','image',0,255,self.nothing)
            cv2.createTrackbar('S_H','image',0,255,self.nothing)
            cv2.createTrackbar('S_L','image',0,255,self.nothing)
            cv2.createTrackbar('VH','image',0,255,self.nothing)
            cv2.createTrackbar('VL','image',0,255,self.nothing)
            cv2.createTrackbar('Focus','image',0,255,self.nothing)
            self.is_tester_initialized = True
        
        img_hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV) 
        
        hh = cv2.getTrackbarPos('HH','image')
        hl = cv2.getTrackbarPos('HL','image')
        sh = cv2.getTrackbarPos('S_H','image')
        sl = cv2.getTrackbarPos('S_L','image')
        vh = cv2.getTrackbarPos('VH','image')
        vl = cv2.getTrackbarPos('VL','image')
        
        lower_limit = np.array([hl,sl,vl], dtype=np.uint8)
        upper_limit = np.array([hh,sh,vh], dtype=np.uint8)  
        
        mask = cv2.inRange(img_hsv, lower_limit, upper_limit)
        
        cv2.imshow("Test mask", mask)
        
    def setPaintResult(self, value):
        self.paint_result = value
        
    def getDetections(self):
        pass
        
    def nothing(self, x):
        pass
        
    def getEllipse(self, mask):
        #key = cv2.waitKey()
        M = cv2.moments(mask)
        cnts = cv2.findContours(mask.copy(), cv2.RETR_EXTERNAL,
            cv2.CHAIN_APPROX_SIMPLE)
        cnts = imutils.grab_contours(cnts)
        center = None
        res = []
        if len(cnts) > 0:
            for c in cnts:
            #c = max(cnts, key=cv2.contourArea)
                ((x, y), radius) = cv2.minEnclosingCircle(c)
                try:
                    ellip = cv2.fitEllipse(c)
                except:
                    pass
                    #return (-1, -1)
                else: 
                    M = cv2.moments(c)
                    if  M["m00"] != 0:
                        center = (int(M["m10"] / M["m00"]), int(M["m01"] / M["m00"]))
                    else:
                        #return (-1, -1)
                        pass
                    if radius > 1:
                        res.append( (center, ellip) )
                    else:
                        pass
                        #return (-1, -1)
        return res
            #return (-1, -1)