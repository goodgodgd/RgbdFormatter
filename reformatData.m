function reformatData(varargin)
% dataFormatter(dataStyle, sourcePath, targetPath)
% dataSytle: data format of dataset, it can be one of
%             'ScanNet', and 'TUM'
% sourcePath: source data path, it can include multiple scenes
% targetPath: target path for converted data in predefined format
% sceneDirPattern (optional): Dataset usually include multiple scenes
%   (=sequance of frames or video). 
%   Folder names of scenes must have specific
%   pattern with respect to dataStyle.
%   If you named folders with specific naming pattern, 
%   give that pattern in the form of '*pattern*'.
% IMPORTANT: When you try to reformat new dataset, 
% you have to prepare camera parameters 
% in a text file in git_root/cameraParams.
% Please refer the format of other files in that folder.

if length(varargin) < 3
    'please type "help reformatData"'
    return
else
    dataStyle = varargin{1};
    sourcePath = varargin{2};
    targetPath = varargin{3};
    sceneDirPattern = varargin{4};
end

if strcmpi(dataStyle, 'ScanNet')
    if isempty(sceneDirPattern)
        sceneDirPattern = 'sceneimgs_*';
    end
    scanReformer = ReformatScanNet();
    scanReformer.reformatDataset(sourcePath, sceneDirPattern, targetPath)
elseif strcmpi(dataStyle, 'TUM')
    if isempty(sceneDirPattern)
        sceneDirPattern = 'rgbd_dataset_freiburg*';
    end
    tumReformer = ReformatTum();
    tumReformer.reformatDataset(sourcePath, sceneDirPattern, targetPath)
elseif strcmpi(dataStyle, 'rgbd-scenes')
    if isempty(sceneDirPattern)
        sceneDirPattern = 'scene_*';
    end
    tumReformer = ReformatRgbdScenes();
    tumReformer.reformatDataset(sourcePath, sceneDirPattern, targetPath)
end
