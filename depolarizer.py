import cv2 as cv
import numpy as np

def width(file_i):
    return cv.imread(file_i).shape[1]

def depolarizer(file_i, file_o=None, crop=None, res_o=1000):
    img_i = cv.imread(file_i, cv.IMREAD_COLOR)

    if crop is not None:
        x = round(crop["x"]) + np.arange(round(crop["width"]))
        y = round(crop["y"]) + np.arange(round(crop["height"]))
        img_i = img_i[y[:, None], x]
    assert(img_i.shape[0] == img_i.shape[1])

    dim_i = img_i.shape[0]
    res_i = np.sqrt(2) * dim_i/2

    seq = np.arange(res_o, dtype=np.float32)
    pix_o = np.meshgrid(seq, np.flip(seq))
    r = res_i * np.exp(2*np.pi * (pix_o[1] / res_o - 1))
    angle = 2*np.pi * pix_o[0] / res_o
    map_x = r * np.cos(angle) + dim_i/2
    map_y = r * np.sin(angle) + dim_i/2
    img_o = cv.remap(img_i, map_x, map_y, cv.INTER_LINEAR)

    if file_o is None:
        return img_o
    cv.imwrite(file_o, img_o)

if __name__ == "__main__":
    import matplotlib.pyplot as plt
    dst = depolarizer("circles.jpg")
    plt.imshow(cv.cvtColor(dst, cv.COLOR_BGR2RGB))
    plt.show()
