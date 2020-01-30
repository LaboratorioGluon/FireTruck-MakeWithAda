import cv2
import numpy as np
import imutils
import Comms
import math

import traceback

class Detector:

    # Color ranges for each 
    hsv_verde = ((49,42,204),(93,255,255))
    hsv_azul  = ((97,104,204),(130,255,255))
    hsv_target  = ((20,107,83),(62,255,255))
    paint_result = False
    
    # Definition of the pattern
    object = np.array([[0,0,17],[8,0,17],[0,9,17],[8,9,17]], dtype=np.float64)
    
    is_tester_initialized = False
    
    
    #######################
    ## Camera parameters ##
    #######################
    dist =np.array([[ -3.18719375e-01,2.83329630e+00 ,  3.21768674e-03,   9.56285595e-03,-9.96029344e+00]],dtype="double")
   
    Cam_Matrix = np.array([[876.84,0      ,220.74],
                       [0     ,862.826 ,316.71],
                       [0     ,0      ,  1]],dtype=np.float64)
    
    
    #########################
    ## Internal variables  ##
    #########################
    modo = "normal"
    mover = False
    back = None
    backSub = None
    backmask = None
    hasBack = False
    move = False
    pump = False
    
    last4X = [0]
    last4Y = [0]
    
    
    
            
    def __init__(self):
        self.last4X = [0]
        self.last4Y = [0]
        self.comm = Comms.Comms()
        self.comm.setServos(0,0)
        self.Inv_Cam_Matrix = np.linalg.inv(self.Cam_Matrix)

        pass
       
    # Method to activate the move commands
    def setMove(self):
        if self.move == True:
            self.move = False   
            self.comm.setDirection(0)            
        else:
            self.move = True
            
    
    # Change the modo of the Detecto
    def setMode(self, modo):
        self.modo = modo
        
    # Manually activate the water pump
    def setPump(self):
        if pump == False:
            pump = True
        else:
            pump = False
       
    # Main program loop
    def Loop(self, img):
        if self.modo == "normal":
            self.Detect(img)
        elif self.modo == "test":
            self.Tester(img)
        elif self.modo == "simple":
            self.Simple(img)
            
    # Update the background image
    def setBack(self, backImg):
        self.back = backImg
        self.hasBack = True
            
    # Some hardcore algorithm to calculate the position
    # of the car based on the detections
    def calculate_XYZ(self,u,v, rvec, tvec):
        uv_1=np.array([[u,v,1]], dtype=np.float32).T
        R_mat,_ = cv2.Rodrigues(rvec)
        Inv_R_mat = np.linalg.inv(R_mat)
        leftSide = Inv_R_mat.dot(self.Inv_Cam_Matrix.dot(uv_1))
        rightSide = Inv_R_mat.dot(tvec)
        s = 0 + rightSide[2][0]/leftSide[2][0]
        XYZ = Inv_R_mat.dot( s * self.Inv_Cam_Matrix.dot(uv_1) - tvec)
        
        return XYZ            
        
        
    # Detect the items in the img
    def Detect(self, img):
        height = img.shape[0]
        width = img.shape[1]
        
        # We have to wait for a background to 
        # see what is different.
        if not self.hasBack:
            cv2.imshow("Detecciones",img)
            
            return
        else:
            # First apply some filters to clean the noise
            img_ = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            back_ = cv2.cvtColor(self.back, cv2.COLOR_BGR2GRAY)
            diff = cv2.absdiff(img_,back_);
            ret, thresh1 = cv2.threshold(diff, 15, 255, cv2.THRESH_BINARY) 
            
            # Then dilate/erode mask to make sure the truck is inside mask
            cv2.imshow("Resta1",thresh1)
            thresh1 = self.FilterMask(thresh1)
            kernel = np.ones((10,10), np.uint8)
            img_dilation = cv2.dilate(thresh1, kernel, iterations=4)
            img_erosion = cv2.erode(img_dilation, kernel, iterations=2)
            cv2.imshow("Resta",img_erosion)
            
            # Calculate the area of the mask areas
            # We know the big one will be the truck
            # While the small one will be the target
            kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(9,9))
            dilated = cv2.dilate(img_erosion.copy(), kernel)
            cnts = cv2.findContours(dilated, cv2.RETR_EXTERNAL,
                cv2.CHAIN_APPROX_SIMPLE)[-2]
                
            mask_target = np.zeros(shape=[height, width, 1], dtype=np.uint8)
            mask_truck = np.zeros(shape=[height, width, 1], dtype=np.uint8)
            if len(cnts) >= 2:
                cntsSorted = sorted(cnts, key=lambda x: cv2.contourArea(x), reverse=True)
                cv2.drawContours(mask_truck, [cntsSorted[0]], -1, 255, -1)
                cv2.drawContours(mask_target, [cntsSorted[1]], -1, 255, -1) 
        
        # The the masked area of the image for the truck and the target
        img_masked_truck = cv2.bitwise_and(img, img, mask=mask_truck)
        img_masked_target= cv2.bitwise_and(img, img, mask=mask_target)
        
        cv2.imshow("mask_target", img_masked_target)
        cv2.imshow("mask_truck", img_masked_truck)
        img_hsv_truck = cv2.cvtColor(img_masked_truck, cv2.COLOR_BGR2HSV) 
        img_hsv_target = cv2.cvtColor(img_masked_target, cv2.COLOR_BGR2HSV) 
        
        # Apply some filtering to smooth the image and get more consistent data
        img_hsv_truck = cv2.GaussianBlur(img_hsv_truck, (13, 13), 0)
        img_hsv_target = cv2.GaussianBlur(img_hsv_target, (13, 13), 0)
        mask_azul = cv2.inRange(img_hsv_truck, self.hsv_azul[0], self.hsv_azul[1])
        mask_verde = cv2.inRange(img_hsv_truck, self.hsv_verde[0], self.hsv_verde[1])
        mask_target = cv2.inRange(img_hsv_target, self.hsv_target[0], self.hsv_target[1])
        

        cv2.imshow("mascaraV", mask_verde)
        cv2.imshow("mascaraA", mask_azul)
        cv2.imshow("mascaraT", mask_target)
        azul_ellipses = self.getEllipse(mask_azul)
        verde_ellipses = self.getEllipse(mask_verde)
        target_ellipses = self.getEllipse(mask_target)
        
        centros = []
        centros_a = []
        centros_v = []
        
        
        # If we detect the blue colors, store the centers
        if len(azul_ellipses) > 0:
            for (cAzul, eAzul) in azul_ellipses:
                if not cAzul == None:
                    centros.append([cAzul[0], cAzul[1]])
                    centros_a.append(cAzul)
                    if not cAzul == -1:
                        cv2.circle(img, cAzul, 5, (0, 0, 255), -1)

        # If we detect the green colors, store the centers   
        if len(verde_ellipses) > 0:
            for (cVerde, eVerde) in verde_ellipses:
                if not cVerde == None:
                    centros.append([cVerde[0], cVerde[1]])
                    centros_v.append(cVerde)
                    if not cVerde == -1:
                        cv2.circle(img, cVerde, 5, (0, 0, 255), -1)
            
            
        # Check that we found the target and store it
        objetivo = None
        if len(target_ellipses) == 1:        
            objetivo = target_ellipses[0]
            cv2.circle(img, objetivo[0], 5, (255, 0, 0), -1)
       
       
        # Check that we have the correct detections:
        # 4 circles, 2 blue and 2 greens
        # But now we have to order them to know where is the front
        # or back of the truck.
        # The process is:
        # 1st: join the same color with a line 
        # 2nd: get the line that goes by the middle of both groups
        if len(centros) == 4 and len(centros_a) == 2 and len(centros_v) == 2:
            
            centros_ordenados = []
            
            cv2.line(img, centros_v[0], centros_v[1], (0,255,0),2)
            v = np.array(centros_v[1]) - np.array(centros_v[0])
            centro_linea_v = (centros_v[0] + v/2).astype(int)
            
            cv2.line(img, centros_a[0], centros_a[1], (0,255,0),2)
            v = np.array(centros_a[1]) - np.array(centros_a[0])
            centro_linea_a = (centros_a[0] + v/2).astype(int)

            # Check which case it is 
            # If the Y coordinate of the green centers is less of the blue one
            # The truck is pointing to the top of the image 
            # We suppose this is always the case
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

            # Try to apply solvePNP to get the best estimation
            # of the pose of the truck
            try:
                ret, rvec, tvec = cv2.solvePnP(self.object,
                         np.array(centros_ordenados, dtype=np.float64),
                         self.Cam_Matrix,
                         self.dist)
                         
                # If we detected the target
                if not objetivo == None:
                    print("=====================")
                    print(objetivo)
                    print(self.calculate_XYZ(objetivo[0][0], objetivo[0][1], rvec, tvec))
                    
                    # We can get the X,Y,Z back from the target image
                    X,Y,Z = self.calculate_XYZ(objetivo[0][0], objetivo[0][1], rvec, tvec)

                    cv2.putText(img,str(X), (10,80), cv2.FONT_HERSHEY_SIMPLEX , 0.7, (255,255,255),2)    
                    dist = math.sqrt(X*X+ Y*Y + Z*Z)
                    cv2.putText(img,str(dist), (10,120), cv2.FONT_HERSHEY_SIMPLEX , 0.7, (255,255,255),2)    
                    
                    # If the move command is active, lets send the directions
                    if self.move:
                    
                        # Keep moving until the distance is less than 90 cm
                        if dist > 90:
                            if X > 10 :
                                self.comm.setDirection(2)
                                print("Derecha!!!!!!!!!!")
                                cv2.putText(img,"Derecha", (10,30), cv2.FONT_HERSHEY_SIMPLEX , 0.7, (255,255,255),2)    
                            elif X < -10 :
                                self.comm.setDirection(1)
                                print("Izquierda############")
                                cv2.putText(img,"IZquierda", (10,30), cv2.FONT_HERSHEY_SIMPLEX , 0.7, (255,255,255),2)     
                            elif dist > 100:
                                cv2.putText(img,"Recto", (10,30), cv2.FONT_HERSHEY_SIMPLEX , 0.7, (255,255,255),2)   
                                print("Recto!")
                                self.comm.setDirection(3)
                        else:
                            # If we are close enough, send the position of the target to the truck
                            cv2.putText(img,"Cerca", (10,30), cv2.FONT_HERSHEY_SIMPLEX , 0.7, (255,255,255),2)   
                            self.comm.setDirection(0)
                            ejeX = 0
                            ejeX = int(math.acos(Y/dist)*180/3.1415)
                            if X > 0:
                                ejeX = -ejeX
                            cv2.putText(img,"Servo" + str(ejeX), (10,160), cv2.FONT_HERSHEY_SIMPLEX , 0.7, (255,255,255),2)   
                            if ejeX > -20 and ejeX < 20:
                                print(ejeX)
                                self.comm.setTarget(ejeX, dist)
                        
            except Exception as e:
                print(e)
                traceback.print_exc()
                print("Exception!") 
                self.comm.setDirection(0)
                pass
                
        cv2.imshow("Detecciones", img)
    
    # Filter the mask
    def FilterMask(self, mask):
        kernel = np.ones((3,3), np.uint8)
        
        img_erosion = cv2.erode(mask, kernel, iterations=1)
        img_dilation = cv2.dilate(img_erosion, kernel, iterations=1)
        return img_erosion

    # Simple mode was made to test the movement of the truck 
    # with a simple setup
    # In this case we are controlling with just two marks
    def Simple(self, img):
        img_hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV) 
         
      
        mask_amarillo = cv2.inRange(img_hsv, (12,44,215), (49,255,255))
        mask_verde = cv2.inRange(img_hsv, (89,178,55), (100,250,97))
        mask_target = cv2.inRange(img_hsv, (157,98,119),(204,255,176))
        
        mask_amarillo  = self.FilterMask(mask_amarillo)
        mask_verde = self.FilterMask(mask_verde)
        mask_target = self.FilterMask(mask_target)
        
        try:
            M = cv2.moments(mask_amarillo)
            cnts = cv2.findContours(mask_amarillo.copy(), cv2.RETR_EXTERNAL,
                cv2.CHAIN_APPROX_SIMPLE)
            cnts = imutils.grab_contours(cnts)
            if len(cnts) > 0:
                c_am = max(cnts, key=cv2.contourArea)
                ((x,y), radius) = cv2.minEnclosingCircle(c_am)
                cv2.circle(img, (int(x),int(y)), 5, (0, 0, 255), -1)
            
            centro_amarillo = ( int(x), int(y) )
            
            
            M = cv2.moments(mask_verde)
            cnts = cv2.findContours(mask_verde.copy(), cv2.RETR_EXTERNAL,
                cv2.CHAIN_APPROX_SIMPLE)
            cnts = imutils.grab_contours(cnts)
            if len(cnts) > 0:
                c_ver = max(cnts, key=cv2.contourArea)
                ((x,y), radius) = cv2.minEnclosingCircle(c_ver)
                cv2.circle(img, (int(x),int(y)), 5, (0, 0, 255), -1)
            centro_verde = ( int(x), int(y) )
                
            M = cv2.moments(mask_target)
            cnts = cv2.findContours(mask_target.copy(), cv2.RETR_EXTERNAL,
                cv2.CHAIN_APPROX_SIMPLE)
            cnts = imutils.grab_contours(cnts)
            if len(cnts) > 0:
                c_roj = max(cnts, key=cv2.contourArea)
                ((x,y), radius) = cv2.minEnclosingCircle(c_roj)
                cv2.circle(img, (int(x),int(y)), 5, (0, 0, 255), -1)
            
            centro_rojo = ( int(x), int(y) )        
        except:
            pass
        try:
            v1 = ((centro_verde[0]-centro_amarillo[0]), (centro_verde[1]-centro_amarillo[1]))
            v2 = ((centro_rojo[0]-centro_amarillo[0]), (centro_rojo[1]-centro_amarillo[1]))
            vab = v1[0]*v2[0] + v1[1]*v2[1]
            mv1 = math.sqrt(v1[0]*v1[0] + v1[1]*v1[1])
            mv2 = math.sqrt(v2[0]*v2[0] + v2[1]*v2[1])
            mm = mv1*mv2
            angle = math.acos(vab/mm)
            angle = angle * 180 /3.1415
            a1 = self.CalcAngle(v1)* 180 /3.1415
            a2 = self.CalcAngle(v2)* 180 /3.1415
            print("angle :" + str(angle))
            print("v2 :" + str(a1))
            print("v1 :" + str(a2))
            if angle > 10:
                if a1 > a2:
                    self.comm.setDirection(2)
                    print("DRCHA")
                else:
                    self.comm.setDirection(1)
                    print("IZDA")
            else:
                self.comm.setDirection(0)
        except:
            self.comm.setDirection(0)
        
        cv2.imshow("Simple", img)
        
        
    def CalcAngle(self, vec):
        m = math.sqrt(vec[0]*vec[0] + vec[1]*vec[1])
        return math.acos(vec[0]/m)
        
        
    # The tester is used to get the HSV values for each characteristic
    # This popups a GUI with controls to adjust the HSV of the current filter
    # and see the results in real time.
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
        img_hsv = cv2.GaussianBlur(img_hsv, (13, 13), 0)
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
        
        
    # Get the position, and the best fitting ellipse for a mask
    def getEllipse(self, mask):
        #key = cv2.waitKey()
        M = cv2.moments(mask)
        cnts = cv2.findContours(mask.copy(), cv2.RETR_EXTERNAL,
            cv2.CHAIN_APPROX_SIMPLE)
        
            
        cnts = imutils.grab_contours(cnts)
        center = None
        res = []
        indice = 0
        
        if len(cnts) > 0:
            if len(cnts) == 1:
                indice = 1
            else:
                indice = 2
            cntsSorted = sorted(cnts, key=lambda x: cv2.contourArea(x), reverse=True)
            for c in cntsSorted[0:indice]:
            #c = max(cnts, key=cv2.contourArea)
                ((x, y), radius) = cv2.minEnclosingCircle(c)
                res.append(((int(x),int(y)), radius))
                continue
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

                    if radius > 0:
                        res.append( (center, ellip) )
                    else:
                        pass
                        #return (-1, -1)
        return res
            #return (-1, -1)