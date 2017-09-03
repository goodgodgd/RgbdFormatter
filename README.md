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
> %   e.g - 'scene_\*', 'rgbd_dataset_\*' </br>

### 4. How to adopt new dataset
Since RgbdFormatter was implemented with MATLAB classes, one can easily adopt new datasets with a minimal effort. 
All you have to do is to make a new class that inherits **Reformatter** and implement four abstract methods. Here's an example of **ReformatRgbdScenes**.

> classdef ReformatRgbdScenes < Reformatter
> methods
>     **function** cameraFile = getCameraFileName(obj, rawScenePath) </br>
>         cameraFile = 'rgbd_scenes_camera.txt'; </br>
>     end </br>
>     **function** imgList = getRgbList(obj, srcPath) </br>
>         imgList = dir(fullfile(srcPath, '*-color.png')); </br>
>     end </br>
>     **function** imgList = getDepthList(obj, srcPath) </br>
>         imgList = dir(fullfile(srcPath, '*-depth.png')); </br>
>     end </br>
>     **function** poses = readAllPoses(obj, srcPath) </br>
>         [pathstr, sceneDir, ~] = fileparts(srcPath); </br>
>         [pathstr, ~, ~] = fileparts(pathstr); </br>
>         filename = fullfile(pathstr, 'pc', sprintf('%s.pose', strrep(sceneDir, 'scene_', ''))); </br>
>         poses = load(filename); </br>
>     end </br>
> end % method </br>
> end </br>

*getCameraFileName()* returns file name that that contains intrinsic paramters of rgb and depth images. This file is copied to each target scene folder. So it has to be prepared in advance in **RgbdFormatter/cameraParams**.
*getRgbList()* and *getDepthList()* return a list of image files.
*readAllPoses()* returns poses on rows in [x y z qx qy qz qw] format.

Once you implemented a new class, you can add it in **rgbdFormatter.m** with a new style name.

