classdef ITracerData < handle
	%% ITRACERDATA  

	%  $Revision$
 	%  was created 17-Mar-2020 22:32:16 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Abstract)
        datetimeForDecayCorrection % datetime
        decayCorrected % logical
        timeForDecayCorrection % numeric
    end	
    
	methods (Abstract, Static)
        this = createFromSession()
    end

	methods 
        a = activity(this) % Bq
        a = activityDensity(this) % Bq/mL
        c = countRate(this) % cps
        h = plot(this)		  
  	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

