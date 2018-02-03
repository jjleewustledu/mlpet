classdef TimeSeries 
	%% TIMESERIES  

	%  $Revision$
 	%  was created 26-Jan-2018 18:05:43 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
        activity
 		dt
        times
        datetime0
        datetimeF
    end
    
    properties
        expectedBaseline = 100
    end

	methods 
        
        %% GET, SET
        
        function g = get.activity(this)
            g = this.activity_;
        end
        function g = get.dt(this)
            g = this.dt_;
        end
        function g = get.times(this)
            g = this.times_;
        end
        function g = get.datetime0(this)
            g = this.datetime0_;
        end
        function this = set.datetime0(this, s)
            assert(isdatetime(s));
            this.datetime0_ = s;
        end
        function g = get.datetimeF(this)
            g = this.datetimeF_; % this.datetime0_ + seconds(this.times(end) - this.times(1));
        end
        function this = set.datetimeF(this, s)
            assert(isdatetime(s));
            this.datetimeF_ = s;
        end
        
        %%
		  
        function [m,s] = baseline(this, varargin)
            ip = inputParser;
            addOptional(ip, 'activity', this.activity, @isnumeric);
            parse(ip, varargin{:});            
            a = ip.Results.activity;
            
            [~,idxBolusInflow] = max(a > a(1) + std(a));
            early = a(1:idxBolusInflow-2);
            m = mean(early);
            s = std( early);
        end
        function [m,s] = baselineTimeReversed(this)
            [m,s] = this.baseline(flip(this.activity));
        end
        function bols = boluses(this)
            %% BOLUSES have baselines removed.
            
            NSTD  = 10;
            [m,s] = this.baseline;
            if (m > 2*this.expectedBaseline)
                [m,s] = this.baselineTimeReversed;
                assert(m < 2*this.expectedBaseline);
            end
            a     = this.activity - m;
            t     = this.datetime0 + seconds(this.times);
            b     = 1;
            
            while (max(a) > NSTD*s)
                [~,bstart] = max(a > NSTD*s);
                [~,deltab] = max(a(bstart:end) < -s);
                %bstart  = bstart - 5;
                bols(b) = mlpet.TimeSeries(a(bstart:bstart+deltab), t(bstart:bstart+deltab), 'dt', this.dt); %#ok<AGROW>
                a = a(bstart+deltab+6:end);
                t = t(bstart+deltab+6:end);
                b = b + 1;
            end
        end
        function dt_  = datetime(this)
            if (isempty(this.datetime0_))
                dt_ = [];
                return
            end
            dt_ = this.datetime0_ + seconds(this.times);
        end
        function bol  = findBolus(this, doseAdminDatetime)
            %% FINDBOLUS boluses have baselines removed.
            
            bols = this.boluses;
            b = 1;
            while (b <= length(bols))
                if (doseAdminDatetime <= bols(b).datetime0)
                    bol = bols(b);
                    return
                end
                b = b + 1;
            end
            error('mlpet:searchFailed', 'TimeSeries.findBolus');
        end
        function        plot(this, varargin)
            figure;
            plot(this.times, this.activities, varargin{:});
            xlabel('this.times');
            ylabel('this.activities');
            title(['TimeSeries:  datetime0->%s, datetimeF->%s' this.datetime0 this.datetimeF], 'Interpreter', 'none');
        end
        
 		function this = TimeSeries(varargin)
 			%% TIMESERIES
            %  @param required activity is numeric.
            %  @param optional times is numeric or datetime; defaults to 1:length(activity).
            %  @param named dt is numeric, default := 1.

            ip = inputParser;
            addRequired(ip, 'activity', @isnumeric);
            addOptional(ip, 'times', [], @(x) isnumeric(x) || isdatetime(x));
            addParameter(ip, 'dt', 1, @isnumeric);
            parse(ip, varargin{:});
            
            this.activity_ = ip.Results.activity;
            this.dt_ = ip.Results.dt;
            if (isempty(ip.Results.times))
                this.times_ = 0:this.dt_:this.dt_*(length(this.activity_)-1);
            else
                this.times_ = ip.Results.times;
            end
            if (isdatetime(this.times_))
                this.datetime0_ = this.times_(1);
                this.times_     = seconds(this.times_ - this.times_(1));
                this.datetimeF_ = this.datetime0_ + seconds(this.times(end) - this.times(1));
            end
 		end
    end 

    %% PRIVATE
    
    properties (Access = private)
        activity_
        dt_
        times_
        datetime0_
        datetimeF_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

