classdef (Abstract) IScannerData < mlpet.IWellData
	%% ISCANNERDATA   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$  	 

    properties (Constant) 
        EXTENSION    = '.nii.gz'
        TIMES_UNITS  = 'sec'
        COUNTS_UNITS = 'scanner-array events'
    end   
    
    properties (Abstract)	
        taus
        timeMidpoints
        injectionTime     
        recFqfilename         
        wellFqfilename
        wellFactor
        pie
        becquerels
        tscCounts
        wellCounts
        mask
        nPixels
    end 
    
    methods (Abstract)        
        wellCountInterpolants(this)
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

