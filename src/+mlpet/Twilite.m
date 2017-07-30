classdef Twilite < mlpet.AbstractTwilite
	%% TWILITE  

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
        
    methods (Static)
        function this = load(varargin)
            this = mlpet.Twilite(varargin{:});
        end
    end
    
    methods 
        
        %%
        
        function this = crossCalibrate(this, varargin)
            cc = mlpet.CrossCalibrator(this, varargin{:});
            this.efficiencyFactor_ = cc.efficiencyFactor;
        end
        
 		function this = Twilite(varargin)
 			%% TWILITE
 			%  Usage:  this = Twilite()

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'efficiencyFactor', 0.5*147.95, @isnumeric);
            parse(ip, varargin{:});
            
 			this = this@mlpet.AbstractTwilite(varargin{:});
            
            this = this.readtable;
            this = this.updateTimingData;
            this.counts = this.tableTwilite2counts;
            assert(length(this.counts) == length(this.taus), 'mlpet:arraySizeMismatch', 'Twilite.ctor');            
            
            this.efficiencyFactor_ = ip.Results.efficiencyFactor;          
            this.becquerelsPerCC = this.efficiencyFactor*(this.counts - this.countsBaseline)./this.taus./this.visibleVolume;
        end        
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        twiliteCalibration_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

