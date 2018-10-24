classdef (Abstract) Instrument < handle
	%% INSTRUMENT is the AbstractProduct in an abstract factory pattern.
    %  For concrete products see also:  {mlpowers, mlarbelaez, mlraichle, ....}.{BloodSuckerDevice, CapracDevice, 
    %  TwiliteDevice, BiographMMRDevice, EcatExactHRPlusDevice}.

	%  $Revision$
 	%  was created 18-Oct-2018 13:58:30 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
 		invEfficiency
        logger
        radMeasurements
    end
    
    methods (Static)        
        function checkRangeInvEfficiency(ie)
            %  @param required ie is numeric.
            %  @throws mlpet:ValueError.
            
            assert(all(0.95 < ie) && all(ie < 1.05), ...
                'mlpet:ValueError', ...
                'Instrument.checkRangeInvEfficiency.ie->%s', mat2str(ie));
        end
    end
    
	methods 
        
        %% GET
        
        function g = get.invEfficiency(this)
            assert(~isempty(this.invEfficiency_), ...
                'mlpet:ValueError', ...
                'request for Instrument.get.invEfficiency made before calibration; first use the calibrate method');
            assert(~isnan(this.invEfficiency_), ...
                'mlpet:ValueError', ...
                'request for Instrument.get.invEfficiency made before calibration; first use the calibrate method');
            assert(this.invEfficiency_ > 0);
            assert(isfinite(this.invEfficiency_));
            g = this.invEfficiency_;
        end
        function g = get.logger(this)
            g = this.logger_;
        end
        function g = get.radMeasurements(this)
            g = this.radMeasurements_;
        end
        
        %%
        
        function this = calibrateDevice(this, varargin)
            %% CALIBRATEDEVICE sets invEfficiency for this instrument by comparing its calibration data 
            %  against reference data.
        end
        function d = makeMeasurements(this)
            error('mlpet:NotImplementedError');
        end
        
        function this = Instrument(varargin)
            %% INSTRUMENT for positron emission measurements.
            %  @param radMeasurements is mlpet.RadMeasurements.
            
 			ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'radMeasurements', [], @(x) isa(x, 'mlpet.RadMeasurements'));
            parse(ip, varargin{:});
            this.radMeasurements_ = ip.Results.radMeasurements;
            this.logger_ = mlpipeline.Logger2(this);
        end
        		  
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        invEfficiency_
        logger_
        radMeasurements_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

