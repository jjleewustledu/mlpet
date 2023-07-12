classdef (Abstract) AugmentedData < handle
	%% AUGMENTEDDATA  

	%  $Revision$
 	%  was created 31-Jan-2021 12:30:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.9.0.1570001 (R2020b) Update 4 for MACI64.  Copyright 2021 John Joowon Lee.

    
    properties (Abstract)
        blurTag
        Delta
        Dt
    end
    
    properties (Dependent)
        tBuffer
    end
    
    properties
        DtMixing
    end
    
	methods (Static)
        function mixed = mix(obj, obj2, f, varargin)
            ip = inputParser;
            addRequired(ip, 'obj')
            addRequired(ip, 'obj2')
            addRequired(ip, 'f', @isscalar)
            addOptional(ip, 'daif', nan, @isscalar)
            parse(ip, obj, obj2, f, varargin{:})
            
            assert(f > 0)
            assert(f < 1)
            if isnumeric(obj) && isnumeric(obj2)
                mixed = f*obj + (1 - f)*obj2;
                return
            end
            obj = mlfourd.ImagingContext2(obj);
            obj2 = mlfourd.ImagingContext2(obj2);
            mixed = obj * f + obj2 * (1 - f);
            if isfinite(ip.Results.daif)
                mixed.fileprefix = sprintf('%s_daif%s', ...
                    mixed.fileprefix, strrep(num2str(ip.Results.daif, 4), '.', 'p'));
            end            
        end
        function [scan_,timesMid_,aif_] = mixScannersAifs(varargin)
            [scan_,timesMid_,aif_] = ...
                mlkinetics.ScannerKit.mixScannersAifsAugmented(varargin{:});
        end            
        function [tac__,timesMid__,aif__,Dt,datetimePeak] = mixTacAif(devkit, varargin)
            [tac__,timesMid__,aif__,Dt,datetimePeak] = ...
                mlkinetics.ScannerKit.mixTacAifAugmented(devkit, varargin{:});
        end
        function [tac__,timesMid__,aif__,Dt] = mixTacsAifs(devkit, devkit2, varargin)
            [tac__,timesMid__,aif__,Dt] = ...
                mlkinetics.ScannerKit.mixTacsAifsAugmented(devkit, devkit2, varargin{:});
        end
        function [tac__,timesMid__,aif__,Dt,datetimePeak] = mixTacIdif(devkit, varargin)
            [tac__,timesMid__,aif__,Dt,datetimePeak] = ...
                mlkinetics.ScannerKit.mixTacIdifAugmented(devkit, varargin{:});
        end
    end 
    
    methods 
        
        %% GET
        
        function g = get.tBuffer(~)
            ad = mlaif.AifData.instance();
            g = ad.tBuffer;
        end
        
        %%
        
		function a = artery_local(this, varargin)
            %% ARTERY_LOCAL returns artery activities mapped into R^(3+1), space-times,
            %  shifted by this.Dt and disperses by this.Delta
            %  @param typ is understood by imagingType.
            %  @return a is an imagingType, the artery activities sampled on scanner space-times.
            %  See also ml*.Dispersed*Model.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'typ', 'mlfourd.ImagingContext2', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            n = length(this.artery_interpolated);
            times = 0:1:n-1;            
            auc0 = trapz(this.artery_interpolated);
            artery_interpolated_ = conv(this.artery_interpolated, exp(-this.Delta*times));
            if this.Dt < 0 % shift back to right
                artery_interpolated1 = zeros(1, n);
                artery_interpolated1(-this.Dt+1:end) = artery_interpolated_(1:n+this.Dt);
            elseif this.Dt > 0 % shift back to left
                artery_interpolated1 = artery_interpolated_(this.Dt+1:this.Dt+n);
            else
                artery_interpolated1 = artery_interpolated_(1:n);
            end 
            artery_interpolated1 = artery_interpolated1*auc0/trapz(artery_interpolated1);
            artery_interpolated1 = artery_interpolated1(this.tBuffer+1:end);
            avec = this.model.solutionOnScannerFrames(artery_interpolated1, this.times_sampled);
            
            roibin = logical(this.roi);
            a = copy(this.roi.imagingFormat);
            a.img = zeros([size(this.roi) length(avec)]);
            for t = 1:length(avec)
                img = zeros(size(this.roi), 'single');
                img(roibin) = avec(t);
                a.img(:,:,:,t) = img;
            end
            a.fileprefix = this.sessionData.metricOnAtlas( ...
                stackstr(), [this.blurTag this.regionTag]);
            a = imagingType(ipr.typ, a);
        end 
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

