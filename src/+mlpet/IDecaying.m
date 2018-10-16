classdef (Abstract) IDecaying < handle
	%% IDECAYING  

	%  $Revision$
 	%  was created 14-Oct-2018 19:29:47 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Abstract)
 		isdecaying
        halflife
        isotope
        tracer
        zerodose
        zerotime
        zerodatetime 		
 	end

	methods (Abstract)
        decayActivities(this)
        decayFactor(this)
        shiftWorldline(this)
        undecayActivities(this)
        undecayFactor(this)
  	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

