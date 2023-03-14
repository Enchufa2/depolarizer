import cv2 as cv
import numpy as np

def width(file_i):
    return cv.imread(file_i).shape[1]

class depolarizer:
    def __init__(self, file_i, crop=None):
        # receives the input file, crops it and saves it as an attribute 
        self._img_i = cv.imread(file_i, cv.IMREAD_COLOR)
        if crop is not None:
            x = round(crop["x"]) + np.arange(round(crop["width"]))
            y = round(crop["y"]) + np.arange(round(crop["height"]))
            self._img_i = self._img_i[y[:, None], x]

        assert(self._img_i.shape[0] == self._img_i.shape[1])

    def __map(self, map_x, map_y, file_o=None):
        # remaps self._img_i into img_o with two given functions 
        img_o = cv.remap(self._img_i, map_x, map_y, cv.INTER_LINEAR)

        if file_o is None:
            return img_o
        cv.imwrite(file_o, img_o)

    def to_cartesian(self, file_o=None, axis=0, res_o=1000):
        # generate the array of coordinates for the output image 
        seq = np.arange(res_o, dtype=np.float32)
        pix_o = np.meshgrid(seq, seq)
        
        # auxiliar variables
        pix_o[0] -= res_o/2 
        pix_o[1] -= res_o/2
        res_i = self._img_i.shape[0]
        diag_o = np.sqrt(2) * res_o/2
        r = np.log ( np.sqrt(pix_o[1]**2 + pix_o[0]**2) / diag_o ) + 2*np.pi 
        angle = np.arctan2(pix_o[1], pix_o[0]) + axis*np.pi/180
        angle[angle < 0] += 2*np.pi
        
        # mapping
        map_x = res_i/(2*np.pi) * angle
        map_y = res_i - res_i/(2*np.pi) * r
        
        return self.__map(map_x, map_y, file_o)

    def to_polar(self, file_o=None, axis=0, res_o=1000):
        # generate the array of coordinates for the output image 
        seq = np.arange(res_o, dtype=np.float32)
        pix_o = np.meshgrid(seq, np.flip(seq))
        
        # auxiliar variables
        res_i = self._img_i.shape[0]
        diag_i = np.sqrt(2) * res_i/2
        r = diag_i * np.exp(2*np.pi * (pix_o[1] / res_o - 1))
        angle = 2*np.pi * ( pix_o[0] / res_o  - axis / 360)
        
        # mapping
        map_x = r * np.cos(angle) + res_i/2
        map_y = r * np.sin(angle) + res_i/2
        
        return self.__map(map_x, map_y, file_o)

if __name__ == "__main__":
    import matplotlib.pyplot as plt
    dst = depolarizer("circles_processed.jpg").to_cartesian()
    plt.imshow(cv.cvtColor(dst, cv.COLOR_BGR2RGB))
    plt.show()
