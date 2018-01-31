classdef AbstractAifBuilder 
	%% ABSTRACTAIFBUILDER  

	%  $Revision$
 	%  was created 09-Jan-2018 16:29:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		product
 	end

	methods 
        
        %% GET
        
        function g = get.product(this)
            g = this.product_;
        end
        
        %%
		  
 		function this = AbstractAifBuilder(varargin)
 			%% ABSTRACTAIFBUILDER
 			%  @param sessionData
            %  @param scannerData
            %  @param manualData
            %  @param dtNyquist
            %  @param calibrationBuilder

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'scannerData', @(x) isa(x, 'mlpet.IScannerData'));
            addParameter(ip, 'manualData',  @(x) isa(x, 'mldata.IManualMeasurements'));
            addParameter(ip, 'dtNyquist', 1, @isnumeric);
            addParameter(ip, 'calibrationBuilder', @(x) isa(x, 'mlpet.ICalibrationBuilder'));
            parse(ip, varargin{:});
            
            this.sessionData_        = ip.Results.sessionData;
            this.scannerData_        = ip.Results.scannerData;
            this.manualData_         = ip.Results.manualData;
            this.dtNyquist_          = ip.Results.dtNyquist;
            this.calibrationBuilder_ = ip.Results.calibrationBuilder;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        calibrationBuilder_
        dtNyquist_
        manualData_
        product_
        scannerData_
        sessionData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

