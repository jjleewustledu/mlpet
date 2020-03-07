classdef SubjectResolveBuilder < handle & mlpet.StudyResolveBuilder
	%% SUBJECTRESOLVEBUILDER  

	%  $Revision$
 	%  was created 07-May-2019 01:16:29 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	methods        
 		function this = SubjectResolveBuilder(varargin)
 			%% SUBJECTRESOLVEBUILDER
 			%  @param .
            
            this = this@mlpet.StudyResolveBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

