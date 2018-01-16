classdef (Abstract) IScannerData < mldata.ITimingData
	%% ISCANNERDATA   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$  
    
	properties (Abstract)
        activity % decays/taus
        counts % := decays/efficiencyFactor
        decays % := efficiencyFactor*counts
        doseAdminDatetime 
        efficiencyFactor
        isDecayCorrected
        isotope
        sessionData
        specificActivity
 	end

	methods (Abstract)
               activityInterpolants(this)
               countInterpolants(this)
               decayInterpolants(this)
               numel(this)
               numelMasked(this)
        this = shiftTimes(this, dt)
        this = shiftWorldlines(this, dt)  
               specificActivityInterpolants(this)
               
               % borrowed from mlfourd.NumericalNIfTId
               blurred(this, blur)
               masked(this)
               thresh(this, t)
               threshp(this, p)
               timeContracted(this, varargin)
               timeSummed(this)
               uthresh(this, u)
               uthreshp(this, p)
               volumeContracted(this, varargin)
               volumeSummed(this)
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

