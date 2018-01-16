classdef AbstractScannerBuilder 
	%% ABSTRACTSCANNERBUILDER  

	%  $Revision$
 	%  was created 09-Jan-2018 16:29:33 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		calibrationBuilder
 	end

	methods 
        
        %% GET/SET
        
        function g = get.calibrationBuilder(this)
            g = this.calibrationBuilder_;
        end
        function this = set.calibrationBuilder(this, s)
            assert(isa(s, 'mlpet.ICalibrationBuilder'));
            this.calibrationBuilder_ = s;
        end
        
        %%
		  
 		function this = AbstractScannerBuilder(varargin)
 			%% ABSTRACTSCANNERBUILDER
            
            import mlpet.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'roisBuilder', @(x) isa(x, 'mlrois.IRoisBuilder'));
            addParameter(ip, 'calibrationBuilder', CalibrationBuilder, @(x) isa(x, 'mlpet.ICalibrationBuilder'));
            addParameter(ip, 'blindedData', @(x) isa(x, 'mlpipeline.IBlindedData'));
            parse(ip, varargin{:});
 			
            this.sessionData_ = ip.Results.sessionData;
            this.roisBuilder_ = ip.Resutls.roisBuilder;
            this.calibrationBuilder_ = ip.Resutls.calibrationBuilder;
            this.blindedData_ = ip.Results.blindedData;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        sessionData_
        roisBuilder_
        calibrationBuilder_
        blindedData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

