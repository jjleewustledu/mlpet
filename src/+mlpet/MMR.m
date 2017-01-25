classdef MMR < mlpet.IMMRData
	%% MMR  

	%  $Revision$
 	%  was created 23-Jan-2017 19:49:56
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties (Dependent)
        product
        sessionData
    end
    
    methods %% GET
        function g = get.product(this)
            g = this.product_;
        end
        function g = get.sessionData(this)
            assert(~isempty(this.sessionData_));
            g = this.sessionData_;
        end
    end

	methods 
		  
 		function this = MMR(varargin)
 			%% MMR
 			%  Usage:  this = MMR()
            
 			ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});
            
            this.sessionData_ = ip.Results.sessionData;
            this.mmrBuilder_ = mlfourdfp.MMRBuilder('sessionData', this.sessionData);
        end
        function this = buildPetObsMap(this)
            this.mmrBuilder_.sif;
            fqfp = this.mmrBuilder_.cropfrac;            
            this.product_ = mlpet.PETImagingContext([fqfp '.4dfp.ifh']);
        end
 	end 
    
    %% PRIVATE
    
    properties (Access = private)
        mmrBuilder_
        product_
        sessionData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

