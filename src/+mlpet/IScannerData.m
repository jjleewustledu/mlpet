classdef IScannerData < mldata.ITimingData
	%% ISCANNERDATA   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$  
    
	properties (Abstract)
        sessionData
        doseAdminDatetime 
        counts
        becquerels
        efficiencyFactor
        isotope
 	end

	methods (Abstract)
               countInterpolants(this)
               becquerelInterpolants(this)
        this = shiftTimes(this, dt)
        this = shiftWorldlines(this, dt)  
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

