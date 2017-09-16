classdef ReformatScanNet < ReformatUnregistered
%REFORMATSCANNET Summary of this class goes here
%   Detailed explanation goes here

    properties
    end

    % inherited from Reformatter
    methods (Access = protected)
        function imgList = getRgbList(obj, srcPath)
            imgList = dir(fullfile(srcPath, 'frame*.color.jpg'));
        end

        function imgList = getDepthList(obj, srcPath)
            imgList = dir(fullfile(srcPath, 'frame*.depth.pgm'));
        end

        function poses = readAllPoses(obj, srcPath)
            poseList = dir(fullfile(srcPath, 'frame*.pose.txt'));
            poseList = arrayfun(@(x) fullfile(x.folder, x.name), poseList, 'UniformOutput', false);
            listLen = length(poseList);
            poses = zeros(listLen, 7);
            for i=1:listLen
                posefile = char(poseList(i));
                if mod(i,floor(listLen/10))==0
                    sprintf('reading pose... %d in %d, %s', i, listLen, posefile)
                end

                try
                    tmat = load(posefile);
                    assert(sum(sum(isinf(tmat))) == 0, ...
                        'ReformatScanNet:readAllPoses:InfinitePoseValues', ...
                        'pose value is infinite')
                    poses(i,:) = obj.convertTransformMatToVector(tmat);
                catch ME
                    sprintf('ReformatScanNet:readAllPoses:\n%s\n%s', ME.identifier, ME.message)
                end
            end
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

