# RgbdFormatter
This repository holds matlab codes to convert rgbd datasets in the unified format. (e.g. dir structure and naming) </br>
When we utilize existing RGB-D datasets, it is annoying that all the datasets have different formats. We had to implement a different reader class for each dataset. </br>
This is why RgbdFormatter was made. It converts different datasets (hence with different formats) into the same format. </br>

### 1. Formattable Datasets
For now, it can deal with three datasets:
- [ScanNet](http://www.scan-net.org)
- [TUM-SLAM](https://vision.in.tum.de/data/datasets/rgbd-dataset/download)
- [RGBD Scenes v2](http://rgbd-dataset.cs.washington.edu/dataset/rgbd-scenes/)

The three datasets have rgb and depth images as well as camera pose information. In addition, to convert depth images into point cloud, we have know intrinsic parameters.

### 2. Unified format
No matter which type of dataset comes, the output format is the same.
Directory structures are reorganized as follows.
![tree-compare](https://github.com/goodgodgd/RgbdFormatter/blob/master/imgs/tree-compare.png)

The output structure has four level hierarchies.
- dataset name
	- scene name
		- rgb
			- rgb-#.png
		- depth
			- depth-#.png
		- poses.txt, camera_param.txt

### 3. How to use
The main function of this repository is **rgbdFormatter.m**. The simple usage of it can be seen by typing 'help rgbdFormatter' on command window or just see **convertAll.m**.
The definition of **rgbdFormatter.m** is as follows.
> rgbdFormatter(dataStyle, sourcePath, targetPath, sceneDirPattern) </br>
> % dataSytle: data format of dataset, it can be one of </br>
> %             'ScanNet', 'TUM', and 'rgbd-scenes' </br>
> % sourcePath: source data path, it can include multiple scenes </br>
> %               (=sequance of frames or video).  </br>
> % targetPath: target path for converted data in predefined format </br>
> % sceneDirPattern: Naming pattern of scene folders. </br>
> %   Folder names of scenes must have specific pattern with respect to dataStyle. </br>
> %   e.g - 'scene_*', 'rgbd_dataset_*' </br>


### 4. How to adopt new dataset
Since RgbdFormatter was implemented with MATLAB classes, one can easily adopt new datasets with a minimal effort. 

