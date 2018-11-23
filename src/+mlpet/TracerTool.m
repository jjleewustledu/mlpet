classdef TracerTool < handle & mlfourd.ImagingFormatTool
	%% TRACERTOOL  

	%  $Revision$
 	%  was created 10-Aug-2018 02:29:38 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = TracerTool(h, varargin)
 			%% TRACERTOOL
 			%  @param .

            this = this@mlfourd.ImagingFormatTool(h, varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

