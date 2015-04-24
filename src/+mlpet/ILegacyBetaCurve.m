classdef ILegacyBetaCurve  
	%% ILEGACYBETACURVE   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

    properties (Abstract, Constant)
        EXTENSION   % e.g., '.crv'
        STUDY_CODES % e.g., 'ho', 'oo', 'oc', 'g', 'gluc'
    end 
    
    properties (Abstract)
        dt % sec      
        
        filepath
        fileprefix
        fqfilename
        scanIndex
        
        scanDuration % sec  
        times
        counts
        header
        headerString
        length % number valid frames
    end 
    
    methods (Abstract)        
        timeInterpolants(this)
        countInterpolants(this)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

