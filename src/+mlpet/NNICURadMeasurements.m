classdef NNICURadMeasurements < handle & mlpet.RadMeasurements
	%% NNICURADMEASUREMENTS  

	%  $Revision$
 	%  was created 21-Oct-2018 23:44:39 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = NNICURadMeasurements(varargin)
 			%% NNICURADMEASUREMENTS
 			%  @param .

 			this = this@mlpet.RadMeasurements(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

