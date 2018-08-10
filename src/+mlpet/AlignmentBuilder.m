classdef AlignmentBuilder < mlpipeline.AbstractSessionBuilder
	%% ALIGNMENTBUILDER  

	%  $Revision$
 	%  was created 03-May-2018 23:07:16 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = AlignmentBuilder(varargin)
 			%% ALIGNMENTBUILDER
 			%  @param .

 			this = this@mlpipeline.AbstractSessionBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

