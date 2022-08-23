classdef (Abstract) AbstractCalibration < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
	%% ABSTRACTCALIBRATION  

	%  $Revision$
 	%  was created 23-Feb-2020 21:44:02 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1296695 (R2019b) Update 4 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Abstract)
        calibrationAvailable % logical scalar
        invEfficiency
 	end

	methods (Abstract, Static)
        buildCalibration()
        createFromSession()
        invEfficiencyf()
    end 
    
	properties (Constant)
        WATER_DENSITY = 0.9982 % pure water at 20 C := 0.9982 mL/g; tap := 0.99823
        BLOOD_DENSITY = 1.06 % https://hypertextbook.com/facts/2004/MichaelShmukler.shtml; human whole blood 37 C
        BRAIN_DENSITY = 1.05 % Torack et al., 1976
        PLASMA_DENSITY = 1.03
    end
    
    properties (Dependent)
        branchingRatio
        radionuclide
        radMeasurements
        sessionData
    end
    
    methods (Static)
        function arr = shiftWorldLines(arr, shift, halflife)
            %% SHIFTWORLDLINES 
            %  @param arr is numeric, undergoing radiodecay
            %  @param shift is numeric, seconds of shift; 
            %         shift < 0 shifts backward in time; shift > 0 shifts forward in time
            %  @param halflife of radionuclide in seconds
            %  @return arr with preserved vector shape
            %  @throws mlpet:ValueError if arr is not vector.
            
            assert(isnumeric(arr)) % activities
            assert(isnumeric(shift)) % time-shift
            assert(isscalar(halflife)) 
            
            if isrow(arr)
                shift = asrow(shift);
                arr = arr .* 2.^(-shift/halflife);
                return
            end
            if iscolumn(arr)
                shift = ascolumn(shift);
                arr = arr .* 2.^(-shift/halflife);
                return
            end
            error('mlpet:ValueError', 'AbstractCalibration.shiftWorldLines:  size(arr)->%s', mat2str(size(arr)))
        end
    end
        
    methods 
        
        %% GET
        
        function g = get.branchingRatio(this)
            g = this.radionuclide.branchingRatio;
        end
        function g = get.radionuclide(this)
            g = this.radionuclide_;
        end
        function g = get.radMeasurements(this)
            g = this.radMeasurements_;
        end
        function g = get.sessionData(this)
            g = this.radMeasurements.sessionData;
        end
        
        %% 
        
        function [trainedModel, validationRMSE] = trainRegressionModel(~, trainingData)
            assert(istable(trainingData));
            trainedModel = [];
            validationRMSE = [];
        end
        
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        radionuclide_
        radMeasurements_
    end
    
    methods (Access = protected)
 		function this = AbstractCalibration(varargin)
 			%% ABSTRACTCALIBRATION
            %  @param required radMeas is mlpet.RadMeasurements.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'radMeas', [], @(x) isa(x, 'mlpet.RadMeasurements') || isempty(x));
            addParameter(ip, 'radMeasurements', [], @(x) isa(x, 'mlpet.RadMeasurements') || isempty(x));
            addParameter(ip, 'isotope', '18F', @(x) ismember(x, mlpet.Radionuclides.SUPPORTED_ISOTOPES));
            parse(ip, varargin{:});   
            ipr = ip.Results;
            
            if ~isempty(ipr.radMeas)
                this.radMeasurements_ = ipr.radMeas;
            end
            if ~isempty(ipr.radMeasurements)
                this.radMeasurements_ = ipr.radMeasurements;
            end 
            this.radionuclide_ = mlpet.Radionuclides(ipr.isotope);
        end
        
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
        end
        function tf = isotopeSelection(this)
            rm = this.radMeasurements;
            tf = contains(rm.wellCounter.TRACER, this.radionuclide.isotope);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

