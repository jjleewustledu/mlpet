classdef MultiBolusData < handle & mldata.TimingData
	%% TWILITETIMINGDATA  

	%  $Revision$
 	%  was created 03-Feb-2018 15:41:44 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties (Constant)
        MIN_DELTA_BOLUS = 60
    end
    
	properties (Dependent)
        activity % used to identify boluses
        activityHalflife
        activityLifetime
        doMeasureBaseline
        expectedBaseline
    end

	methods 
        
        %% GET, SET
        
        function g = get.activity(this)
            g = this.activity_(this.index0:this.indexF);
        end
        function g = get.activityHalflife(this)
            g = this.radionuclides_.halflife;
        end
        function g = get.activityLifetime(this)
            g = this.radionuclides_.lifetime;
        end
        function g = get.doMeasureBaseline(this)
            g = this.doMeasureBaseline_;
        end
        function g = get.expectedBaseline(this)
            g = this.expectedBaseline_;
        end
        
        %%		  
        
        function [m,s] = baseline(this, varargin)
            %  @param optional activity is numeric.
            %  @param named expectedBaseline is numeric, defaulting to this.expectedBaseline.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'expectedBaseline', this.expectedBaseline, @isnumeric);
            addParameter(ip, 'doMeasureBaseline', this.doMeasureBaseline, @islogical);
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            this.expectedBaseline_ = ipr.expectedBaseline;
            this.doMeasureBaseline_ = ipr.doMeasureBaseline;
            if (~this.doMeasureBaseline_)
                m = this.expectedBaseline_;
                s = sqrt(m);
                return
            end
            
            [m,s] = this.baselineTimeForward(varargin{:});
            if (m > 2*ipr.expectedBaseline + 5*s)
                [m,s] = this.baselineTimeReversed;
            end
            assert(m < 2*ipr.expectedBaseline + 5*s, ...
                'mlpet:RuntimeError', 'MultiBolusData.baseline could not find a baseline')
        end
        function [m,s] = baselineTimeForward(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addOptional(ip, 'activity', this.activity, @isnumeric);
            parse(ip, varargin{:});            
            a = ip.Results.activity;
            
            [~,idxBolusInflow] = max(a > a(1) + std(a));
            early = a(1:idxBolusInflow-2);
            if (isempty(early))
                early = a(1);
            end
            m = mean(early);
            s = std( early);           
        end
        function [m,s] = baselineTimeReversed(this, varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addOptional(ip, 'activity', this.activity, @isnumeric);
            parse(ip, varargin{:});  
            [m,s] = this.baselineTimeForward(flip(ip.Results.activity));
        end
        function [bols,base]  = boluses(this)
            %% BOLUSES 
            %  @return bols have m := this.baseline removed.
            %  @return bols is composite of mlpet.MultiBolusData.
            %  @return base is baseline that was remvoed.
            
            NSTD  = 10; % heuristic
            HWHH  = 6;  % 
            [m,s] = this.baseline;
            a     = this.activity - m;
            t     = this.datetime;
            b     = 1;
            while (max(a) > NSTD*s)
                [~,bstart] = max(a > NSTD*s);
                [~,deltab] = max(a(bstart:end) < -s); % duration for return to baseline
                deltab     = this.ensurePlausibleDeltab( ...
                             deltab, length(a(bstart:end))-1); % manage common deltab pathologies
                bols(b)    = mlpet.MultiBolusData( ...
                    'activity', a(bstart:bstart+deltab), ...
                    'times',    t(bstart:bstart+deltab), ...
                    'dt',       this.dt); %#ok<AGROW>
                a = a(bstart+deltab+HWHH:end);
                t = t(bstart+deltab+HWHH:end);
                b = b + 1;
            end
            base = m;
        end
        function [bol,base] = findBolusFrom(this, doseAdminDatetime)
            %% FINDBOLUSFROM boluses have m := this.baseline removed.
            %  @param doseAdminDatetime determines the bolus to find, which begins at or later than doseAdminDatetime.
            %  @return bol is mlpet.MultiBolusData.
            %  @return base is baseline that was remvoed.
            
            [bols,base] = this.boluses;
            b = 1;
            while (b <= length(bols))
                if (doseAdminDatetime <= bols(b).datetime0)
                    bol      = bols(b);                                           
                    [~,idx0] = max(doseAdminDatetime < this.datetime);
                    [~,idxF] = max(bol.datetimeF     < this.datetime);
                       idxF  = min(idxF, idx0 + this.activityLifetime/this.dt);
                    a        = this.activity - this.baseline;
                    t        = this.datetime;
                    bol = mlpet.MultiBolusData( ...
                        'activity',  a(idx0:idxF), ...
                        'times',     t(idx0:idxF), ...
                        'datetimeMeasured', doseAdminDatetime, ...
                        'dt',        bol.dt); 
                    return
                end
                b = b + 1;
            end
            bol = bols(b-1);
        end
        function [cal,base] = findCalibrationFrom(this, scanStart)
            %% @scanStart is the datetime at which the calibration emission scan starts.
            %  @return cal is mlpet.MultiBolusData.
            %  @return base is baseline that was remvoed.
            
            [m,s] = this.baseline;
            a     = this.activity - m;
            t     = this.datetime;
            [~,bstart] = max(t >= scanStart);
            [~,deltab] = max(a(bstart:end) < a(bstart)/2); % duration for return to 1/2 initial emissions
            deltab     = this.ensurePlausibleDeltab( ...
                         deltab, length(a(bstart:end))-1); % manage common deltab pathologies            
            cal = mlpet.MultiBolusData( ...
                'activity', a(bstart:bstart+deltab), ...
                'times',    t(bstart:bstart+deltab), ...
                'datetimeMeasured', scanStart, ...
                'dt',       this.dt);
            base = m;
        end
        function         plot(this, varargin)
            figure;
            plot(this.datetime, this.activity, varargin{:});
            xlabel('this.datetime');
            ylabel('this.activities');
            title(sprintf('MultiBolusData:  time0->%g, timeF->%g', this.time0, this.timeF), 'Interpreter', 'none');
        end
                
 		function this = MultiBolusData(varargin)
 			%% TWILITETIMINGDATA
            %  @param named activity is numeric.

 			this = this@mldata.TimingData(varargin{:});            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'activity', [], @isnumeric);
            addParameter(ip, 'expectedBaseline', 90, @isnumeric);
            addParameter(ip, 'doMeasureBaseline', true, @islogical);
            addParameter(ip, 'radionuclides', @(x) isa(x, 'mlpet.Radionuclides'))
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            this.activity_ = ipr.activity;
            this.expectedBaseline_ = ipr.expectedBaseline;
            this.doMeasureBaseline_ = ipr.doMeasureBaseline;
            
            if (isempty(this.activity_))
                this.activity_ = nan(size(this.times_));
            end
            if (isempty(this.times))
                this.times = 0:this.dt:this.dt*(length(this.activity_)-1); % empty for empty activity_
            end
            this.radionuclides_ = ipr.radionuclides;
 		end
 	end 

    %% PRIVATE
    
    properties (Access = private)
        activity_
        doMeasureBaseline_
        expectedBaseline_
        radionuclides_
    end
    
    methods (Access = private)        
        function db = ensurePlausibleDeltab(this, db, bestGuess)
            %  When db == 1 over len samples, it's likely that the calculation of db failed.   Use the best guess.
            %  @param db is numeric.
            %  @param bestGuess is numeric.
            
            life = this.activityLifetime/this.dt;
            minBestGuess = min(bestGuess, life);
            if (1 == db)
                db = bestGuess;
                return
            end
            if (db > life)
                db = minBestGuess;
                return
            end
            assert(db > this.MIN_DELTA_BOLUS, ...
                'mlpet:RuntimeError', 'MultiBolusData.ensurePlausibleDeltab found bolus of duration %g sec', db)
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

