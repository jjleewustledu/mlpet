classdef SubjectResolverToHO < handle & mlpet.SessionResolverToHO
	%% SUBJECTRESOLVERTOHO  

	%  $Revision$
 	%  was created 14-Jan-2020 12:44:19 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	methods
        function        constructResamplingRestricted(this, varargin)
            this.tools_.constructResamplingRestricted(varargin{:})
        end
        function fps  = linkAndSimplifyScans(this, varargin)
            fps = this.tools_.linkAndSimplifyScans(varargin{:});
        end 
        
 		function this = SubjectResolverToHO(varargin)
 			%% SUBJECTRESOLVERTOHO
 			%  @param .

 			this = this@mlpet.SessionResolverToHO(varargin{:});
            this.collectionRB_ = mlfourdfp.CollectionResolveBuilder( ...
                'sessionData', this.client_.sessionData, ...
                'workpath', fullfile(this.client_.sessionData.subjectPath, '')); % replacing of superclass assignment
            this.tools_ = mlpet.SubjectResolverTools('resolver', this);
 		end
    end
    
    %% PROTECTED    
    
    properties (Access = protected)
        tools_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

