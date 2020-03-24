classdef (Abstract) IDecaying < handle
	%% IDECAYING is DEPRECATED

	%  $Revision$
 	%  was created 14-Oct-2018 19:29:47 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Abstract)
        activities
        activityUnits
 		isdecaying
        halflife
        isotope
        tracer
        zerotime
        zerodatetime 		
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

