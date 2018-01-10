classdef (Abstract) IAifData < mlpet.IScannerData
	%% IAIFDATA  

	%  $Revision$
 	%  was created 29-Jan-2017 17:16:57
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties (Abstract)
        isPlasma
 	end

	methods (Abstract)
        this = shiftTimes(this, dt) 
        this = shiftWorldlines(this, dt)     
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

