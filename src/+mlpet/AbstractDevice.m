classdef (Abstract) AbstractDevice < handle & matlab.mixin.Copyable & mldata.ITiming & mlpet.ITracerData
	%% DEVICE is the AbstractProduct in an abstract factory pattern.
    %  See also factories mlpet.DeviceKit & descendent classes.
    %  See also concrete products:  {mlpowers, mlarbelaez, mlraichle, ....}.{BloodSuckerDevice, CapracDevice, 
    %  TwiliteDevice, BiographMMRDevice, EcatExactHRPlusDevice}.

	%  $Revision$
 	%  was created 18-Oct-2018 13:58:30 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
        datetimeForDecayCorrection  
        decayCorrected
        halflife
        isotope
        radMeasurements
        timeForDecayCorrection
        threshOfPeak
        
        %% mldata.ITiming, mldata.TimingData
        
        datetime0
        datetimeF
        datetimeInterpolants
        datetimeMeasured
        datetimeWindow
        datetimes
        datetimesMid
        dt
        index0
        indexF
        indices
        taus
        time0
        timeF
        timeInterpolants
        times
        timesMid
        timeWindow        
    end    
    
    methods (Static)
        function sesd = findCalibrationSession(sesd0, varargin)
            assert(isa(sesd0, 'mlpipeline.ISessionData'))
            scanfold = globFoldersT(fullfile(sesd0.sessionPath, 'FDG_DT*-Converted-AC'));
            sesd = sesd0.create(fullfile(sesd0.projectFolder, sesd0.sessionFolder, mybasename(scanfold{end})));
        end
    end

	methods 
        
        %% GET
        
        function g = get.datetimeForDecayCorrection(this)
            g = this.data_.datetimeForDecayCorrection;
        end
        function     set.datetimeForDecayCorrection(this, s)
            this.data_.datetimeForDecayCorrection = s;
        end
        function g = get.decayCorrected(this)
            g = this.data_.decayCorrected;
        end
        function g = get.halflife(this)
            g = this.data_.halflife;
        end
        function g = get.isotope(this)
            g = this.data_.isotope;
        end
        function g = get.radMeasurements(this)
            g = this.data_.radMeasurements;
        end
        function g = get.timeForDecayCorrection(this)
            g = this.data_.timeForDecayCorrection;
        end    
        function g = get.threshOfPeak(this)
            if strcmpi('15O', this.isotope)
                g = 0.5;
            else
                g = 0.5;
            end
        end
        
        function g = get.datetime0(this)
            g = this.data_.datetime0;
        end
        function     set.datetime0(this, s)
            this.data_.datetime0 = s;
        end
        function g = get.datetimeF(this)
            g = this.data_.datetimeF;
        end
        function     set.datetimeF(this, s)
            this.data_.datetimeF = s;
        end
        function g = get.datetimeInterpolants(this)
            g = this.data_.datetimeInterpolants;
        end
        function g = get.datetimeMeasured(this)
            g = this.data_.datetimeMeasured;
        end
        function     set.datetimeMeasured(this, s)
            assert(isdatetime(s))            
            this.data_.datetimeMeasured = s;
        end
        function g = get.datetimes(this)
            g = this.data_.datetimes;
        end
        function g = get.datetimesMid(this)
            g = this.data_.datetimesMid;
        end
        function g = get.datetimeWindow(this)
            g = this.data_.datetimeWindow;
        end
        function     set.datetimeWindow(this, s)
            this.data_.datetimeWindow = s;
        end
        function g = get.dt(this)
            g = this.data_.dt;
        end
        function     set.dt(this, s)
            this.data_.dt = s;
        end
        function g = get.index0(this)
            g = this.data_.index0;
        end
        function     set.index0(this, s)
            this.data_.index0 = s;
        end
        function g = get.indexF(this)
            g = this.data_.indexF;
        end
        function     set.indexF(this, s)
            this.data_.indexF = s;
        end
        function g = get.indices(this)
            g = this.data_.indices;
        end
        function g = get.taus(this)
            g = this.data_.taus;
        end  
        function     set.taus(this, s)
            this.data_.taus = s;
        end
        function g = get.time0(this)
            g = this.data_.time0;
        end
        function     set.time0(this, s)
            this.data_.time0 = s;
        end
        function g = get.timeF(this)
            g = this.data_.timeF;
        end
        function     set.timeF(this, s)
            this.data_.timeF = s;
        end
        function g = get.timeInterpolants(this)
            %% GET.TIMEINTERPOLANTS are uniformly separated by this.dt
            %  @returns interpolants this.times(1):this.dt:this.times(end)
            
            g = this.data_.timeInterpolants;
        end
        function g = get.times(this)
            g = this.data_.times;
        end
        function     set.times(this, s)
            this.data_.times = s;
        end
        function g = get.timesMid(this)
            g = this.times;
            g = g + this.taus/2;
        end
        function g = get.timeWindow(this)
            g = this.data_.timeWindow;
        end
        function     set.timeWindow(this, s)
            this.data_.timeWindow = s;
        end  
        
        %%        
        
        function d = datetime(this, varargin)
            d = this.data_.datetime(varargin{:});
        end        
        function this = decayCorrect(this)
            this = decayCorrect(this.data_);
        end
        function this = decayUncorrect(this)
            this = decayUncorrect(this.data_);
        end
        function d = duration(this, varargin)
            d = this.data_.duration(varargin{:});
        end        
        function h = plot(this, varargin)
            %% PLOT
            %  @param optional abscissa in {'datetime', 'datetimesMid', 'times', 'indices'}
            %  @param optional ordinate in {'countRate', 'activity', 'actvityDensity'}.
            
            ip = inputParser;
            addOptional(ip, 'abscissa', 'this.datetime', @ischar)
            addOptional(ip, 'ordinate', 'this.activityDensity', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            if length(eval(ipr.abscissa)) < 100
                marks = ':o';
            else
                marks = '.';                
            end
            
            h = figure;
            plot(eval(ipr.abscissa), eval(ipr.ordinate), marks);
            switch strtok(ipr.abscissa, '(')
                case 'this.times'
                    xlabel('time / s')
                otherwise
            end
            switch strtok(ipr.ordinate, '(')
                case 'this.countRate'
                    ylabel('count rate / cps')
                case 'this.activity'
                    ylabel('activity / Bq')
                case 'this.activityDensity'
                    ylabel('activity density / (Bq/mL)')
                otherwise
            end
            title(sprintf('%s.plot(%s)', class(this), this.data_.tracer))
        end
        function     resetTimeLimits(this)
            this.data_.resetTimeLimits();
        end
        function this = shiftWorldlines(this, timeShift)
            %% shifts worldline of internal data self-consistently
            %  @param timeShift is numeric.
            
            this.data_.shiftWorldlines(timeShift);
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        calibration_
        data_
        logger_
    end
    
    methods (Access = protected)
        function this = AbstractDevice(varargin)
            %% DEVICE
            %  @param calibration
            %  @param data
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'calibration', [])
            addParameter(ip, 'data', [])
            parse(ip, varargin{:});
            ipr = ip.Results;
            
            this.calibration_ = ipr.calibration;
            this.data_ = ipr.data;  
            this.logger_ = mlpipeline.Logger2(this);
        end        
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
            that.calibration_ = copy(this.calibration_);
            that.data_ = copy(this.data_);
            that.logger_ = copy(this.logger_);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

