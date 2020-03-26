classdef (Abstract) ICalibration < handle
	%% ICALIBRATION  

	%  $Revision$
 	%  was created 10-Mar-2020 22:50:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Abstract) 		
        calibrationAvailable % logical scalar
        invEfficiency
        radMeasurements
 	end

	methods (Abstract, Static)
        invEfficiencyf
  	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

