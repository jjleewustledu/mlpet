classdef (Abstract) ITracerDosing < handle
	%% ITRACERDOSING  

	%  $Revision$
 	%  was created 17-Oct-2018 16:57:01 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Abstract)
 		sessionIdentifier % unambiguously defines the measurement session
        tracer
        dose
        doseUnits
        doseAdminDatetime % synchronized to an NTS
        comments 		
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

