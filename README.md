# RgbdFormatter
This repository holds matlab codes to convert various rgbd datasets into the easy-to-use unified format including dir structure and file naming </br>
When we utilize existing RGB-D datasets, it is annoying that all the datasets have different formats. We had to implement a different reader class for each dataset. </br>
In addition, some datasets are difficult to syncronize rgb-depth-pose data. For example, TUM-style datasets are named with precise timestamps, which is more difficult to be synchronized than frame index naming. As ScanNet provides a camera pose with transformation matrix in a distinct file, there are too many tiny text files. Poses can be written in a single file where each line represents a position and a quaternion. </br>
This is why RgbdFormatter was made. It converts different datasets (hence with different formats) into the same format. </br>

### 1. Formattable Datasets
For now, it can deal with three datasets:
- [ScanNet](http://www.scan-net.org)
- [TUM-SLAM](https://vision.in.tum.de/data/datasets/rgbd-dataset/download)
- [RGBD Scenes v2](http://rgbd-dataset.cs.washington.edu/dataset/rgbd-scenes/)

The three datasets have rgb and depth images as well as camera pose information. In addition, to convert depth images into point cloud, we have know intrinsic parameters.

### 2. Unified Format
No matter which type of dataset comes, the output format is the same.
The output structure has four level hierarchies.
- dataset name
	- scene name
		- rgb
			- rgb-#####.png
		- depth
			- depth-#####.png
		- poses.txt, camera_param.txt
Directory structures are reorganized as follows.
![tree-compare](https://github.com/goodgodgd/RgbdFormatter/blob/master/imgs/tree-compare.png)
</br>
The unified format has three features.

1. Index-based naming: rgb and depth images are simply named by frame indices.
2. Camera tracjectoy on a single file: The pose on the i-th line in 'poses.txt' corresponds to the i-th rgb-depth images. Poses are formatted as (tx ty tz qw qx qy qz).
3. Registered rgb-depth pixels : If rgb images have the different size from depth images, they are rescaled into the size of depth images. If rgb-depth images have different intrinsic parameters, depth pixels are registered to rgb pixels. Hence the intrinsic parameters in 'camera_param.txt' are shared in both rgb and depth images.

</br>
Consequently, users simply read frames by indices and need not to care correspondences between rgb and depth.


### 3. How To Use
The main function of this repository is **rgbdFormatter.m**. The simple usage of it can be seen by typing 'help rgbdFormatter' on command window or just see **convertAll.m**.
The definition of **rgbdFormatter.m** is as follows.
> rgbdFormatter(dataStyle, sourcePath, targetPath, sceneDirPattern, imgCopy)


### 4. How To Adopt a New Dataset
Since RgbdFormatter was implemented with MATLAB classes, one can easily adopt new datasets with a minimal effort.

##### When RGB-Depth are Registered
All you have to do is to make a new class that inherits **Reformatter** and implement two abstract methods. Please refer to **ReformatRgbdScenes** and **ReformatTum**.

- *[depthFiles, rgbFiles, poses] = getSyncronizedFrames(obj, scenePath)* </br>: returns lists of image files and poses in the (tx ty tz qw qx qy qz) format. </br>
- *cameraFile = getCameraFileName(obj, rawScenePath)* </br>
: returns file name that that contains intrinsic paramters. This file is copied to each target scene folder. So it has to be prepared in advance in **RgbdFormatter/cameraParams**. </br>

Once you implemented a new class, you can add it in **rgbdFormatter.m** with a new style name.

##### When RGB-Depth are Not Registered
To handle pixel-level correspondences, make a new class that inherits **ReformatUnregistered** and implement two abstract methods like **ReformatScanNet**.

- *[depthFiles, rgbFiles, poses] = getSyncronizedFrames(obj, scenePath)* </br>: returns lists of image files and poses in the (tx ty tz qw qx qy qz) format **whose indices are syncronized in time**. </br>
- *[rgbintr, depintr, T_dep2rgb] = readCameraParams(obj, scenePath, rgbintr, depintr)* </br>
: returns intrinsic parameters of rgb and depth in the structure including cx, cy, fx, fy, width, and height. T_dep2rgb refers to the extrinsic transformation matrix from a depth sensor to a rgb sensor.

