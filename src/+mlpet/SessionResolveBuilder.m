classdef SessionResolveBuilder < handle & mlpet.StudyResolveBuilder
	%% SESSIONRESOLVEBUILDER operates on scans contained in $SUBJECTS_DIR/sub-S000000/ses-E000000

	%  $Revision$
 	%  was created 07-May-2019 01:16:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
       
	methods
                
 		function this = SessionResolveBuilder(varargin)
 			%% SESSIONRESOLVEBUILDER
 			%  @param sessionData is an mlpipeline.ISessionData.
            
            this = this@mlpet.StudyResolveBuilder(varargin{:});
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

