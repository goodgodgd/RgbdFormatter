clc
clear

%%%%% ScanNet
% sourcePath = '/media/cideep/HardDisk/RGBD-datasets-raw/scannet/scene-frames';
% sceneDirPattern = 'sceneimgs_*';
% targetPath = '/media/cideep/HardDisk/RGBD-datasets-formatted/scannet';
% rgbdFormatter('scannet', sourcePath, targetPath, sceneDirPattern)
% 
% %%%%% TUM
% sourcePath = '/media/cideep/HardDisk/RGBD-datasets-raw/TUM-SLAM';
% sceneDirPattern = 'rgbd_dataset_freiburg*';
% targetPath = '/media/cideep/HardDisk/RGBD-datasets-formatted/tum';
% rgbdFormatter('tum', sourcePath, targetPath, sceneDirPattern)

%%%%% rgbd-scenes
sourcePath = '/media/cideep/HardDisk/RGBD-datasets-raw/rgbd-scenes-v2/imgs';
sceneDirPattern = 'scene_11*';
targetPath = '/media/cideep/HardDisk/RGBD-datasets-formatted/rgbd-scenes-v2';
rgbdFormatter('rgbd-scenes', sourcePath, targetPath, sceneDirPattern)
