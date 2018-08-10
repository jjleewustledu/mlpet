classdef (Abstract) ISessionResolvingData 
	%% ISESSIONRESOLVINGDATA  

	%  $Revision$
 	%  was created 27-May-2018 16:55:27 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Abstract) 		
        compositeT4ResolveBuilderBlurArg
        epoch
        epochTag
        maxLengthEpoch
        resolveTag
        rnumber
        supEpoch
        t4ResolveBuilderBlurArg
 	end

	methods (Abstract)
  	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

