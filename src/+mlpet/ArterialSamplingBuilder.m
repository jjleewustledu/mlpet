classdef ArterialSamplingBuilder < mlpipeline.AbstractSessionBuilder
	%% ARTERIALSAMPLINGBUILDER  

	%  $Revision$
 	%  was created 06-Jan-2017 16:03:15
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	
    
	methods 
		  
 		function this = ArterialSamplingBuilder(varargin)
 			%% ARTERIALSAMPLINGBUILDER
 			%  Usage:  this = ArterialSamplingBuilder()
 			
            this = this@mlpipeline.AbstractSessionBuilder(varargin{:});
        end
        
        function this = buildArterialSampling(this)
            
            if (isa(this.studyData, 'mlderdeyn.StudyDataSingleton'))
                this.product_ = [];
                return
            end
            if (isa(this.studyData, 'mlraichle.StudyData'))
                this.product_ = [];
                return
            end
            error('mlpet:unsupportTypeclass', ...
                  'ArterialSamplingBuilder.buildArterialSampling.this.studyData -> %s', ...
                  this.studyData);
        end
 	end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

