import cv2 as cv
import numpy as np

def depolarizer(img_i, res_o=1000):
    if type(img_i) == str:
        img_i = cv.imread(img_i, cv.IMREAD_COLOR)
    assert(img_i.shape[0] == img_i.shape[1])
  
    dim_i = img_i.shape[0]
    res_i = np.sqrt(2) * dim_i/2

    map_x = np.zeros((res_o, res_o), dtype=np.float32)
    map_y = np.zeros((res_o, res_o), dtype=np.float32)

    for i in range(res_o):
        for j in range(res_o):
            r = res_i * np.exp(2*np.pi * (i / res_o - 1))
            angle = 2*np.pi * j / res_o
            map_x[res_o - 1 - i, j] = r * np.cos(angle) + dim_i/2
            map_y[res_o - 1 - i, j] = r * np.sin(angle) + dim_i/2

    return cv.remap(img_i, map_x, map_y, cv.INTER_LINEAR)

if __name__ == "__main__":
    import matplotlib.pyplot as plt
    dst = depolarizer("circles.jpg")
    plt.imshow(cv.cvtColor(dst, cv.COLOR_BGR2RGB))
    plt.show()
