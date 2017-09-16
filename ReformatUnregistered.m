classdef ReformatUnregistered < Reformatter
    %REFORMATUNREGISTERED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % init structure
        rgbintr
        depintr
        itgintr
        T_dep2rgb = eye(4);
        depthMeterScale = 1000
    end
    
    % constructor
    methods
        function obj = ReformatUnregistered()
            obj.rgbintr = obj.invalidIntrinsic();
            obj.depintr = obj.invalidIntrinsic();
            obj.itgintr = obj.invalidIntrinsic();
            obj.T_dep2rgb = eye(4);
            obj.depthMeterScale = 1000;
        end
    end

    methods (Access = protected)
        function intr = invalidIntrinsic(obj)
            intr = struct('width', -1, 'height', -1, 'fx', -1, 'fy', -1, 'cx', -1, 'cy', -1);
        end
        
        
        % dummy implementation of unused method, you don't have implement it in
        % subclasses of this class
        function cameraFile = getCameraFileName(obj, rawScenePath)
            cameraFile = 'nouse';
        end
        
        
        % override method implemented in super class
        function copyCameraParam(obj, rawScenePath, dstPath)
            % read rgb and depth camera parameters seperately
            [obj.rgbintr, obj.depintr, obj.T_dep2rgb] = ...
                obj.readCameraParams(rawScenePath, obj.rgbintr, obj.depintr);
            % merge them into integrated camera parameter
            obj.itgintr = obj.makeUnifiedParams(obj.rgbintr, obj.depintr);
            obj.checkIntrinsics()
            
            % write on file
            dstFileName = fullfile(dstPath, 'camera_param.txt');
            obj.writeCameraParams(obj.itgintr, dstFileName);
        end

        function itgintr = makeUnifiedParams(obj, rgbintr, depintr)
            itgintr = obj.invalidIntrinsic();
            itgintr.width = depintr.width;
            itgintr.height = depintr.height;
            % final image size <- depth
            % final image intrinsics <- scaled rgb
            xscale = depintr.width / rgbintr.width;
            yscale = depintr.height / rgbintr.height;
            itgintr.fx = rgbintr.fx * xscale;
            itgintr.fy = rgbintr.fy * yscale;
            itgintr.cx = rgbintr.cx * xscale;
            itgintr.cy = rgbintr.cy * yscale;
        end

        function writeCameraParams(obj, intrinsic, dstFileName)
            fid = fopen(dstFileName, 'w');
            fprintf(fid, 'width = %d\n', intrinsic.width);
            fprintf(fid, 'height = %d\n', intrinsic.height);
            fprintf(fid, 'fx = %d\n', intrinsic.fx);
            fprintf(fid, 'fy = %d\n', intrinsic.fy);
            fprintf(fid, 'cx = %d\n', intrinsic.cx);
            fprintf(fid, 'cy = %d\n', intrinsic.cy);
            fprintf(fid, 'depthMeterScale = %d\n', obj.depthMeterScale);
            fclose(fid);
        end

        function checkIntrinsics(obj)
            rgb = obj.rgbintr;
            dep = obj.depintr;
            itg = obj.itgintr;
            params = [rgb.width rgb.height rgb.fx rgb.fy rgb.cx rgb.cy; ...
                dep.width dep.height dep.fx dep.fy dep.cx dep.cy; ...
                itg.width itg.height itg.fx itg.fy itg.cx itg.cy]
            imgsizes = params(:,1:2)
            intrinsics = params(:,3:end)
            
            assert(sum(sum(params <= 0))==0, ...
                'ReformatUnregistered:checkIntrinsics:InvalidIntrinsic', ...
                'intrinsic parameters were not updated')
        end

        
        % override method implemented in super class
        function moveImgFile(obj, imgType, srcfile, dstfile)
            try
                % read source image
                image = imread(srcfile);
                if strcmp(imgType, 'rgb')
                    % resize rgb image into integrated size (depth)
                    image = imresize(image, [obj.itgintr.height, obj.itgintr.width], 'bilinear');
                elseif strcmp(imgType, 'depth')
                    % register depth image into rgb image
                    image_new = obj.registerDepth(image, obj.depintr, obj.itgintr, obj.T_dep2rgb);
