classdef TracerKineticsBuilder < mlpet.TracerBuilder
	%% TRACERKINETICSBUILDER  

	%  $Revision$
 	%  was created 30-May-2017 21:19:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
	properties (Constant)
        REUSE_APARCASEG = true
 		REUSE_BRAINMASK = true
    end
    
    properties (Dependent)
        kinetics
    end
    
    methods 
        
        %% GET
        
        function g = get.kinetics(this)
            g = this.kinetics_;
        end
		  
        %%
        
        function this = constructKinetics(this, varargin)
            this.kinetics_ = this.kinetics_.constructKinetics(varargin{:});
        end
        function tf = constructKineticsPassed(this, varargin)
            tf = this.kinetics_.constructKineticsPassed(varargin{:});
        end
        
 		function this = TracerKineticsBuilder(varargin)
 			%% TRACERKINETICSBUILDER

 			this = this@mlpet.TracerBuilder(varargin{:});
        end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        kinetics_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

