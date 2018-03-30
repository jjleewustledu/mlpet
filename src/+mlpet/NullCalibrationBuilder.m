classdef NullCalibrationBuilder < mlpet.ICalibrationBuilder
	%% NULLCALIBRATIONBUILDER  

	%  $Revision$
 	%  was created 14-Jan-2018 14:05:14 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = NullCalibrationBuilder(varargin)
 			%% NULLCALIBRATIONBUILDER
 			%  Usage:  this = NullCalibrationBuilder()

 			this = this@mlpet.ICalibrationBuilder(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

