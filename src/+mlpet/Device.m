classdef (Abstract) Device < handle
	%% INSTRUMENT is the AbstractProduct in an abstract factory pattern.
    %  For concrete products see also:  {mlpowers, mlarbelaez, mlraichle, ....}.{BloodSuckerDevice, CapracDevice, 
    %  TwiliteDevice, BiographMMRDevice, EcatExactHRPlusDevice}.

	%  $Revision$
 	%  was created 18-Oct-2018 13:58:30 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
        alpha
        calibrations
        logger
        radMeasurements
    end    
    
    methods (Abstract, Static)
        [tbl,h] = screenInvEfficiency
    end
    
    methods (Static)
        function checkRangeInvEfficiency(ie)
            %  @param required ie is numeric.
            %  @throws mlpet:ValueError.
            
            import mlpet.Device;
            assert(isnumeric(ie), ...
                'mlpet:ValueError', ...
                'Device.checkRangeInvEfficiency.ie has unsupported typeclass %s', class(ie));
            assert(~isempty(ie), ...
                'mlpet:ValueError', ...
                ['Device.checkRangeInvEfficiency.ie was empty.  ' ...
                 'Call calibrateDevice before calling calibrateMeasurement or invEfficiency.']);
            assert(all(1 - Device.alpha < ie) && all(ie < 1 + Device.alpha), ...
                'mlpet:ValueError', ...
                'Device.checkRangeInvEfficiency.ie->%s', mat2str(ie));
        end
    end
    
	methods 
        
        %% GET
        
        function g = get.alpha(~)
            g = mlpipeline.ResourcesRegistry.instance().alpha;
        end
        function g = get.calibrations(this)
            g = this.calibrations_;
        end
        function g = get.logger(this)
            g = this.logger_;
        end
        function g = get.radMeasurements(this)
            g = this.radMeasurements_;
        end
        
        %%
        
        function this = calibrateDevice(this, varargin)
            %% CALIBRATEDEVICE prepares invEfficiency and calibrateMeasurements for this instrument using calibration data. 
            
            this.calibrations_ = 1;
        end
        function m    = calibrateMeasurement(this, varargin)
            ip = inputParser;
            addRequired(ip, 'measurement', @isnumeric);
            parse(ip);
            
            m = this.invEfficiency * ip.Results.measurement;
        end
        function ie   = invEfficiency(this, varargin)
            %% INVEFFICIENCY is the linear estimate of the mapping from raw measurements to calibrated measurements.
            %  @throws mlpet.ValueError if the gradient of the estimate exceeds alpha.
            
            ie = this.calibrations_;
            this.checkRangeInvEfficiency(ie);
        end
        
        function this = Device(varargin)
            %% INSTRUMENT for positron emission measurements.
            %  @param radMeasurements is mlpet.RadMeasurements.
            %  @param alpha is numeric.
            
 			ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'radMeasurements', [], @(x) isa(x, 'mlpet.RadMeasurements'));
            addParameter(ip, 'alpha', 0.05, @isnumeric);
            parse(ip, varargin{:});
            this.radMeasurements_ = ip.Results.radMeasurements;
            this.alpha_ = ip.Results.alpha;
            this.logger_ = mlpipeline.Logger2(this);
        end
        		  
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        calibrations_
        logger_
        radMeasurements_
        alpha_
    end
    
    methods (Access = protected)
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

