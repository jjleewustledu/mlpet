classdef InstrumentBuilder < handle & mlpipeline.AbstractHandleSessionBuilder
	%% INSTRUMENTBUILDER  

	%  $Revision$
 	%  was created 21-Dec-2018 17:32:30 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		calibration
 	end

	methods 
        
        %% GET/SET
        
        function g = get.calibration(this)
            g = this.getCalibration__;
        end
        
        function set.calibration(this, s)
            this.setCalibration__(s);
        end
        
        %% 
        
        function this = InstrumentBuilder(varargin)
            this = this@mlpipeline.AbstractHandleSessionBuilder(varargin{:});
        end
		  
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        calibration_
    end
    
    methods (Access = protected)
        function g = getCalibration__(this)
            g = this.calibration_;
        end
        function setCalibration__(this, s)
            assert(isa(s, 'mlpet.AbstractCalibration'));
            this.calibration_ = s;
        end
    end    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

