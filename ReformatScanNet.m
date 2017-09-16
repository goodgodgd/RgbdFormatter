classdef ReformatScanNet < ReformatUnregistered
%REFORMATSCANNET Summary of this class goes here
%   Detailed explanation goes here

    properties
    end

    % inherited from Reformatter
    methods (Access = protected)
        function [depthFiles, rgbFiles, poses] = getSyncronizedFrames(obj, scenePath)
            depthList = dir(fullfile(scenePath, 'frame*.depth.pgm'));
            numFrames = length(depthList);
            depthFiles = cell(numFrames, 1);
            rgbFiles = cell(numFrames, 1);
            poses = zeros(numFrames, 7);
            
            for i=1:numFrames
                try
                    [depth, rgb, pose] = obj.checkExistingFrame(scenePath, i);
                    depthFiles(i) = {depth};
                    rgbFiles(i) = {rgb};
                    poses(i,:) = pose;
                catch ME
%                     sprintf('ReformatScanNet:getSyncronizedFrames:\n%s\n%s', ...
%                         ME.identifier, ME.message)
                end
            end
            
            validInds = find(~cellfun('isempty', depthFiles) & ...
                            ~cellfun('isempty', rgbFiles) & sum(abs(poses),2) > 0.1);
            sprintf('final valid frames: %d among %d', length(validInds), length(depthFiles))
            depthFiles = depthFiles(validInds);
            rgbFiles = rgbFiles(validInds);
            poses = poses(validInds,:);
        end
        
        function [depth, rgb, pose] = checkExistingFrame(obj, scenePath, index)
            zbIndex = index - 1; % zero-base index
            depth = fullfile(scenePath, sprintf('frame-%06d.depth.pgm', zbIndex));
            assert(exist(depth, 'file')>0, ...
                    'ReformatScanNet:checkExistingFrame:depthNotExist', depth)
            rgb = fullfile(scenePath, sprintf('frame-%06d.color.jpg', zbIndex));
            assert(exist(depth, 'file')>0, ...
                    'ReformatScanNet:checkExistingFrame:rgbNotExist', rgb)
            posefile = fullfile(scenePath, sprintf('frame-%06d.pose.txt', zbIndex));
            assert(exist(posefile, 'file')>0, ...
                    'ReformatScanNet:checkExistingFrame:rgbNotExist', posefile)
            tmat = load(posefile);
            pose = obj.convertTransformMatToVector(tmat);
        end
    end
    

    % inherited from ReformatUnregistered
    methods (Access = protected)
        function [rgbintr, depintr, T_dep2rgb] ...
                = readCameraParams(obj, scenePath, rgbintr, depintr)
            
            % no extrinsic between rgb and depth
            T_dep2rgb = eye(4);
            
            % open a file containing intrinsic paramters
            fid = fopen(fullfile(scenePath, '_info.txt'), 'r');
            assert(fid>=0, 'ReformatScanNet:readCameraParams:fileOpenFailure', ...
                   ['cannot open file:', fullfile(scenePath, '_info.txt')])
            
            tline = fgetl(fid);
            while ischar(tline)
                [name, value] = obj.parseLine(tline);
                switch name
                    case 'm_colorWidth'
                        rgbintr.width = value;
                    case 'm_colorHeight'
                        rgbintr.height = value;
                    case 'm_depthWidth'
                        depintr.width = value;
                    case 'm_depthHeight'
                        depintr.height = value;
                    case 'm_calibrationColorIntrinsic'
                        rgbintr.fx = value(1);
                        rgbintr.fy = value(6);
                        rgbintr.cx = value(3);
                        rgbintr.cy = value(7);
                    case 'm_calibrationDepthIntrinsic'
                        depintr.fx = value(1);
                        depintr.fy = value(6);
                        depintr.cx = value(3);
                        depintr.cy = value(7);
                    case 'm_depthShift'
                        obj.depthMeterScale = value;
                end
                tline = fgetl(fid);
            end
            fclose(fid);
        end
        
        function [name, value] = parseLine(obj, tline)
            name = 'nothing';
            value = 0;
            
            tline = strip(tline);            
            if isempty(tline) || startsWith(tline, '#')
                return
            end
            
            nameValue = split(tline, '=');
            if length(nameValue) ~= 2
                return
            end
            
            nameValue = strip(nameValue);
            name = nameValue{1};
            value = nameValue{2};
            value = str2num(value);            
        end
    end
    
end

