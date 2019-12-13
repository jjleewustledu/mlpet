classdef (Abstract) IRadiationData 
	%% IRADIATIONDATA  

	%  $Revision$
 	%  was created 25-Jan-2018 19:43:42 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Abstract)
        activity % decays/taus
        counts % := decays/invEfficiency
        decays % := invEfficiency*counts
        doseAdminDatetime 
        invEfficiency
        isDecayCorrected
        isotope
        sessionData
        specificActivity
 	end

	methods (Abstract)
        activityInterpolants(this)
        countInterpolants(this)
        decayInterpolants(this)
        specificActivityInterpolants(this)
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

