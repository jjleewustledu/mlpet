classdef CbfBuilder < mlpipeline.AbstractSessionBuilder
	%% CBFBUILDER  

	%  $Revision$
 	%  was created 28-Jan-2017 04:34:42
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	
    
	methods 
		  
 		function this = CbfBuilder(varargin)
 			%% CBFBUILDER
 			%  Usage:  this = CbfBuilder()
 			
            this = this@mlpipeline.AbstractSessionBuilder(varargin{:});
        end
        
        function this = buildHerscCbfMap(this, varargin)
        end
        function this = buildDistribParamCbfMap(this)
        end
        function this = buildPlaifCbfMap(this)
        end
        function this = buildLieCbfMap(this)
        end
 	end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

