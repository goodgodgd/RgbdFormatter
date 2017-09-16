classdef Reformatter < handle
    %REFORMATTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        extension = 'png'
    end

    methods
        function reformatDataset(obj, sourcePath, sceneDirPattern, targetPath)
            % find sub paths under sourcePath that includes image frames
            subPathList = obj.findSourceDirList(sourcePath, sceneDirPattern)
            listLen = length(subPathList);

            for i=1:listLen
                rawScenePath = char(subPathList(i));
                dstPath = char(strrep(rawScenePath, sourcePath, targetPath));
                % create subdirs and files
                obj.preparePath(dstPath);
                
                % the order of following functions MATTERS. Do NOT change it.
                % copy text file containing camera parameters
                obj.copyCameraParam(rawScenePath, dstPath)
                % convert rgb, depth, and pose into unified format
                % and copy them into dstPath
                [depthFiles, rgbFiles, poses] = obj.getSyncronizedFrames(rawScenePath);
                obj.moveImages(depthFiles, 'depth', dstPath)
                obj.moveImages(rgbFiles, 'rgb', dstPath)
                obj.writePoses(poses, dstPath)
            end
        end
    end


    methods (Access = protected)
        function subpaths = findSourceDirList(obj, rootPath, dirPattern)
            % list all dirs and files in rootPath recursively
            list = dir(fullfile(rootPath, dirPattern));
            % extract dirs only
            list = list(cell2mat({list.isdir}));
            % remove . and ..
            list = list(~cellfun(@(x) endsWith(x, '.'), {list.name}));
            % make cell array of full paths
            subpaths = arrayfun(@(x) fullfile(x.folder, x.name), list, ...
                                'UniformOutput', false);
        end


        function preparePath(obj, parentDir)
            if exist(parentDir, 'dir')
                parentDir
                rmdir(parentDir, 's')
            end
            pause(0.1)
            mkdir(parentDir);

            if exist(fullfile(parentDir, 'rgb'), 'dir')
                rmdir(fullfile(parentDir, 'rgb'), 's')
            end
            pause(0.1)
            mkdir(parentDir, 'rgb')

            if exist(fullfile(parentDir, 'depth'), 'dir')
                rmdir(fullfile(parentDir, 'depth'), 's')
            end
            pause(0.1)
            mkdir(parentDir, 'depth')

            fid = fopen(fullfile(parentDir, 'poses.txt'), 'w');
            pause(0.1)
            fclose(fid);
        end

        function moveImages(obj, imgList, imgType, dstPath)
            listLen = length(imgList);
            prinInterv = max(floor(listLen/10), 100);
            prinInterv = round(prinInterv/100)*100;

            tic
            for i=1:listLen
                srcfile = char(imgList(i));
                if mod(i, prinInterv)==0
                    sprintf('copying %s... %d in %d, took %.1fs\n%s', ...
                        imgType, i, listLen, toc, srcfile)
                    tic
                end

                dstfile = fullfile(dstPath, imgType, sprintf('%s-%05d.%s', imgType, i, obj.extension));
                obj.moveImgFile(imgType, srcfile, dstfile);
            end
        end


        function writePoses(obj, poses, dstPath)
            try
                filename = fullfile(dstPath, 'poses.txt');
                fid = fopen(filename, 'w');
                assert(fid>=0, 'Reformatter:writePoses:cannotOpenFile', filename);
                fprintf(fid, '%.4f %.4f %.4f %.4f %.4f %.4f %.4f\n', poses');
                fclose(fid);
            catch ME
                sprintf('convertAndMovePoses:\n%s\n%s', ME.identifier, ME.message)
            end
        end


        function pose = convertTransformMatToVector(obj, tmat)
            assert(size(tmat,1)==4 && size(tmat,2)==4 && abs(det(tmat(1:3,1:3))-1) < 0.001, ...
                'Reformatter:convertTransformMatToVector:wrongTMatFormat', ...
                'invalid transformation matrix')
            quat = rotm2quat(tmat(1:3,1:3));
            assert(abs(norm(quat,2)-1) < 1e-5)
            posi = tmat(1:3,4)';
            pose = [posi, quat];
        end

        function fileCopy(obj, srcfile, dstfile, funcname)
            [success, msg, msgid] = copyfile(srcfile, dstfile);
            if success == 0
                sprintf('%s:\n%s\n%s', funcname, msgid, msg)
            end
        end


    end


    % methods to be overriden in ReformatUnregistered
    methods (Access = protected)
        function copyCameraParam(obj, rawScenePath, dstPath)
            % fullpath of dir of current m-file
            [pathstr, ~, ~] = fileparts(mfilename('fullpath'));
            try
                srcCameraParam = fullfile(pathstr, 'cameraParams', ...
                                    obj.getCameraFileName(rawScenePath));
                dstCameraParam = fullfile(dstPath, 'camera_param.txt');
                obj.fileCopy(srcCameraParam, dstCameraParam, 'copyCameraParam');
            catch ME
                sprintf('copyCameraParam:\n%s\n%s', ME.identifier, ME.message)
            end
        end

        function moveImgFile(obj, imgType, srcfile, dstfile)
            if endsWith(srcfile, obj.extension)
                obj.fileCopy(srcfile, dstfile, 'convertAndMoveImgs');
            else
                try
                    img = imread(srcfile);
                    imwrite(img, dstfile)
                catch ME
                    sprintf('convertAndMoveImgs:\n%s\n%s', ME.identifier, ME.message)
                end
            end
        end
    end


    % methods to be implemented in subclasses
    methods (Abstract, Access = protected)
        cameraFile = getCameraFileName(obj, rawScenePath)
        [depthFiles, rgbFiles, poses] = getSyncronizedFrames(obj, scenePath)
%         imgList = getDepthList(obj, srcPath)
%         imgList = getRgbList(obj, srcPath)
%         poses = readAllPoses(obj, srcPath)
    end
end
