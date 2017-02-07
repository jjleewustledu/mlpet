classdef Caprac < mlpet.ICapracData 
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
        drawnMin   % as col vector
        drawnSec   % as col vector
        countedMin % as col vector
        countedSec % as col vector
        nSyringes  % quantity of syringes used
    end
      
	methods 		  
 		function this = Caprac(varargin)
 			%% CAPRAC
 			%  Usage:  this = Caprac()

 			
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

    %% HIDDEN, DEPRECATED
    
    properties (Hidden)        
        variableCountTime = nan
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

