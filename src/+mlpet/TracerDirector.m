classdef TracerDirector 
	%% TRACERDIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 19:29:04
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	

	properties (Dependent)
        builder
        product
        roisBuilder
        sessionData
    end
    
    methods 
        
        %% GET/SET
        
        function g = get.builder(this)
            g = this.builder_;
        end        
        function g = get.product(this)
            g = this.builder_.product;
        end
        function g = get.roisBuilder(this)
            g = this.builder_.roisBuilder;
        end
        function g = get.sessionData(this)
            g = this.builder_.sessionData;
        end
        
        function this = set.roisBuilder(this, s)
            assert(isa(s, 'mlrois.IRoisBuilder'));
            this.builder_.roisBuilder = s;
        end
        
        %%        
        
        function this = constructKinetics(this, varargin)   
            %% CONSTRUCTKINETICS requests that the builder prepare filesystems, coregistrations and 
            %  resolve-projections of ancillary data to tracer data.  
            %  Subsequently, it requests that the builder construct kinetics.
            %  @params named 'roisBuild' is an 'mlrois.IRoisBuilder'.
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            this.builder_ = this.builder_.gatherConvertedAC;
            this.builder_ = this.builder_.resolveRoisOnAC(varargin{:});
            this.builder_ = this.builder_.constructKinetics(varargin{:});            
        end
        function tf = constructKineticsPassed(this, varargin)
            %% CONSTRUCTKINETICSPASSED
            %  @params named 'roisBuild' is an 'mlrois.IRoisBuilder'.
            %  @returns tf logical.
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            tf = this.builder_.constructKineticsPassed(varargin{:});
        end
        
 		function this = TracerDirector(varargin)
 			%% TRACERDIRECTOR
 			%  @param required 'builder' is a 'mlpet.ITracerBuilder'
            
            ip = inputParser;
            addRequired(ip, 'builder', @(x) isa(x, 'mlpet.ITracerBuilder'));
            parse(ip, varargin{:});
            
            this.builder_ = ip.Results.builder;
        end
 	end 

    
    %% PROTECTED
    
    properties (Access = protected)
        builder_
    end
    
    methods (Access = protected)
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

