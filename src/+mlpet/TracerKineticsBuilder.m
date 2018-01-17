classdef TracerKineticsBuilder < mlpet.TracerBuilder
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
        
        function this = instanceConstructKinetics(this, varargin)
            this.kinetics_ = this.kinetics_.instanceConstructKinetics(varargin{:});
        end
        function tf   = constructKineticsPassed(this, varargin)
            tf = this.kinetics_.constructKineticsPassed(varargin{:});
        end    
        function [this,aab] = resolveRoisOnTracer(this, varargin)
            %% RESOLVEROISONAC
            %  @param named 'roisBuilder' is an 'mlrois.IRoisBuilder'
            %  @returns aab, an mlfourd.ImagingContext from mlpet.BrainmaskBuilder.aparcAsegBinarized.
            
            ip = inputParser;
            addParameter(ip, 'roisBuilder', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});            
            sessd = this.sessionData;
            
            % actions
            
            pwd0 = sessd.tracerLocation;
            ensuredir(pwd0);
            pushd(pwd0);
            bmb = mlpet.BrainmaskBuilder('sessionData', sessd);
            [~,ct4rb] = bmb.brainmaskBinarized( ...
                'tracer', this.sessionData.tracerRevisionSumt('typ', 'mlfourd.ImagingContext'));
            aab = bmb.aparcAsegBinarized(ct4rb);
            popd(pwd0);
        end           
        
 		function this = TracerKineticsBuilder(varargin)
 			%% TRACERKINETICSBUILDER
            %  @param named 'logger' is an mlpipeline.AbstractLogger.
            %  @param named 'product' is the initial state of the product to build.
            %  @param named 'sessionData' is an mlpipeline.ISessionData.
 			%  @param named 'buildVisitor' is an mlfourdfp.FourdfpVisitor.
            %  @param named 'roisBuild' is an mlrois.IRoisBuilder.
            %  @param named 'kinetics' is an mlkinetics.AbstractKinetics.

 			this = this@mlpet.TracerBuilder(varargin{:});
        end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        kinetics_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

