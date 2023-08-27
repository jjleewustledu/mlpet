classdef (Abstract) AbstractTracerData < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable & ...
                                         mldata.ITiming & mlpet.ITracerData
	%% ABSTRACTTRACERDATA is an abstract factory pattern.
    %  For concrete subclasses see also:  mlcapintec.CapracData, mlswisstrace.TwiliteData, mlpet.BloodSuckerData, 
    %  mlsiemens.BiographMMRData, mlsiemens.EcatExactHRPlusData, and similarly named classes for project packages such
    %  as mlpowers, mlarbelaez, mlraichle.

	%  $Revision$
 	%  was created 17-Oct-2018 15:54:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
    
	properties (Dependent) 
        branchingRatio
        datetimeForDecayCorrection  
        decayCorrected
        halflife
        isotope
        timeForDecayCorrection
        tracer
        
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

	methods %% GET, SET
        function g = get.branchingRatio(this)
            g = this.radionuclides_.branchingRatio;
        end
        function g = get.datetime0(this)
            g = this.timingData_.datetime0;
        end
        function     set.datetime0(this, s)
            this.timingData_.datetime0 = s;
        end
        function g = get.datetimeF(this)
            g = this.timingData_.datetimeF;
        end
        function     set.datetimeF(this, s)
            this.timingData_.datetimeF = s;
        end
        function g = get.datetimeForDecayCorrection(this)
            g = this.datetimeMeasured + seconds(this.timeForDecayCorrection);
        end
        function     set.datetimeForDecayCorrection(this, s)
            assert(isdatetime(s) && ~isnat(s))
            this.timeForDecayCorrection = this.timing2num(s - this.datetimeMeasured);
        end
        function g = get.datetimeInterpolants(this)
            g = this.timingData_.datetimeInterpolants;
        end
        function g = get.datetimeMeasured(this)
            g = this.timingData_.datetimeMeasured;
        end
        function     set.datetimeMeasured(this, s)
            this.timingData_.datetimeMeasured = s;
        end
        function g = get.datetimes(this)
            g = this.timingData_.datetimes;
        end
        function g = get.datetimesMid(this)
            g = this.timingData_.datetimes + seconds(this.taus/2);
        end
        function g = get.datetimeWindow(this)
            g = this.timingData_.datetimeWindow;
        end
        function     set.datetimeWindow(this, s)
            this.timingData_.datetimeWindow = s;
        end
        function g = get.decayCorrected(this)
            g = this.decayCorrected_;
        end
        function g = get.dt(this)
            g = this.timingData_.dt;
        end
        function     set.dt(this, s)
            this.timingData_.dt = s;
        end
        function g = get.halflife(this)
            g = this.radionuclides_.halflife;
        end
        function g = get.index0(this)
            g = this.timingData_.index0;
        end
        function     set.index0(this, s)
            this.timingData_.index0 = s;
        end
        function g = get.indexF(this)
            g = this.timingData_.indexF;
        end
        function     set.indexF(this, s)
            this.timingData_.indexF = s;
        end
        function g = get.indices(this)
            g = this.timingData_.indices;
        end
        function g = get.isotope(this)
            g = this.radionuclides_.isotope;
        end
        function g = get.taus(this)
            g = this.timingData_.taus;
        end  
        function     set.taus(this, s)
            this.timingData_.taus = s;
        end
        function g = get.time0(this)
            g = this.timingData_.time0;
        end
        function     set.time0(this, s)
            this.timingData_.time0 = s;
        end
        function g = get.timeF(this)
            g = this.timingData_.timeF;
        end
        function     set.timeF(this, s)
            this.timingData_.timeF = s;
        end
        function g = get.timeForDecayCorrection(this)
            if isnan(this.timeForDecayCorrection_) || ~isnumeric(this.timeForDecayCorrection_) || isempty(this.timeForDecayCorrection_)
                g = this.timingData_.time0;
                return
            end
            g = this.timeForDecayCorrection_;
        end
        function     set.timeForDecayCorrection(this, s)
            assert(~isnan(s) && isnumeric(s) && ~isempty(s))
            this.timeForDecayCorrection_ = s;
        end
        function g = get.timeInterpolants(this)
            %% GET.TIMEINTERPOLANTS are uniformly separated by this.dt
            %  @returns interpolants this.times(1):this.dt:this.times(end)
            
            g = this.timingData_.timeInterpolants;
        end
        function g = get.times(this)
            g = this.timingData_.times;
        end
        function     set.times(this, s)
            this.timingData_.times = s;
        end
        function g = get.timesMid(this)
            g = this.times;
            g = g + this.taus/2;
        end
        function g = get.timeWindow(this)
            g = this.timingData_.timeWindow;
        end
        function     set.timeWindow(this, s)
            this.timingData_.timeWindow = s;
        end  
        function g = get.tracer(this)
            g = this.tracer_;
        end
    end
       
    methods
        function d = datetime(this)
            d = this.timingData_.datetime();
        end
        function d = duration(this)
            %% timeF  - time0, in sec            
            
            d = this.timingData_.duration();
        end
        function l = length(this)
            %% indexF - index0 + 1
            
            l = this.indexF - this.index0 + 1;
        end
        function h = plot(this, varargin)
            %% PLOT
            %  @param optional abscissa in {'datetime', 'times', 'indices'}
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
                case 'this.activity_kdpm'
                    ylabel('activity / kdpm')
                case 'this.activityDensity'
                    ylabel('activity density / (Bq/mL)')
                otherwise
            end
            title(sprintf('%s.plot(%s)', class(this), this.tracer))
        end
        function     resetTimeLimits(this)
            this.timingData_.resetTimeLimits();
        end
        function n = timing2num(this, t)
            %% TIMING2NUM
            %  @param t is datetime | duration | arg of double.
            %  @returns n is numeric in sec.
            
            n = this.timingData_.timing2num(t);
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        decayCorrected_
        radionuclides_
        timeForDecayCorrection_
        timingData_
        tracer_
    end
    
    methods (Access = protected)		  
 		function this = AbstractTracerData(varargin)
 			%% ABSTRACTTRACERDATA
            %  @param isotope in mlpet.Radionuclides.SUPPORTED_ISOTOPES.  MANDATORY.
            %  @param tracer.
            %  @param datetimeMeasured is the measured datetime for times(1).
 			%  @param datetimeForDecayCorrection.
            %  @param dt is numeric and must satisfy Nyquist requirements of the client.
 			%  @param taus  are frame durations.
 			%  @param time0 >= this.times(1).
 			%  @param timeF <= this.times(end).
 			%  @param times are frame starts.
            
            import mldata.TimingData
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'isotope', '', @(x) ismember(x, mlpet.Radionuclides.SUPPORTED_ISOTOPES))
            addParameter(ip, 'tracer', '', @istext)
            addParameter(ip, 'datetimeMeasured', NaT, @isdatetime);
            addParameter(ip, 'datetimeForDecayCorrection', NaT, @isdatetime)
            addParameter(ip, 'dt', 1, @isnumeric);
            addParameter(ip, 'taus', [], @TimingData.isniceDur);
            addParameter(ip, 'time0', -inf, @isnumeric); % time0 > times(1) drops early times
            addParameter(ip, 'timeF', inf, @isnumeric);  % timeF < times(end) drops late times
            addParameter(ip, 'times', [], @TimingData.isniceDat);
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.radionuclides_ = mlpet.Radionuclides(ipr.isotope);
            this.tracer_ = ipr.tracer;
            this.constructTimingData(ipr)
            this.timingData_.datetimeMeasured = ipr.datetimeMeasured;
            if isnat(ipr.datetimeForDecayCorrection) || ~isdatetime(ipr.datetimeForDecayCorrection)
                ipr.datetimeForDecayCorrection = ipr.datetimeMeasured;
            end
            this.timeForDecayCorrection_ = this.timing2num(ipr.datetimeForDecayCorrection - ipr.datetimeMeasured);
 		end
        function constructTimingData(this, ipr)
            this.timingData_ = mldata.TimingData( ...
                'taus', ipr.taus, ...
                'times', ipr.times, ...
                'time0', ipr.time0, ...
                'timeF', ipr.timeF, ...
                'datetimeMeasured', ipr.datetimeMeasured, ...
                'dt', ipr.dt);
        end
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
            that.timingData_ = copy(this.timingData_);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

