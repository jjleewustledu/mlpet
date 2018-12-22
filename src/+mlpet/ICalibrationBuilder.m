classdef (Abstract) ICalibrationBuilder < handle
	%% ICALIBRATIONBUILDER  

	%  $Revision$
 	%  was created 18-Dec-2018 21:23:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods (Abstract)
        readMeasurements(this)
        selectCalHierarchy(this)
        propagateEfficiencies(this)
  	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

