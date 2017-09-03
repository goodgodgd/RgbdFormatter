function rgbdFormatter(varargin)
% rgbdFormatter(dataStyle, sourcePath, targetPath, sceneDirPattern)
% dataSytle: data format of dataset, it can be one of
%             'ScanNet', 'TUM', and 'rgbd-scenes'
% sourcePath: source data path, it can include multiple scenes
%               (=sequance of frames or video). 
% targetPath: target path for converted data in predefined format
% sceneDirPattern: Naming pattern of scene folders.
%   Folder names of scenes must have specific pattern with respect to dataStyle.
%   e.g - 'scene_*', 'rgbd_dataset_*'
%   
% IMPORTANT: When you try to reformat new dataset, 
% you have to prepare camera parameters 
% in a text file in git_root/cameraParams.
% Please refer the format of other files in that folder.

if length(varargin) < 4
    'please type "help reformatData"'
    return
else
    dataStyle = varargin{1};
    sourcePath = varargin{2};
    targetPath = varargin{3};
    sceneDirPattern = varargin{4};
end

if strcmpi(dataStyle, 'ScanNet')
    scanReformer = ReformatScanNet();
    scanReformer.reformatDataset(sourcePath, sceneDirPattern, targetPath)
elseif strcmpi(dataStyle, 'TUM')
    tumReformer = ReformatTum();
    tumReformer.reformatDataset(sourcePath, sceneDirPattern, targetPath)
elseif strcmpi(dataStyle, 'rgbd-scenes')
    tumReformer = ReformatRgbdScenes();
    tumReformer.reformatDataset(sourcePath, sceneDirPattern, targetPath)
end
