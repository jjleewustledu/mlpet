classdef (Abstract) IDeviceKit < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
	%% IDEVICEKIT provides the interface of the abstract factory of the abstract factory pattern comprising
    %  mlpet.DeviceKit, its concrete subclasses, mlpet.AbstractDevice and its concrete subclasses.

	%  $Revision$
 	%  was created 23-Feb-2020 15:10:25 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee. 	

    properties (Abstract)        
        sessionData
        radMeasurements
    end
    
    methods (Abstract)
        buildScannerDevice(this)
        buildArterialSamplingDevice(this)
        buildCountingDevice(this)
    end
    
	methods (Abstract, Static)
        this = createFromSession(varargin)
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

