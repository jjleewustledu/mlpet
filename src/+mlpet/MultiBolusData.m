classdef MultiBolusData < mldata.TimingData
	%% TWILITETIMINGDATA  

	%  $Revision$
 	%  was created 03-Feb-2018 15:41:44 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
        activity % used to identify boluses
        expectedBaseline
    end

	methods 
        
        %% GET, SET
        
        function g = get.activity(this)
            g = this.activity_(this.index0:this.indexF);
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
            parse(ip, varargin{:});
            
            [m,s] = this.baselineTimeForward(varargin{:});
            if (m > 2*ip.Results.expectedBaseline)
                [m,s] = this.baselineTimeReversed;
                assert(m < 2*ip.Results.expectedBaseline);
            end
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
        function bols  = boluses(this)
            %% BOLUSES 
            %  @return bols have m := this.baseline removed.
            
            NSTD  = 10;
            [m,s] = this.baseline;
            a     = this.activity - m;
            t     = this.datetime;
            b     = 1;
            while (max(a) > NSTD*s)
                [~,bstart] = max(a > NSTD*s);
                [~,deltab] = max(a(bstart:end) < -s);
                bols(b)    = mlpet.MultiBolusData( ...
                    'activity', a(bstart:bstart+deltab), ...
                    'times',    t(bstart:bstart+deltab), ...
                    'dt',       this.dt); %#ok<AGROW>
                a = a(bstart+deltab+6:end);
                t = t(bstart+deltab+6:end);
                b = b + 1;
            end
        end
        function bol   = findBolusFrom(this, doseAdminDatetime)
            %% FINDBOLUSFROM boluses have baselines removed.
            %  @param doseAdminDatetime determines the bolus to find, which begins at or later than doseAdminDatetime.
            
            bols = this.boluses;
            b = 1;
            while (b <= length(bols))
                if (doseAdminDatetime <= bols(b).datetime0)
                    bol      = bols(b);                                           
                    [~,idx0] = max(doseAdminDatetime < this.datetime);
                    [~,idxF] = max(bol.datetimeF     < this.datetime);
                    a        = this.activity - this.baseline;
                    t        = this.datetime;
                    bol = mlpet.MultiBolusData( ...
                        'activity',  a(idx0:idxF), ...
                        'times',     t(idx0:idxF), ...
                        'datetime0', doseAdminDatetime, ...
                        'dt',        bol.dt); 
                    return
                end
                b = b + 1;
            end
            error('mlpet:searchFailed', 'MultiBolusData.findBolusFrom');
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
            addParameter(ip, 'expectedBaseline', 100, @isnumeric);
            parse(ip, varargin{:});            
            this.activity_ = ip.Results.activity;
            this.expectedBaseline_ = ip.Results.expectedBaseline;
            
            if (isempty(this.activity_))
                this.activity_ = nan(size(this.times_));
            end
            if (isempty(this.times_))
                this.times_ = 0:this.dt_:this.dt_*(length(this.activity_)-1); % empty for empty activity_
            end
 		end
 	end 

    %% PRIVATE
    
    properties (Access = private)
        activity_
        expectedBaseline_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

