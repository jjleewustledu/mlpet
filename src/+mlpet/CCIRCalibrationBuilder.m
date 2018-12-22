classdef CCIRCalibrationBuilder < handle & mlpet.CalibrationBuilder
	%% CCIRCALIBRATIONBUILDER  

	%  $Revision$
 	%  was created 18-Dec-2018 23:05:09 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
        function readMeasurements(this)
            sessd = this.sessionData;
            radMeas = mlpet.CCIRRadMeasurements.createBySession(sessd);
            this.wellCounterCal_ = mlcapintec.CapracCalibration(radMeas);
            this.bloodSamplerCal_ = mlswisstrace.TwiliteCalibration(radMeas);
            this.scannerCal_ = mlsiemens.BiographMMRCalibration(radMeas);
        end
        function selectCalHierarchy(this)
            %% selects the chain of calibrations.
            
            this.wellCounterCal_.selfCalibrate;
            this.bloodSamplerCal_.calibrateTo(this.wellCounterCal_);
            this.scannerCal_.calibrateTo(this.wellCounterCal_);
        end
        function propagateEfficiencies(this)
        end
		  
 		function this = CCIRCalibrationBuilder(varargin)
 			%% CCIRCALIBRATIONBUILDER
 			%  @param .

 			this = this@mlpet.CalibrationBuilder(varargin{:});
 		end
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

