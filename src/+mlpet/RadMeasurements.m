classdef (Abstract) RadMeasurements < handle & matlab.mixin.Heterogeneous
	%% RADMEASUREMENTS  

	%  $Revision$
 	%  was created 21-Oct-2018 19:00:55 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	    
    methods (Abstract)
        cath = catheterInfo(this)
        dt   = datetime(this)    
        dt   = datetimeTracerAdmin(this, varargin)
        wcrs = wellCounterRefSrc(this, isotope)
    end
    
    properties (Constant)
        REFERENCE_SOURCES = {'[22Na]' '[68Ge]' '[137Cs]'}
    end

    methods (Static)
        function this = createByDate(varargin)
            this = [];
        end
        function this = createByFilename(varargin)
            this = [];
        end
        function this = createBySession(varargin)
            this = [];
        end
    end
        
	methods 		  
 		function this = RadMeasurements(varargin)
 			%% RADMEASUREMENTS
 			%  @param .

 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

