classdef TwiliteCalibration < mlpet.AbstractTwilite
	%% TWILITECALIBRATION  

	%  $Revision$
 	%  was created 19-Jul-2017 23:38:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
	methods 
        
        %%
		  
        function [m,s] = calibrationBaseline(this)
            %% CALIBRATIONBASELINE returns specific activity
            %  @returns m, mean
            %  @returns s, std
            
            cnts = this.counts.*this.taus;
            cnts = cnts(this.baselineRange_);
            sa   = cnts/this.arterialCatheterVisibleVolume;
            m    = mean(sa);
            s    = std(sa);
        end
        function [m,s] = calibrationMeasurement(this)
            %% CALIBRATIONMEASUREMENT returns specific activity without baseline
            %  @returns m, mean
            %  @returns s, std
            
            [m,s] = this.calibrationSample;
             m    = m - this.calibrationBackground;
        end
        function [m,s] = calibrationSample(this)
            %% CALIBRATIONSAMPLE returns specific activity
            %  @returns m, mean
            %  @returns s, std
            
            tzero  = this.times(this.samplingRange_(1));
            dccnts = this.decayCorrection_.correctedCounts(this.counts, tzero).*this.taus;
            dccnts = dccnts(this.samplingRange_);
            sa     = dccnts/this.arterialCatheterVisibleVolume;
            m      = mean(sa);
            s      = std(sa);
        end
        
 		function this = TwiliteCalibration(varargin)
 			%% TWILITECALIBRATION
       
 			this = this@mlpet.AbstractTwilite(varargin{:});
            
            this = this.readtable;
            this = this.updateTimingData;
            this.counts = this.tableTwilite2counts;
            assert(length(this.counts) == length(this.taus), 'mlpet:arraySizeMismatch', 'Twilite.ctor');
            
            this.decayCorrection_ = mlpet.DecayCorrection(this);
            this = this.findCalibrationIndices;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        baselineRange_ % time index
        decayCorrection_
        samplingRange_ % time index
    end
    
    methods (Access = protected)
        function this = findCalibrationIndices(this)
            minCnts = min(this.counts);
            cappedCnts = [minCnts*ones(1,5) this.counts minCnts*ones(1,5)];
            [~,tup]   = max(diff(smooth(cappedCnts))); % smoothing range = 5
            tup = tup - 5;
            [~,tdown] = min(diff(smooth(cappedCnts)));
            tdown = tdown - 5;
            smplRng   = tup:tdown;
            N = length(this.counts);
            Npre = smplRng(1);
            Npost = N - smplRng(end);
            if (Npre > Npost)
                baseRng = 1:smplRng(1)-1;
            else
                baseRng = smplRng(end)+1:N;
            end
            this.samplingRange_ = smplRng;
            this.baselineRange_ = baseRng;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end
