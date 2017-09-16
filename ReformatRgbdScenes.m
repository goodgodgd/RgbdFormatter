classdef ReformatRgbdScenes < Reformatter
    %REFORMATRSE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        function cameraFile = getCameraFileName(obj, rawScenePath)
            cameraFile = 'rgbd_scenes_camera.txt';
        end


        function imgList = getRgbList(obj, srcPath)
            imgList = dir(fullfile(srcPath, '*-color.png'));
        end


        function imgList = getDepthList(obj, srcPath)
            imgList = dir(fullfile(srcPath, '*-depth.png'));
        end


        function poses = readAllPoses(obj, srcPath)
            [pathstr, sceneDir, ~] = fileparts(srcPath);
            [pathstr, ~, ~] = fileparts(pathstr);
            filename = fullfile(pathstr, 'pc', sprintf('%s.pose', strrep(sceneDir, 'scene_', '')));
            poses = load(filename);
        end

    end
    
end

