classdef TracerKineticsBuilder < mlpet.TracerBuilder & mlpet.ITracerKineticsBuilder
	%% TRACERKINETICSBUILDER  

	%  $Revision$
 	%  was created 30-May-2017 21:19:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
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
        function tf   = constructKineticsPassed(this, varargin)
            tf = this.kinetics_.constructKineticsPassed(varargin{:});
        end               
        
 		function this = TracerKineticsBuilder(varargin)
 			%% TRACERKINETICSBUILDER
            %  @params named 'logger' is an mlpipeline.AbstractLogger.
            %  @params named 'product' is the initial state of the product to build.
            %  @params named 'sessionData' is an mlpipeline.ISessionData.
 			%  @params named 'buildVisitor' is an mlfourdfp.FourdfpVisitor.
            %  @params named 'roisBuild' is an mlrois.IRoisBuilder.
            %  @params named 'kinetics' is an mlkinetics.AbstractKinetics.

 			this = this@mlpet.TracerBuilder(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'kinetics', [], @(x) isa(x, 'mlkinetics.AbstractKinetics') || isempty(x));
            parse(ip, varargin{:});
            
            this.kinetics_ = ip.Results.kinetics;
        end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        kinetics_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

