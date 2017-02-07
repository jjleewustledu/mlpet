classdef AbstractHerscovitch1985 < mlpipeline.AbstractDataBuilder
	%% ABSTRACTHERSCOVITCH1985  

	%  $Revision$
 	%  was created 06-Feb-2017 21:31:05
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		
 	end

	methods 
		  
 		function this = AbstractHerscovitch1985(varargin)
 			%% ABSTRACTHERSCOVITCH1985
 			%  Usage:  this = AbstractHerscovitch1985()

 			this = this@mlpipeline.AbstractDataBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

