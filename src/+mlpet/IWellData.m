classdef (Abstract) IWellData
	%% IWELLDATA   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
    
    properties (Constant)        
        DEPTH_SEARCH_FOR_WELL = 3
    end
 	 
    properties (Abstract, Constant)
        EXTENSION
        TIMES_UNITS
        COUNTS_UNITS
    end
    
    properties (Abstract)        
        scanIndex % integer, e.g., last char in 'p1234ho1'
        tracer % char, e.g., 'ho'
        length % integer, number valid frames
        scanDuration % sec  
        dt % sec        
        times
        counts
        wellCounts   
        wellFactor      
        wellFqfilename
        header
        noclobber
    end 
    
    methods (Abstract)
        timeInterpolants(this)
        countInterpolants(this)
        wellCountInterpolants(this)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

