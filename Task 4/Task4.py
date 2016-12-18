import cv2
import numpy as np


def flow_read(filename):
    # loads flow field F from png file

    I = np.double(np.uint8(cv2.imread(filename)))
    F=I
    print(I)

    F_u = np.double((I[:, :, 0]-2**8 ) / 64.0)
    F_v = np.double((I[:, :, 1]-2**8 )  / 64.0)
    F_valid = np.minimum(I[:, :, 2], 1.0)
    F_u[F_valid == 0] = 0
    F_v[F_valid == 0] = 0
    F[:, :, 0] = F_u
    F[:, :, 1] = F_v
    F[:, :, 2] = F_valid
    print(F)
    print (F[60:62,70:80,1])
    print(F.dtype)
    print(I.dtype)
    print(F_u.dtype)


flow_read('../datasets/results_of/LKflow_000045_10.png')
#flow_read('../datasets/results_of/LKflow_000157_10.png')
