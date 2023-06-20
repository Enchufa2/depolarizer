import cv2 as cv
import numpy as np
import os, imageio, webptools
webptools.grant_permission()

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

    def __steps(self, pix_i, pix_o, res_i, res_o):
        map_x = []
        map_y = []
        pix_i = [_ / res_i for _ in pix_i]
        pix_o = [_ / res_o for _ in pix_o]
        
        smooth = lambda a, b : a**b/(a**b + (1-a)**b)
        
        for p in smooth(np.linspace(0, 1, 11), 3):
            map_x.append((pix_o[0] + (pix_i[0] - pix_o[0]) * p) * res_i)
            map_y.append((pix_o[1] + (pix_i[1] - pix_o[1]) * p) * res_i)

        return map_x, map_y

    def __map(self, map_x, map_y, file_o=None):
        if type(map_x) is list:
            return self.__map_list(map_x, map_y, file_o)

        # remaps self._img_i into img_o with two given functions
        img_o = cv.remap(self._img_i, map_x, map_y, cv.INTER_LINEAR)

        if file_o is None:
            return img_o

        cv.imwrite(file_o, img_o)

    def __map_list(self, map_x, map_y, file_o=None):
        img_o = []
        for x, y in zip(map_x, map_y):
            img_o.append(cv.remap(self._img_i, x, y, cv.INTER_LINEAR))

        if file_o is None:
            return img_o

        img_o = [cv.cvtColor(_, cv.COLOR_BGR2RGB) for _ in img_o]
        d = [0.5] + [0.1] * (len(img_o)-2) + [1]
        mirror = lambda x: x + x[-2:0:-1]
        imageio.mimwrite(file_o + ".gif", mirror(img_o), duration=mirror(d), loop=0)

        webptools.gifwebp(file_o + ".gif", file_o, option="-lossy -mt")
        os.remove(file_o + ".gif")

    def to_cartesian(self, file_o=None, axis=0, res_o=1000, steps=False):
        # generate the array of coordinates for the output image 
        seq = np.arange(res_o, dtype=np.float32)
        pix_o = np.meshgrid(seq, seq)
        
        # auxiliar variables
        res_i = self._img_i.shape[0]
        x_o, y_o = [_/res_o - 0.5 for _ in pix_o]

        r = np.sqrt(y_o**2 + x_o**2) * np.sqrt(2) 
        angle = np.arctan2(y_o, x_o) + axis * np.pi/180
        angle[angle < 0] += 2*np.pi
        
        # mapping
        map_x = res_i * angle / (2*np.pi)
        map_y = res_i * (-np.log(r)) / (2*np.pi)
        
        if steps:
            map_x, map_y = self.__steps((map_x, map_y), pix_o, res_i, res_o)

        return self.__map(map_x, map_y, file_o)

    def to_polar(self, file_o=None, axis=0, res_o=1000, steps=False):
        # generate the array of coordinates for the output image 
        seq = np.arange(res_o, dtype=np.float32)
        pix_o = np.meshgrid(seq, seq)
        
        # auxiliar variables
        res_i = self._img_i.shape[0]
        x_o, y_o = [_/res_o for _ in pix_o]

        r = np.exp(-2*np.pi * y_o) / np.sqrt(2)
        angle = 2*np.pi * (x_o - axis / 360)
        
        # mapping
        map_x = res_i * (r * np.cos(angle) + 0.5)
        map_y = res_i * (r * np.sin(angle) + 0.5)
        
        if steps:
            map_x, map_y = self.__steps((map_x, map_y), pix_o, res_i, res_o)

        return self.__map(map_x, map_y, file_o)

if __name__ == "__main__":
    import matplotlib.pyplot as plt
    dst = depolarizer("circles.jpg").to_polar(axis=-90)
    plt.imshow(cv.cvtColor(dst, cv.COLOR_BGR2RGB))
    plt.show()