%                     depth_diff = abs(image_new - double(image));
%                     depth_diff(depth_diff < 0.1) = 0;
                    image = uint16(max(image_new, 0));
                else
                    error('ReformatUnregistered:moveImgFile:wrongImageType', ...
                           ['image type is wrong: ', imgType])
                end

                % write output image
                imwrite(image, dstfile)
            catch ME
                sprintf('moveImgFile:\n%s\n%s', ME.identifier, ME.message)
            end
        end

        function depthReg = registerDepth(obj, depthRaw, depintr, itgintr, T_dep2rgb)
            deppar = [depintr.fx, depintr.fy, depintr.cx, depintr.cy];
            itgpar = [itgintr.fx, itgintr.fy, itgintr.cx, itgintr.cy];
            if sum(abs(deppar - itgpar)) < 0.1 && sum(sum(abs(T_dep2rgb - eye(4)))) < 0.001
                depthReg = depthRaw;
                return
            end

            points = obj.convertToPoints(depthRaw, depintr, T_dep2rgb);
            depthReg = obj.projectDepthOnRgb(points, itgintr);
        end

        function points = convertToPoints(obj, depth, campar, Tmat)
            imx = repmat(1:campar.width, campar.height, 1);
            imy = repmat((1:campar.height)', 1, campar.width);
            depth = double(depth);
            X = (imx - (campar.cx + 1)) / campar.fx .* depth;
            Y = (imy - (campar.cy + 1)) / campar.fy .* depth;
            Z = depth;
            points = cat(3, X, Y, Z); % size = H x W x 3

            points = permute(points, [3 2 1]);
            points = reshape(points, 3, [])'; % size = (HxW) x 3
            N = length(points);
            points = points*Tmat(1:3,1:3)' + repmat(Tmat(1:3,4)', N, 1);
        end

        function depthReg = projectDepthOnRgb(obj, points, intrin)
            points = points(points(:,3)>0.01, :);
            imx = points(:,1) ./ points(:,3) * intrin.fx + intrin.cx;
            imy = points(:,2) ./ points(:,3) * intrin.fy + intrin.cy;
            valPtInds = find(imx>-0.5 & imx<intrin.width-0.5 & ...
                            imy>-0.5 & imy<intrin.height-0.5);
            imgInds = round(imx(valPtInds)) * intrin.height + round(imy(valPtInds)) + 1;
            depthReg = zeros(intrin.height, intrin.width);
            depthReg(imgInds) = points(valPtInds,3);
            return;
            

            weight = zeros(intrin.height, intrin.width);
            depthW = zeros(intrin.height, intrin.width);
            depthReg = zeros(intrin.height, intrin.width);
            valN = length(imx);
            for i=1:valN
                pixrng = [floor(imx(i)), ceil(imx(i)), floor(imy(i)), ceil(imy(i))];
                if pixrng(1) < 1 || pixrng(2) > intrin.width || ...
                        pixrng(3) < 1 || pixrng(4) > intrin.height
                    continue
                end

                curdep = points(i,3);
                rwnd = pixrng(3):pixrng(4);
                cwnd = pixrng(1):pixrng(2);
                pixw = obj.distributeWeight([imx(i), imy(i)], pixrng);
                weight(rwnd, cwnd) = weight(rwnd, cwnd) + pixw;
                depthW(rwnd, cwnd) = depthW(rwnd, cwnd) + pixw * curdep;
            end

            nzInds = find(weight > 0.001);
            depthReg(nzInds) = depthW(nzInds) ./ weight(nzInds);
        end

        function pixw = distributeWeight(obj, pixel, pixrng)
            if pixrng(1)==pixrng(2)
                xw = 0.5;
            else
                xw = [abs(pixrng(2) - pixel(1)), abs(pixrng(1) - pixel(1))];
            end
            if pixrng(3)==pixrng(4)
                yw = 0.5;
            else
                yw = [abs(pixrng(4) - pixel(2)); abs(pixrng(3) - pixel(2))];
            end

            xw = repmat(xw, size(yw,1), 1);
            yw = repmat(yw, 1, size(xw,2));
            pixw = xw .* yw;
        end
    end

    % function to be implemented for children of this class
    methods (Abstract, Access = protected)
        [rgbintr, depintr, T_dep2rgb] = readCameraParams(obj, scenePath, rgbintr, depintr)
    end
end
