classdef ReformatTum < Reformatter
    %REFORMATTUM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end

    methods (Access = protected)
        function cameraFile = getCameraFileName(obj, rawScenePath)
            if contains(rawScenePath, 'freiburg1', 'IgnoreCase', true)
                cameraFile = 'tum_freiburg1_camera.txt';
            elseif contains(rawScenePath, 'freiburg2', 'IgnoreCase', true)
                cameraFile = 'tum_freiburg2_camera.txt';
            elseif contains(rawScenePath, 'freiburg3', 'IgnoreCase', true)
                cameraFile = 'tum_freiburg3_camera.txt';
            else
                assert(1, 'ReformatTum:getCameraFileName:wrongPathName', ...
                        'ReformatTum:getCameraFileName:wrongPathName', ...
                        sprintf('%s does not include "freiburg"', rawScenePath))
            end
        end

        function [depthFiles, rgbFiles, poses] = getSyncronizedFrames(obj, scenePath)
            [depthFiles, depthTimes] = obj.getImageList(scenePath, 'depth');
            [rgbFiles, rgbTimes] = obj.getImageList(scenePath, 'rgb');
            [poses, poseTimes] = obj.readPoses(scenePath, length(depthTimes));
            
            maxTimeDiff = 0.015;
            rgbInds = obj.findCorrespIndices(depthTimes, rgbTimes, maxTimeDiff);
            poseInds = obj.findCorrespIndices(depthTimes, poseTimes, maxTimeDiff);
            assert(length(depthTimes)==length(rgbInds) && length(depthTimes)==length(poseInds), ...
                'ReformatTum:getSyncronizedFrames:wrongIndices', ...
                'indices length must match depth length')

            validInds = find(rgbInds>0 & poseInds>0);
            sprintf('final valid frames: %d among %d', length(validInds), length(depthFiles))
            depthFiles = depthFiles(validInds);
            rgbFiles = rgbFiles(rgbInds(validInds));
            poses = poses(poseInds(validInds),:);
        end

        function [imgList, imgTimes] = getImageList(obj, srcPath, imgType)
            imgList = dir(fullfile(srcPath, imgType, '*.png'));
            imgTimes = obj.fileNamesToTimeVector(imgList);
            [imgTimes, sortedInds] = sort(imgTimes);
            imgList = imgList(sortedInds);
            % structure array to cell array of full paths
            imgList = arrayfun(@(x) fullfile(x.folder, x.name), imgList, 'UniformOutput', false);
        end
        
        function [poses, poseTimes] = readPoses(obj, srcPath, depthLen)
            poseFile = fullfile(srcPath, 'groundtruth.txt');
            poses = obj.readPoseFile(poseFile, depthLen);
            poseTimes = poses(:,1);
            poses = poses(:,2:end);
        end

        function times = fileNamesToTimeVector(obj, imgList)
            fileList = {imgList.name};
            fileList = cellfun(@(x) strrep(x, '.png', ''), fileList, 'UniformOutput', false);
            times = cellfun(@str2num, fileList, 'UniformOutput', false);
            times = cell2mat(times)';
        end

        function indices = findCorrespIndices(obj, referTimes, inputTimes, maxTimeDiff)
            refTimeMat = repmat(referTimes, 1, length(inputTimes));
            inpTimeMat = repmat(inputTimes', length(referTimes), 1);
            timeDiff = abs(refTimeMat - inpTimeMat);
            [minTime, indices] = min(timeDiff, [], 2);
            indices(minTime > maxTimeDiff) = 0;
        end

        function poses = readPoseFile(obj, poseFile, depthLen)
            fid = fopen(poseFile);
            assert(fid >= 0, 'ReformatTum:readPoseFile:cannotReadPoseFile', ...
                    poseFile)
            tline = fgetl(fid);
            poses = zeros(depthLen*5, 8);
            maxLen = length(poses);
            linecnt = 0;

            while ischar(tline)
                tline = fgetl(fid);
                if length(tline) < 10 || linecnt >= maxLen || startsWith(tline, '#')
                    continue
                end

                strnums = strsplit(tline);
                if length(strnums) ~= 8
                    continue
                end
                timepose = str2num(tline);
                linecnt = linecnt + 1;
                poses(linecnt,:) = timepose;
            end
            fclose(fid);

            poses = poses(1:linecnt,:);
        end

    end % method
    
end





