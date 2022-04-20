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
            
            import mlpet.AugmentedData
            import mlpet.AugmentedData.mix
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'scanner2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'roi2', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'DtMixing', 0, @isscalar)
            addParameter(ip, 'fracMixing', 0.9, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            DtMixing = ipr.DtMixing;
            
            % scanners provide calibrations, ancillary data            
            
            scanner = ipr.scanner.volumeAveraged(ipr.roi);
            scan = scanner.activityDensity();
            scanner2 = ipr.scanner2.volumeAveraged(ipr.roi2);            
            scan2 = scanner2.activityDensity();
            
            % arterials also have calibrations
            
            a = ipr.arterial;
            aif = a.activityDensity();         
            a2 = ipr.arterial2;
            aif2 = a2.activityDensity();
            
            % reconcile timings  
              
            t_a = 0:a.timeWindow;
            t_a2 = 0:a2.timeWindow;
            
            if DtMixing < 0 % shift aif2, scan2 to left             
                aif = makima(t_a + a.Dt, aif, 0:scanner.times(end));
                aif2 = makima(t_a2 + a2.Dt + DtMixing, aif2, 0:scanner.times(end));
                scan2 = makima(scanner2.times + DtMixing, scan2, scanner.times); 
                timesMid_ = scanner.timesMid;
            else % shift aif, scan to left
                aif2 = makima(t_a2 + a2.Dt, aif2, 0:scanner2.times(end));
                aif = makima(t_a + a.Dt - DtMixing, aif, 0:scanner2.times(end));
                scan = makima(scanner.times - DtMixing, scan, scanner2.times);  
                timesMid_ = scanner2.timesMid;
            end 
            aif(aif < 0) = 0;
            scan(scan < 0) = 0;
            aif2(aif2 < 0) = 0;
            scan2(scan2 < 0) = 0;
            
            scan_ = mix(scan, scan2, ipr.fracMixing); % calibrated, decaying
            aif_ = mix(aif, aif2, ipr.fracMixing);
        end            
        function [tac__,timesMid__,aif__,Dt,datetimePeak] = mixTacAif(devkit, varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'devkit', @(x) isa(x, 'mlpet.IDeviceKit'))
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            parse(ip, devkit, varargin{:})
            ipr = ip.Results;      
            if strcmp(class(ipr.scanner), class(ipr.arterial))
                [tac__,timesMid__,aif__,Dt,datetimePeak] = ...
                    mlpet.AugmentedData.mixTacIdif(devkit, varargin{:});
                return
            end
            ad = mlaif.AifData.instance();
            
            % scannerDevs provide calibrations & ROI-volume averaging            
            s = ipr.scanner.volumeAveraged(ipr.roi);
            tac = s.activityDensity();
            tac(tac < 0) = 0;                       
            tac = ad.normalizationFactor*tac; % empirical normalization
            tac__ = tac;
            timesMid__ = s.timesMid;
            Nt = ceil(timesMid__(end));
            
            % arterialDevs calibrate & align arterial times-series to localized scanner time-series            
            a0 = ipr.arterial;
            [a, datetimePeak] = devkit.alignArterialToScanner( ...
                a0, s, ad, 'sameWorldline', false);
            aif = a.activityDensity('Nt', Nt);
            switch class(a)
                case 'mlswisstrace.TwiliteDevice'
                    t = (0:Nt-1) - seconds(s.datetime0 - a.datetime0);
                case 'mlcapintec.CapracDevice'
                    t = a.times - seconds(s.datetime0 - a.datetime0);
                otherwise
                    error('mlpet:ValueError', ...
                        'class(AugmentedData.mixTacAif.a) = %s', class(a))
            end
            
            % use tBuffer to increase fidelity of kinetic model
            while any(-ad.tBuffer == t)
                ad.T = ad.T + 1;
            end
            aif = interp1([-ad.tBuffer t], [0 aif], -ad.tBuffer:s.timesMid(end), 'linear', 0);
            aif(aif < 0) = 0;            
            aif__ = aif;            
            Dt = a.Dt;
        end
        function [tac__,timesMid__,aif__,Dt] = mixTacsAifs(devkit, devkit2, varargin)
            
            import mlpet.AugmentedData
            import mlpet.AugmentedData.mixTacAif
            import mlpet.AugmentedData.mix
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'devkit', @(x) isa(x, 'mlpet.IDeviceKit'))
            addRequired(ip, 'devkit2', @(x) isa(x, 'mlpet.IDeviceKit'))
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'scanner2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'roi2', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'DtMixing', 0, @isscalar) % sec > 0
            addParameter(ip, 'fracMixing', 0.9, @isscalar)
            parse(ip, devkit, devkit2, varargin{:})
            ipr = ip.Results;
            s = ipr.scanner;
            s2 = ipr.scanner2;
            ad = mlaif.AifData.instance();
            
            % align aif with tac, aif2 with tac2
            [tac,timesMid,aif,Dt,datetimePeak] = mixTacAif(devkit, ...
                                                           'scanner', ipr.scanner, ...
                                                           'arterial', ipr.arterial, ...
                                                           'roi', ipr.roi);                                                
            [tac2,~,aif2,~,datetimePeak2] = mixTacAif(devkit2, ...
                                                      'scanner', ipr.scanner2, ...
                                                      'arterial', ipr.arterial2, ...
                                                      'roi', ipr.roi2);
            offset = seconds(datetimePeak - s.datetime0) - ...
                     seconds(datetimePeak2 - s2.datetime0) + ...
                     ipr.DtMixing;
            
            % align tac2 with tac
            tac = interp1([-1 s.timesMid], [0 tac], s.timesMid(1):s.timesMid(end), 'linear', 0);
            tac2 = interp1((offset + [-1 s2.timesMid]), [0 tac2], s.timesMid(1):s.timesMid(end), 'linear', 0);
            tac__ = mix(tac, tac2, ipr.fracMixing); 
            tac__ = interp1(s.timesMid(1):s.timesMid(end), tac__, s.timesMid, 'linear', 0);
            tac__(tac__ < 0) = 0;                       
            tac__ = ad.normalizationFactor*tac__; % empirical normalization
            timesMid__ = timesMid;
            
            % align aif2 with aif
            n = length(aif);
            n2 = length(aif2);
            aif2 = interp1(offset + (0:n2-1), aif2, 0:n-1, 'linear', 0);
            aif__ = mix(aif, aif2, ipr.fracMixing); 
            aif__(aif__ < 0) = 0;  
        end
        function [tac__,timesMid__,aif__,Dt,datetimePeak] = mixTacIdif(devkit, varargin)
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'devkit', @(x) isa(x, 'mlpet.IDeviceKit'))
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'arterial', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            parse(ip, devkit, varargin{:})
            ipr = ip.Results;
            ad = mlaif.AifData.instance();
            
            % scannerDevs provide calibrations & ROI-volume averaging            
            s = ipr.scanner.volumeAveraged(ipr.roi);
            tac = s.activityDensity();
            tac(tac < 0) = 0;                       
            tac = ad.normalizationFactor*tac; % empirical normalization
            tac__ = tac;
            timesMid__ = s.timesMid;
            
            % arterialDevs calibrate & align arterial times-series to localized scanner time-series 
            aif = a.activityDensity();
            t = a.timesMid;
            
            % use tBuffer to increase fidelity of kinetic model
            while any(-ad.tBuffer == t)
                ad.T = ad.T + 1;
            end
            aif = interp1([-ad.tBuffer t], [0 aif], -ad.tBuffer:s.timesMid(end), 'linear', 0);
            aif(aif < 0) = 0;            
            aif__ = aif;  

            % trivial values
            Dt = 0;
            datetimePeak = NaT;
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
            a = copy(this.roi.fourdfp);
            a.img = zeros([size(this.roi) length(avec)]);
            for t = 1:length(avec)
                img = zeros(size(this.roi), 'single');
                img(roibin) = avec(t);
                a.img(:,:,:,t) = img;
            end
            a.fileprefix = this.sessionData.aifsOnAtlas('typ', 'fp', 'tags', [this.blurTag this.regionTag]);
            a = imagingType(ipr.typ, a);
        end 
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

