classdef (Abstract) IWorldLines 
	%% IWORLDLINES  

	%  $Revision$
 	%  was created 25-Jan-2018 19:39:15 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods (Abstract)	  
        this = shiftTimes(this, dt)
        this = shiftWorldlines(this, dt)  
  	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

