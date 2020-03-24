classdef BloodSuckerDevice < mlpet.AbstractDevice
	%% BLOODSUCKERDEVICE  

	%  $Revision$
 	%  was created 18-Oct-2018 13:59:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
		  
 		function this = BloodSuckerDevice(varargin)
 			%% BLOODSUCKERDEVICE
 			%  @param .

 			this = this@mlpet.AbstractDevice(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

