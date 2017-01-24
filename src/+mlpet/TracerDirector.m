classdef TracerDirector 
	%% TRACERDIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 19:29:04
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties (Dependent)
        builder
        product
    end
    
    methods %% GET
        function g = get.builder(this)
            g = this.builder_;
        end
        function g = get.product(this)
            g = this.builder_.product;
        end
    end

	methods 		  
 		function this = TracerDirector(varargin)
 			%% TRACERDIRECTOR
 			%  Usage:  this = TracerDirector(builder_object)
            
            import mlraichle.*;
            ip = inputParser;
            addRequired(ip, 'builder', @(x) isa(x, 'mlpipeline.IDataBuilder'));
            parse(ip, varargin{:});
            
            this.builder_ = ip.Results.builder;
        end
        
        function b = configureNAC(~, b)
            assert(isa(b, 'mlpipeline.IDataBuilder'));
            sessd = b.sessionData;
            sessd.attenuationCorrected = false;
            sessd.rnumber = 1;
            b.sessionData = sessd;
        end
        function b = configureAC(~, b)
            assert(isa(b, 'mlpipeline.IDataBuilder'));
            sessd = b.sessionData;
            sessd.attenuationCorrected = true;
            sessd.rnumber = 1;
            b.sessionData = sessd;
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

