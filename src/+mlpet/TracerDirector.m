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
        sessionData
    end
    
    methods %% GET
        function g = get.builder(this)
            g = this.builder_;
        end
        function g = get.product(this)
            g = this.builder_.product;
        end
        function g = get.sessionData(this)
            g = this.builder_.sessionData;
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
 	end 

    
    %% PROTECTED
    
    properties (Access = protected)
        builder_
    end
    
    methods (Access = protected)
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

