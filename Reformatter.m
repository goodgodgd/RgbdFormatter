classdef Reformatter < handle
    %REFORMATTER Summary of this class goes here
    %   Detailed explanation goes here
    
properties
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
            obj.preparePath(dstPath)
            % camera parameters
            obj.copyCameraParam(rawScenePath, dstPath)

            % convert formats of rgb, depth, and pose
            % depth must be converted FIRST for tum-stype dataset
            obj.convertAndMoveDepths(rawScenePath, dstPath)
            obj.convertAndMovePoses(rawScenePath, dstPath)
            obj.convertAndMoveRgbs(rawScenePath, dstPath)
        end
    end


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

    
    function copyCameraParam(obj, rawScenePath, dstPath)
        % fullpath of dir of current m-file
        [pathstr, ~, ~] = fileparts(mfilename('fullpath'));
        % cd ..
        [pathstr, ~, ~] = fileparts(pathstr);
        try
            srcCameraParam = fullfile(pathstr, 'cameraParams', obj.getCameraFileName(rawScenePath))
            dstCameraParam = fullfile(dstPath, 'camera_param.txt');
            obj.fileCopy(srcCameraParam, dstCameraParam, 'copyCameraParam');
        catch ME
            sprintf('copyCameraParam:\n%s\n%s', ME.identifier, ME.message)
        end
    end


    function preparePath(obj, parentDir)
        if exist(parentDir, 'dir')
            parentDir
            rmdir(parentDir, 's')
        end
        mkdir(parentDir);

        if exist(fullfile(parentDir, 'rgb'), 'dir')
            rmdir(fullfile(parentDir, 'rgb'), 's')
        end
        mkdir(parentDir, 'rgb')

        if exist(fullfile(parentDir, 'depth'), 'dir')
            rmdir(fullfile(parentDir, 'depth'), 's')
        end
        mkdir(parentDir, 'depth')

        fid = fopen(fullfile(parentDir, 'poses.txt'), 'w');
        fclose(fid);
    end


    function convertAndMoveDepths(obj, srcPath, dstPath)
        listFunc = @(x) obj.getDepthList(x);
        obj.convertAndMoveImgs(srcPath, dstPath, 'depth', 'png', listFunc);
    end
    
    
    function convertAndMoveRgbs(obj, srcPath, dstPath)
        listFunc = @(x) obj.getRgbList(x);
        obj.convertAndMoveImgs(srcPath, dstPath, 'rgb', 'png', listFunc);
    end


    function convertAndMoveImgs(obj, srcPath, dstPath, imgType, extension, listFunc)
        imgList = listFunc(srcPath);
        
        % full path file name
        imgList = arrayfun(@(x) fullfile(x.folder, x.name), imgList, 'UniformOutput', false);
        imgList = string(imgList);
        listLen = length(imgList);
        prinInterv = max(floor(listLen/10), 100);
        prinInterv = round(prinInterv/100)*100;
        
        for i=1:listLen
            srcfile = char(imgList(i));
            if mod(i, prinInterv)==0
                sprintf('copying %s... %d in %d\n%s', imgType, i, listLen, srcfile)
            end
            
            dstfile = fullfile(dstPath, imgType, sprintf('%s-%05d.%s', imgType, i, extension));
            if endsWith(srcfile, extension)
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


    function convertAndMovePoses(obj, srcPath, dstPath)
        try
            poses = obj.readAllPoses(srcPath);
            fid = fopen(fullfile(dstPath, 'poses.txt'), 'w');
            fprintf(fid, '%.4f %.4f %.4f %.4f %.4f %.4f %.4f\n', poses');
            fclose(fid);
        catch ME
            sprintf('convertAndMovePoses:\n%s\n%s', ME.identifier, ME.message)
        end
    end

    
    function pose = convertTransformMatToVector(obj, tmat)
        assert(size(tmat,1)==4 && size(tmat,2)==4)
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
    

end % methods

methods (Abstract)
    cameraFile = getCameraFileName(obj, rawScenePath)

    imgList = getDepthList(obj, srcPath)

    imgList = getRgbList(obj, srcPath)

    poses = readAllPoses(obj, srcPath)

end % methods (Abstract)
end % classdef

