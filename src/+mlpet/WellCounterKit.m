classdef WellCounterKit < handle & mlpet.IDeviceKit
	%% WELLCOUNTERKIT  

	%  $Revision$
 	%  was created 23-Feb-2020 15:42:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = WellCounterKit(varargin)
 			%% WELLCOUNTERKIT
 			%  @param .

 			this = this@mlpet.IDeviceKit(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

