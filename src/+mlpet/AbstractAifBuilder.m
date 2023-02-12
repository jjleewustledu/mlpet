classdef AbstractAifBuilder 
	%% ABSTRACTAIFBUILDER is DEPRECATED 

	%  $Revision$
 	%  was created 09-Jan-2018 16:29:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		product
        sessionData
 	end

	methods 
        
        %% GET
        
        function g = get.product(this)
            g = this.product_;
        end
        function g = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %%
		  
 		function this = AbstractAifBuilder(varargin)
 			%% ABSTRACTAIFBUILDER
 			%  @param named sessionData
            %  @param named scannerData is an mlpet.IScannerData or empty.
            %  @param named manualData  is an mldata.IManualMeasurements.

            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'scannerData', [], @(x) isa(x, 'mlpet.IScannerData') || isempty(x));
            addParameter(ip, 'manualData', [], @(x) isa(x, 'mldata.IManualMeasurements'));
            parse(ip, varargin{:});            
            this.sessionData_ = ip.Results.sessionData;
            this.scannerData_ = ip.Results.scannerData;
            this.manualData_  = ip.Results.manualData;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        calibrator_
        manualData_
        product_
        scannerData_
        sessionData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

