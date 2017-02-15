classdef Caprac < mlpipeline.AbstractDataBuilder & mlpet.ICapracData 
	%% CAPRAC  

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties 
        dryWeight % as col vector
        wetWeight % as col vector
        drawn     % datetime
        counted   % datetime
        counts    % as col vector
    end 
    
	properties (Dependent)
        datetimeDrawn
        DACGe68        
%         drawnMin   % as col vector
%         drawnSec   % as col vector
%         countedMin % as col vector
%         countedSec % as col vector
%         nSyringes  % quantity of syringes used
    end
    
    methods %% GET/SET
        function g = get.datetimeDrawn(this)
            g = this.CCIRRadMeasurementsTable_.TIMEDRAWN_Hh_mm_ss;
            g.TimeZone = 'local';
            g = [g(7:31); g(42:48)];
        end
        function g = get.DACGe68(this)
            g = this.CCIRRadMeasurementsTable_.DECAY_APERTURECORRGE_68_Kdpm_G;
            g = [g(7:31); g(42:48)];
        end
    end
      
	methods 		  
 		function this = Caprac(varargin)
 			%% CAPRAC
 			%  Usage:  this = Caprac()

            this = this@mlpipeline.AbstractDataBuilder(varargin{:});            
 			this.CCIRRadMeasurementsTable_ = readtable(this.sessionData.CCIRRadMeasurementsTable);            
        end
        
        function this = crossCalibrate(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.IScanner'));
            addParameter(ip, 'wellCounter', [], @(x) isa(x, 'mlpet.IBloodData'));
            addParameter(ip, 'aifSampler', this, @(x) isa(x, 'mlpet.IAifData'));
            parse(ip, varargin{:});
            
            cc = mlpet.CrossCalibrator(varargin{:});
            this.efficiencyFactor_ = cc.wellCounterEfficiency;
        end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        efficiencyFactor_ = 1/0.9499
        CCIRRadMeasurementsTable_
    end

    %% HIDDEN, DEPRECATED
    
    properties (Hidden)        
        variableCountTime = nan
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

