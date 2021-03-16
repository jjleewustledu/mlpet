classdef (Abstract) AugmentedData < handle
	%% AUGMENTEDDATA  

	%  $Revision$
 	%  was created 31-Jan-2021 12:30:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.9.0.1570001 (R2020b) Update 4 for MACI64.  Copyright 2021 John Joowon Lee.

    
    properties (Abstract)
        Delta
        Dt
    end
    
    properties (Dependent)
        tBuffer
    end
    
    properties
        Dt_aif
    end
    
	methods (Static)
        function Dt_ = DTimeToShiftAifs(varargin)
            %% @return Dt by which to shift arterial2 to match arterial.
            
            ip = inputParser;
            addRequired(ip, 'arterialDev')
            addRequired(ip, 'arterialDev2')
            parse(ip, varargin{:})
            ipr = ip.Results;
            dev = ipr.arterialDev;
            dev2 = ipr.arterialDev2;
            top = dev.threshOfPeak;
            
            % match radial-artery bolus to radial-artery bolus
            t = dev.times(dev.index0:dev.indexF) - dev.time0;
            t2 = dev2.times(dev2.index0:dev2.indexF) - dev2.time0;            
            unifTimes = 0:max([t t2]);
            act = makima(t, dev.activityDensity(), unifTimes);
            act2 = makima(t2, dev2.activityDensity(), unifTimes);
            [~,idx] = max(act > top*max(act));
            [~,idx2] = max(act2 > top*max(act2));               
            Dt_ = unifTimes(idx) - unifTimes(idx2);
        end
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
            addParameter(ip, 'Dt_aif', 0, @isscalar)
            addParameter(ip, 'fracMixing', 0.9, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            Dt_aif = ipr.Dt_aif;
            
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
            
            if Dt_aif < 0 % shift aif2, scan2 to left             
                aif = makima(t_a + a.Dt, aif, 0:scanner.times(end));
                aif2 = makima(t_a2 + a2.Dt + Dt_aif, aif2, 0:scanner.times(end));
                scan2 = makima(scanner2.times + Dt_aif, scan2, scanner.times); 
                timesMid_ = scanner.timesMid;
            else % shift aif, scan to left
                aif2 = makima(t_a2 + a2.Dt, aif2, 0:scanner2.times(end));
                aif = makima(t_a + a.Dt - Dt_aif, aif, 0:scanner2.times(end));
                scan = makima(scanner.times - Dt_aif, scan, scanner2.times);  
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
            RR = mlraichle.RaichleRegistry.instance();
            
            % scannerDevs provide calibrations & ROI-volume averaging            
            s = ipr.scanner.volumeAveraged(ipr.roi);
            tac = s.activityDensity();
            tac(tac < 0) = 0;                       
            tac = RR.normalizationFactor*tac; % empirical normalization
            tac__ = tac;
            timesMid__ = s.timesMid;
            
            % arterialDevs calibrate & align arterial times-series to localized scanner time-series            
            a0 = ipr.arterial;
            [a, datetimePeak] = devkit.alignArterialToScanner(a0, s, 'sameWorldline', false);
            aif = a.activityDensity();
            t = a.times(a.index0:a.indexF) - a.time0 - seconds(s.datetime0 - a.datetime0);
            
            % extrapolate aif beyond cliff
            if isfinite(ipr.arterial.timeCliff)
                Nt = ceil(timesMid__(end));
                Na = length(aif);
                tacint = interp1(timesMid__, tac__, 0:Nt-1);
                indexCliff = ipr.arterial.timeCliff + 1;
                fracCliff = aif(indexCliff) / tacint(indexCliff);
                aif(indexCliff:Na) = fracCliff * tacint(indexCliff:Na);
                aif(Na+1:Nt) = fracCliff * tacint(Na+1:Nt);
                t = (0:Nt-1) - seconds(s.datetime0 - a.datetime0);
            end
            
            % use tBuffer to increase fidelity of kinetic model
            while any(-RR.tBuffer == t)
                RR.T = RR.T + 1;
            end
            aif = interp1([-RR.tBuffer t], [0 aif], -RR.tBuffer:s.timesMid(end), 'linear', 0);
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
            addParameter(ip, 'Dt_aif', 0, @isscalar) % sec > 0
            addParameter(ip, 'fracMixing', 0.9, @isscalar)
            parse(ip, devkit, devkit2, varargin{:})
            ipr = ip.Results;
            s = ipr.scanner;
            s2 = ipr.scanner2;
            RR = mlraichle.RaichleRegistry.instance();
            
            % align aif with tac, aif2 with tac2
            [tac,timesMid,aif,Dt,datetimePeak] = mixTacAif(devkit, ...
                                                           'scanner', ipr.scanner, ...
                                                           'arterial', ipr.arterial, ...
                                                           'roi', ipr.roi);                                                
            [tac2,timesMid2,aif2,~,datetimePeak2] = mixTacAif(devkit2, ...
                                                              'scanner', ipr.scanner2, ...
                                                              'arterial', ipr.arterial2, ...
                                                              'roi', ipr.roi2);
            offset = round(seconds(datetimePeak - s.datetime0) - ...
                           seconds(datetimePeak2 - s2.datetime0) + ...
                           ipr.Dt_aif);                       

            % extrapolate aifs beyond cliffs
            if isfinite(ipr.arterial.timeCliff)
                Nt = ceil(timesMid(end));
                Na = length(aif);
                tacint = interp1(timesMid, tac, 0:Nt-1);
                indexCliff = ipr.arterial.timeCliff + 1;
                fracCliff = aif(indexCliff) / tacint(indexCliff);
                aif(indexCliff:Na) = fracCliff * tacint(indexCliff:Na);
                aif(Na+1:Nt) = fracCliff * tacint(Na+1:Nt);
            end            
            if isfinite(ipr.arterial2.timeCliff)
                Nt2 = ceil(timesMid2(end));
                Na2 = length(aif2);
                tacint2 = interp1(timesMid2, tac2, 0:Nt2-1);
                indexCliff2 = ipr.arterial2.timeCliff + 1;
                fracCliff2 = aif(indexCliff2) / tacint2(indexCliff2);
                aif2(indexCliff2:Na2) = fracCliff2 * tacint2(indexCliff2:Na2);
                aif2(Na2+1:Nt2) = fracCliff2 * tacint2(Na2+1:Nt2);
            end
            
            % align tac2 with tac
            tac = interp1([-1 s.timesMid], [0 tac], s.timesMid(1):s.timesMid(end), 'linear', 0);
            tac2 = interp1((offset + [-1 s2.timesMid]), [0 tac2], s.timesMid(1):s.timesMid(end), 'linear', 0);
            tac__ = mix(tac, tac2, ipr.fracMixing); 
            tac__ = interp1(s.timesMid(1):s.timesMid(end), tac__, s.timesMid, 'linear', 0);
            tac__(tac__ < 0) = 0;                       
            tac__ = RR.normalizationFactor*tac__; % empirical normalization
            timesMid__ = timesMid;
            
            % align aif2 with aif
            n = length(aif);
            n2 = length(aif2);
            aif2 = interp1(offset + (0:n2-1), aif2, 0:n-1, 'linear', 0);
            aif__ = mix(aif, aif2, ipr.fracMixing); 
            aif__(aif__ < 0) = 0;  
        end
        function aif_ = mixAifs(varargin)
            
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
            addParameter(ip, 'Dt_aif', 0, @isscalar)
            addParameter(ip, 'fracMixing', 0.9, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            Dt_aif = ipr.Dt_aif;
            
            % scanners provide calibrations, ancillary data            
            
            scanner = ipr.scanner.volumeAveraged(ipr.roi);
            scanner2 = ipr.scanner2.volumeAveraged(ipr.roi2);
            
            % arterials also have calibrations
            
            a = ipr.arterial;
            aif = a.activityDensity();         
            a2 = ipr.arterial2;
            aif2 = a2.activityDensity();
            
            % reconcile timings  
            
            t_a = 0:a.timeWindow;
            t_a2 = 0:a2.timeWindow;
              
            if Dt_aif < 0 % shift aif2 to left              
                aif = makima(t_a + a.Dt, aif, 0:scanner.times(end));
                aif2 = makima(t_a2 + a2.Dt + Dt_aif, aif2, 0:scanner.times(end));
            else % shift aif to left
                aif2 = makima(t_a2 + a2.Dt, aif2, 0:scanner2.times(end));
                aif = makima(t_a + a.Dt - Dt_aif, aif, 0:scanner2.times(end));
            end 
            aif(aif < 0) = 0;
            aif2(aif2 < 0) = 0;
            
            aif_ = mix(aif, aif2, ipr.fracMixing);
        end
    end 
    
    methods 
        
        %% GET
        
        function g = get.tBuffer(~)
            RR = mlraichle.RaichleRegistry.instance();
            g = RR.tBuffer;
        end
        
        %%
        
		function a = artery_local(this, varargin)
            %% ARTERY_LOCAL
            %  @param typ is understood by imagingType.
            %  @return a is an imagingType.
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

