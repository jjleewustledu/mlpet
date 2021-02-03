classdef AugmentedData < handle
	%% AUGMENTEDDATA  

	%  $Revision$
 	%  was created 31-Jan-2021 12:30:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.9.0.1570001 (R2020b) Update 4 for MACI64.  Copyright 2021 John Joowon Lee.

    
    properties
        Dt_aif
    end
    
	methods (Static)
        function Dt = DTimeToShift(varargin)
            %% Dt by which to shift arterial to match diff(scanner):  Dt < 0 will shift left; Dt > 0 will shift right.
            %  Adjusts for ipr.counter.datetime0 ~= ipr.scanner.datetime0.
            
            ip = inputParser;
            addRequired(ip, 'counter')
            addRequired(ip, 'scanner')
            parse(ip, varargin{:})
            ipr = ip.Results;            
            c = ipr.counter;
            s = ipr.scanner;
            
            Dt = c.Dt;
        end
        function Dt_ = DTimeToShiftAifs(varargin)
            %% @return Dt by which to shift counter2 to match counter.
            
            ip = inputParser;
            addRequired(ip, 'counter')
            addRequired(ip, 'counter2')
            addRequired(ip, 'scanner')
            addRequired(ip, 'scanner2')
            parse(ip, varargin{:})
            ipr = ip.Results;
            c = ipr.counter;
            c2 = ipr.counter2;
            s = ipr.scanner;
            s2 = ipr.scanner2;
            
            if isa(ipr.counter, 'mlswisstrace.TwiliteDevice')
                t = 0:c.timeWindow;
            else
                t = asrow(c.times);
            end
            activity = asrow(c.activityDensity());
            
            if isa(ipr.counter2, 'mlswisstrace.TwiliteDevice')
                t2 = 0:c2.timeWindow;
            else
                t2 = asrow(ipr.counter2.times);
            end
            activity2 = asrow(ipr.counter2.activityDensity());
            
            unif_t = 0:max([t t2]);
            unif_activity = makima(t, activity, unif_t);
            unif_activity2 = makima(t2, activity2, unif_t);
              
            % shift activity in time to match inflow with activity2
            % use 0.1 of max since counter SNR >> 10 
            [~,idx] = max(unif_activity > 0.5*max(unif_activity));
            [~,idx2] = max(unif_activity2 > 0.5*max(unif_activity2));
            
            Dc2s2 = seconds(c2.datetime0 - s2.datetime0); % -18 s, to align c2 on s2
            Dori2 = -(unif_t(idx2) + Dc2s2); % -(23 - 18) = -5 s, to place c2 at origin
            Dcs = seconds(c.datetime0 - s.datetime0); % 0 s, to align c on s
            Dori = -(unif_t(idx) + Dcs); % -(8 + 0) = -8 s, to place c at origin
            Dt_ = Dori2 - Dori; % -5 + 8 = 3 s
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
            addParameter(ip, 'counter', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'counter2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'roi2', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'Dt_aif', 0, @isscalar)
            addParameter(ip, 'fracMixing', 0.5, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            Dt_aif = ipr.Dt_aif;
            
            % scanners provide calibrations, ancillary data            
            
            scanner = ipr.scanner.volumeAveraged(ipr.roi);
            scan = ipr.scanner.activityDensity();
            scanner2 = ipr.scanner2.volumeAveraged(ipr.roi2);            
            scan2 = ipr.scanner2.activityDensity();
            
            % counters also have calibrations
            
            c = ipr.counter;
            aif = c.activityDensity();         
            c2 = ipr.counter2;
            aif2 = c2.activityDensity();
            
            % reconcile timings  
              
            if isa(c, 'mlswisstrace.TwiliteDevice')
                t_c = 0:c.timeWindow;
            else
                t_c = c.times;
            end
            if isa(c, 'mlswisstrace.TwiliteDevice')
                t_c2 = 0:c2.timeWindow;
            else
                t_c2 = c2.times;
            end
            
            if Dt_aif < 0 % shift aif2, scan2 to left             
                Dt = AugmentedData.DTimeToShift(c, scanner);
                aif = makima(t_c + Dt, aif, 0:scanner.times(end));
                aif2 = makima(t_c2 + Dt_aif, aif2, 0:scanner.times(end));
                scan2 = makima(scanner2.times + Dt_aif, scan2, scanner.times); 
                timesMid_ = scanner.timesMid;
            else % shift aif, scan to left
                Dt2 = AugmentedData.DTimeToShift(c2, scanner2);
                aif2 = makima(t_c2 + Dt2, aif2, 0:scanner2.times(end));
                aif = makima(t_c - Dt_aif, aif, 0:scanner2.times(end));
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
        function [tac_,timesMid_,aif_] = mixTacsAifs(varargin)
            
            import mlpet.AugmentedData
            import mlpet.AugmentedData.mix
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'scanner2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'counter', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'counter2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'roi2', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'Dt_aif', 0, @isscalar)
            addParameter(ip, 'fracMixing', 0.5, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            Dt_aif = ipr.Dt_aif;
            
            % scanners provide calibrations, ancillary data            
            
            scanner = ipr.scanner.volumeAveraged(ipr.roi);
            tac = scanner.activityDensity();
            scanner2 = ipr.scanner2.volumeAveraged(ipr.roi2);            
            tac2 = scanner2.activityDensity();
            
            % counters also have calibrations
            
            c = ipr.counter;
            aif = c.activityDensity();         
            c2 = ipr.counter2;
            aif2 = c2.activityDensity();
            
            % reconcile timings  
              
            if isa(c, 'mlswisstrace.TwiliteDevice')
                t_c = 0:c.timeWindow;
            else
                t_c = c.times;
            end
            if isa(c, 'mlswisstrace.TwiliteDevice')
                t_c2 = 0:c2.timeWindow;
            else
                t_c2 = c2.times;
            end
            
            if Dt_aif < 0 % shift aif2, tac2 to left           
                Dt = AugmentedData.DTimeToShift(c, scanner);
                aif = makima(t_c + Dt, aif, 0:scanner.times(end));
                aif2 = makima(t_c2 + Dt_aif, aif2, 0:scanner.times(end));
                tac2 = makima(scanner2.times + Dt_aif, tac2, scanner.times); 
                timesMid_ = scanner.timesMid;
            else % shift aif, tac to left
                Dt2 = AugmentedData.DTimeToShift(c2, scanner2);
                aif2 = makima(t_c2 + Dt2, aif2, 0:scanner2.times(end));
                aif = makima(t_c - Dt_aif, aif, 0:scanner2.times(end));
                tac = makima(scanner.times - Dt_aif, tac, scanner2.times);  
                timesMid_ = scanner2.timesMid;
            end 
            aif(aif < 0) = 0;
            tac(tac < 0) = 0;
            aif2(aif2 < 0) = 0;
            tac2(tac2 < 0) = 0;
            
            tac_ = mix(tac, tac2, ipr.fracMixing); % calibrated, decaying
            aif_ = mix(aif, aif2, ipr.fracMixing);
        end
        function aif_ = mixAifs(varargin)
            
            import mlpet.AugmentedData            
            import mlpet.AugmentedData.mix
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'scanner2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'counter', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'counter2', [], @(x) isa(x, 'mlpet.AbstractDevice'))
            addParameter(ip, 'roi', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'roi2', [], @(x) isa(x, 'mlfourd.ImagingContext2'))
            addParameter(ip, 'Dt_aif', 0, @isscalar)
            addParameter(ip, 'fracMixing', 0.5, @isscalar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            Dt_aif = ipr.Dt_aif;
            
            % scanners provide calibrations, ancillary data            
            
            scanner = ipr.scanner.volumeAveraged(ipr.roi);
            scanner2 = ipr.scanner2.volumeAveraged(ipr.roi2);
            
            % counters also have calibrations
            
            c = ipr.counter;
            aif = c.activityDensity();         
            c2 = ipr.counter2;
            aif2 = c2.activityDensity();
            
            % reconcile timings  
            
            if isa(c, 'mlswisstrace.TwiliteDevice')
                t_c = 0:c.timeWindow;
            else
                t_c = c.times;
            end
            if isa(c, 'mlswisstrace.TwiliteDevice')
                t_c2 = 0:c2.timeWindow;
            else
                t_c2 = c2.times;
            end
              
            if Dt_aif < 0 % shift aif2 to left              
                Dt = AugmentedData.DTimeToShift(c, scanner);
                aif = makima(t_c + Dt, aif, 0:scanner.times(end));
                aif2 = makima(t_c2 + Dt_aif, aif2, 0:scanner.times(end));
            else % shift aif to left
                Dt2 = AugmentedData.DTimeToShift(c2, scanner2);
                aif2 = makima(t_c2 + Dt2, aif2, 0:scanner2.times(end));
                aif = makima(t_c - Dt_aif, aif, 0:scanner2.times(end));
            end 
            aif(aif < 0) = 0;
            aif2(aif2 < 0) = 0;
            
            aif_ = mix(aif, aif2, ipr.fracMixing);
        end
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

