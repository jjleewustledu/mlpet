classdef CrossCalibrator 
	%% CROSSCALIBRATOR  

	%  $Revision$
 	%  was created 07-Feb-2017 00:42:54
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

	methods 
		  
 		function this = CrossCalibrator(varargin)
 			%% CROSSCALIBRATOR
 			%  Usage:  this = CrossCalibrator()
 			
            ip = inputParser;
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.IScanner'));
            addParameter(ip, 'wellCounter', [], @(x) isa(x, 'mlpet.IBloodData'));
            addParameter(ip, 'aifSampler', this, @(x) isa(x, 'mlpet.IAifData'));
            parse(ip, varargin{:});
            
            
            this.scanner_     = ip.Results.scanner;
            this.wellCounter_ = ip.Results.wellCounter;
            this.aifSampler_  = ip.Results.aifSampler;
 		end
    end
    
    properties (Access = private)
        scanner_
        wellCounter_
        aifSampler_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

