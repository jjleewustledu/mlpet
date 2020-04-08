classdef (Abstract) IAerobicGlycolysisKit < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
	%% IAEROBICGLYCOLYSISKIT  

	%  $Revision$
 	%  was created 01-Apr-2020 10:53:03 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Abstract) 
 		studyData
 	end

	methods (Abstract, Static) 
        this = createFromStudy(varargin)
    end 
    
	methods (Abstract)
        buildAGI(this)
        buildCBV(this)
        buildCBF(this)
        buildCMRglc(this)
        buildCMRO2(this)
        buildKs(this)
        buildOEF(this)
		buildOGI(this)  
  	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

