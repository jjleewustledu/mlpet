classdef CalibrationBuilder < handle & mlpipeline.AbstractHandleSessionBuilder & mlpet.ICalibrationBuilder
	%% CALIBRATIONBUILDER builds products:  bloodSamplerCal, scannerCal, wellCounterCal.

	%  $Revision$
 	%  was created 09-Jan-2018 16:43:16 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlsiemens/src/+mlsiemens.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent) 
        bloodSamplerCal
        scannerCal
        wellCounterCal
    end
    
    methods (Static)
        function this = doMake(typeclass, varargin)
            switch(typeclass)
                case 'CCIRCalibrationBuilder'
                    this = mlpet.CCIRCalibrationBuilder(varargin{:});
                case 'NNICUCalibrationBuilder'
                    this = mlpet.NNICUCalibrationBuilder(varargin{:});
                otherwise
                    error('mlpet:RunTimeError', 'CalibrationBuilder.doMake does not support typeclass %s', typeclass);
            end
        end
    end

	methods 
        
        %% GET
        
        function g = get.bloodSamplerCal(this)
            g = this.bloodSamplerCal_;
        end
        function g = get.scannerCal(this)
            g = this.scannerCal_;
        end
        function g = get.wellCounterCal(this)
            g = this.wellCounterCal_;
        end
        
        %%
        
        function readMeasurements(this)
        end
        function selectCalHierarchy(this)
        end
        function propagateEfficiencies(this)
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        bloodSamplerCal_
        scannerCal_
        wellCounterCal_
    end
        
    methods (Access = protected)
 		function this = CalibrationBuilder(varargin)
 			%% CALIBRATIONBUILDER            
            
            this = this@mlpipeline.AbstractHandleSessionBuilder(varargin{:});
            this = this.setLogPath(fullfile(this.sessionData_.vallLocation, 'Log', ''));
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end
