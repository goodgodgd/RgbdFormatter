classdef ReformatScanNet < Reformatter
%REFORMATSCANNET Summary of this class goes here
%   Detailed explanation goes here

properties
end

methods
    function cameraFile = getCameraFileName(obj, rawScenePath)
        cameraFile = 'scannet_camera.txt';
    end

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

end % method
    
end

