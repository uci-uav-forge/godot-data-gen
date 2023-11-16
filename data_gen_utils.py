import cv2
import numpy as np
import os

def get_polygon(shape_img: cv2.Mat) -> np.ndarray:
    '''
    Returns the enclosing polygon of the shape in the image. The polygon is a list of points, each point being a list of 2 coordinates.
    '''
    im = cv2.cvtColor(shape_img, cv2.COLOR_BGR2GRAY)
    im = cv2.threshold(im, 253, 255, cv2.THRESH_BINARY)[1]
    contours, hierarchy = cv2.findContours(im, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if len(contours)==0:
        return np.array([]) 
    if len(contours)>1:
        if os.getenv("VERBOSE") is not None:
            print("Warning: multiple contours found")
        # combine contours and return convex hull
        contours = np.concatenate([c.reshape(-1,2) for c in contours])
        contours = cv2.convexHull(contours)
        return contours.reshape(-1,2)
    return np.array(contours[0]).reshape(-1,2)