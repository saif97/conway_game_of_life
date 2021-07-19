

# %%
import matplotlib.image as mpimg
import matplotlib.pyplot as plt
from numpy.lib.type_check import imag

img = mpimg.imread('Screen Shot 2021-07-20 at 2.35.36 AM.png')
# call the grid size.

numRows = 0
numCols = 0

isNewCell = True


for eachPixle in img[0]:
    # is dead cell
    if eachPixle[0] == 0:
        if isNewCell:
            numCols += 1
            isNewCell = False
    else:
        isNewCell = True


isNewCell = True
for i in range(img.shape[0]):
    # is dead cell
    if img[i][0][0] == 0:
        if isNewCell:
            numRows += 1
            isNewCell = False
    else:
        isNewCell = True

print('Board Size')

print('cols: ',numCols, 'X','rows: ', numRows)
print()


# %%
mat = [[False for x in range(numCols)] for y in range(numRows)]
row_interval = (img.shape[0] // numRows)
col_interval = (img.shape[1] // numCols)

mg = [[0 for x in range(numCols)] for y in range(numRows)]
output_img = [[[0., 0., 0., 1.]
               for x in range(numCols)] for y in range(numRows)]

for eachRow in range(numRows):
    for eachCol in range(numCols):
        yPixel = (eachRow * row_interval) + (row_interval // 2)
        x_pixel = eachCol * col_interval + (col_interval // 2)
        pixel = img[yPixel][x_pixel]
        mg[eachRow][eachCol] = pixel
        if pixel[1] > 0.7:
            output_img[eachRow][eachCol] = pixel
            mat[eachRow][eachCol] = True

print("How the script sees the image")
# plt.imshow(mg)
print()

print("How the script sees the image")
plt.imshow(output_img,)

print("output")
# print(mat)

# for i in mat:
    # print('\t'.join(map(str, i)))

with open('output.txt', 'w') as f:
    f.write(str(mat).replace('F', 'f').replace('T', 't'))

# %%
