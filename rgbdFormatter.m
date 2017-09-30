function rgbdFormatter(dataStyle, sourcePath, targetPath, sceneDirPattern, imgCopy)
% dataSytle: data format of dataset, it can be one of
%             'ScanNet', 'TUM', and 'rgbd-scenes'
% sourcePath: source data path, it can include multiple scenes
%               (=sequance of frames or video). 
% targetPath: target path for converted data in predefined format
% sceneDirPattern: Naming pattern of scene folders.
%   Folder names of scenes must have specific pattern with respect to dataStyle.
%   e.g - 'scene_*', 'rgbd_dataset_*'
% imgCopy (optional): if false, image files are NOT copied, but 
% dir structure, camera parameter file, and pose file will be created.
%   
% IMPORTANT: When you try to reformat new dataset, 
% you have to prepare camera parameters 
% in a text file in git_root/cameraParams.
% Please refer the format of other files in that folder.

if nargin < 5
    imgCopy = true;
end

if strcmpi(dataStyle, 'ScanNet')
    scanReformer = ReformatScanNet();
    scanReformer.reformatDataset(sourcePath, sceneDirPattern, targetPath, imgCopy)
elseif strcmpi(dataStyle, 'TUM')
    tumReformer = ReformatTum();
    tumReformer.reformatDataset(sourcePath, sceneDirPattern, targetPath, imgCopy)
elseif strcmpi(dataStyle, 'rgbd-scenes')
    tumReformer = ReformatRgbdScenes();
    tumReformer.reformatDataset(sourcePath, sceneDirPattern, targetPath, imgCopy)
end
