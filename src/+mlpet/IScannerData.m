classdef IScannerData
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
        doseAdminTime
        dt
        time0
        timeF
        times
        timeMidpoints
        taus        
        counts
        becquerels
    end 
    
    methods (Abstract)
        timeInterpolants(this)
        timeMidpointInterpolants(this)
        tauInterpolants(this)
        countInterpolants(this)
        becquerelInterpolants(this)
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

