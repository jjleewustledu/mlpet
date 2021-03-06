classdef (Abstract) StudyRegistry < handle & mlpipeline.StudyRegistry
	%% STUDYREGISTRY  

	%  $Revision$
 	%  was created 11-Jun-2019 19:29:10 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
        numberNodes
        referenceTracer
        voxelTime = 60 % sec
        wallClockLimit = 168*3600 % sec
    end
    
    properties (Dependent)
        YeoDir
    end
    
    methods
        
        %% GET
        
        function g = get.YeoDir(~)
            g = getenv('YEODIR');
        end
    end
    
	methods (Access = protected)		  
 		function this = StudyRegistry(varargin)
 			%% STUDYREGISTRY
 			%  @param .

 			this = this@mlpipeline.StudyRegistry(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

