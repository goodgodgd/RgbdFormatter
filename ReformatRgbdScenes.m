classdef ReformatRgbdScenes < Reformatter
    %REFORMATRSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = protected)
        function cameraFile = getCameraFileName(obj, rawScenePath)
            cameraFile = 'rgbd_scenes_camera.txt';
        end

        function [depthFiles, rgbFiles, poses] = getSyncronizedFrames(obj, scenePath)
            depthList = dir(fullfile(scenePath, '*-depth.png'));
            numFrames = length(depthList);
            depthFiles = cell(numFrames, 1);
            rgbFiles = cell(numFrames, 1);
            poses = obj.readPoses(scenePath);
            
            for i=1:numFrames
                try
                    [depth, rgb] = obj.checkExistingFrame(scenePath, i);
                    depthFiles(i) = {depth};
                    rgbFiles(i) = {rgb};
                catch ME
                    sprintf('ReformatScanNet:getSyncronizedFrames:\n%s\n%s', ...
                        ME.identifier, ME.message)
                end
            end
            
            assert(length(depthFiles)==length(rgbFiles) && length(depthFiles)==length(poses), ...
                'ReformatRgbdScenes:getSyncronizedFrames:wrongLengths', ...
                '(rgb depth pose) lengths must match')

            
            validInds = find(~cellfun('isempty', depthFiles) & ...
                            ~cellfun('isempty', rgbFiles) & sum(abs(poses),2) > 0.1);
            sprintf('final valid frames: %d among %d', length(validInds), length(depthFiles))
            depthFiles = depthFiles(validInds);
            rgbFiles = rgbFiles(validInds);
            poses = poses(validInds,:);
        end
        
        function [depth, rgb] = checkExistingFrame(obj, scenePath, index)
            zbIndex = index - 1; % zero-base index
            depth = fullfile(scenePath, sprintf('%05d-depth.png', zbIndex));
            if exist(depth, 'file')==0
                depth = '';
            end
            rgb = fullfile(scenePath, sprintf('%05d-color.png', zbIndex));
            if exist(rgb, 'file')==0
                rgb = '';
            end
        end

        function poses = readPoses(obj, srcPath)
            [pathstr, sceneDir, ~] = fileparts(srcPath);
            [pathstr, ~, ~] = fileparts(pathstr);
            filename = fullfile(pathstr, 'pc', sprintf('%s.pose', strrep(sceneDir, 'scene_', '')));
            poses = load(filename);
        end

    end
    
end

