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
        function ef   = efficiencyFactor(this)
            ef = this.reference_.calibrationMeasurement / this.toCalibrate_.calibrationMeasurement;
        end
		  
 		function this = CrossCalibrator(varargin)
 			%% CROSSCALIBRATOR
            %  @params named reference must be one of:
            %  mlpipeline.IXlsxObjScanData, mlpet.IScanner, mlpet.IAifData, mlpet.IBloodData
            %  @params toCalibrate 
 			
            ip = inputParser;
            addRequired(ip,  'toCalibrate',     @(x) isa(x, 'mlpet.IScannerData') || ...
                                                     isa(x, 'mlpet.IAifData') || ...
                                                     isa(x, 'mlpet.IBloodData') || ...
                                                     isa(x, 'mlpet.IWellData'));
            addParameter(ip, 'reference', [], @(x)   isa(x, 'mlpipeline.IXlsxObjScanData') || ...
                                                     isa(x, 'mlpet.IScannerData') || ...
                                                     isa(x, 'mlpet.IAifData') || ...
                                                     isa(x, 'mlpet.IBloodData') || ...
                                                     isa(x, 'mlpet.IWellData'));
            parse(ip, varargin{:});            
            
            this.toCalibrate_ = ip.Results.toCalibrate;
            this.reference_   = ip.Results.reference;
 		end
    end
    
    properties (Access = private)
        reference_
        toCalibrate_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

