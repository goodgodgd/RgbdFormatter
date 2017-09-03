# RgbdFormatter
This repository holds matlab codes to convert rgbd datasets in the unified format (e.g. dir structure and naming)
When we utilize existing RGB-D datasets, it is annoying that all the datasets have different formats. We had to implement a different reader class for each dataset.
This is why RgbdFormatter was made. It converts different datasets (hence with different formats) into the same format.

### 1. Formattable Datasets
For now, it can deal with three datasets:
- [ScanNet](http://www.scan-net.org)
- [TUM-SLAM](https://vision.in.tum.de/data/datasets/rgbd-dataset/download)
- [RGBD Scenes v2](http://rgbd-dataset.cs.washington.edu/dataset/rgbd-scenes/)
The three datasets have rgb and depth images as well as camera pose information. In addition, to convert depth images into point cloud, we have know intrinsic parameters.

### 2. Unified format
No matter which type of dataset comes, the output format is the same.
Directory structures are reorganized as follows.
![tree-compare]

The output structure has four level hierarchies.
- dataset
	- scene
		- rgb
			- rgb-#.png
		- depth
			- depth-#.png
		- poses.txt, camera_param.txt

### 3. How to use
The main function of this repository is **rgbdFormatter.m**. The simple usage of it can be seen by typing 'help rgbdFormatter' on command window or just see **convertAll.m**.
The definition of **rgbdFormatter.m** is as follows.
> rgbdFormatter(dataStyle, sourcePath, targetPath, sceneDirPattern)
> % dataSytle: data format of dataset, it can be one of
> %             'ScanNet', 'TUM', and 'rgbd-scenes'
> % sourcePath: source data path, it can include multiple scenes
> %               (=sequance of frames or video). 
> % targetPath: target path for converted data in predefined format
> % sceneDirPattern: Naming pattern of scene folders.
> %   Folder names of scenes must have specific pattern with respect to dataStyle.
> %   e.g - 'scene_*', 'rgbd_dataset_*'


### 4. How to adopt new dataset
Since RgbdFormatter was implemented with MATLAB classes, one can easily adopt new datasets with a minimal effort. 

