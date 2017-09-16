classdef ReformatTum < Reformatter
    %REFORMATTUM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        depthTimes
    end

    methods
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


        function imgList = getDepthList(obj, srcPath)
            imgList = dir(fullfile(srcPath, 'depth', '*.png'));
            obj.depthTimes = obj.fileNamesToTimeVector(imgList);
            [obj.depthTimes, sortedInds] = sort(obj.depthTimes);
            imgList = imgList(sortedInds);
        end


        function imgList = getRgbList(obj, srcPath)
            imgList = dir(fullfile(srcPath, 'rgb', '*.png'));
            rgbTimes = obj.fileNamesToTimeVector(imgList);
            [rgbTimes, sortedInds] = sort(rgbTimes);
            imgList = imgList(sortedInds);

            corresIndices = obj.findCorrespIndices(obj.depthTimes, rgbTimes);

            emptyIndex = length(imgList) + 1;
            imgList(emptyIndex) = imgList(1);
            imgList(emptyIndex).name = 'noname';
            imgList = imgList(corresIndices);
            assert(length(obj.depthTimes)==length(imgList))

            emptyIndices = find(strcmp({imgList.name}, 'noname'));
            for ind = emptyIndices
                imgList(ind).name = sprintf('image_%d', ind);
            end
        end


        function times = fileNamesToTimeVector(obj, imgList)
            fileList = {imgList.name};
            fileList = cellfun(@(x) strrep(x, '.png', ''), fileList, 'UniformOutput', false);
            times = cellfun(@str2num, fileList, 'UniformOutput', false);
            times = cell2mat(times)';
        end


        function indices = findCorrespIndices(obj, referTimes, inputTimes)
            % set default index as length+1, see why in getRgbList()
            indices = ones(length(referTimes), 1) * (length(inputTimes) + 1);
            % find index with closest time in inputTimes
            for i = 1:length(referTimes)
                timeDiff = abs(inputTimes - referTimes(i));
                [time, index] = min(timeDiff);
                if time < 0.015
                    indices(i) = index;
                end
            end
        end


        function poses = readAllPoses(obj, srcPath)
            poseFile = fullfile(srcPath, 'groundtruth.txt');
            poses = obj.readPoseFile(poseFile);
            poseTimes = poses(:,1);
            poses = poses(:,2:end);

            corresIndices = obj.findCorrespIndices(obj.depthTimes, poseTimes);

            poses = [poses; zeros(1,7)];
            poses = poses(corresIndices,:);
            assert(length(obj.depthTimes)==length(poses))
        end


        function poses = readPoseFile(obj, poseFile)
            fid = fopen(poseFile);
            assert(abs(fid+1) < 1e-5, ...
                'ReformatTum:readPoseFile:cannotReadPoseFile', 'pose file open failed')
            tline = fgetl(fid);
            poses = zeros(length(obj.depthTimes)*5, 8);
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





