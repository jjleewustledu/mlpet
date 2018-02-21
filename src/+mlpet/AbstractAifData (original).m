classdef (Abstract) AbstractAifData < mlio.AbstractIO & mlpet.IAifData
	%% ABSTRACTAIFDATA
    %  Yet abstract:  properties counts, activity; static method load; method save

	%  $Revision$
 	%  was created 29-Jan-2017 18:46:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.    
    
    properties
        isDecayCorrected
        isPlasma 
    end
    
	properties (Dependent)
        
        % IAifData        
        datetime0 % determines datetime of this.times(1)
        decays
        doseAdminDatetime
 		dt
        index0
        indexF
        time0
        timeF
        timeDuration
        times
        timeMidpoints
        taus
        isotope        
        counts
        activity
        
        % new  
        decayCorrection
        scannerData
        sessionData
        specificDecays % Bq*s/mL
        specificActivity % Bq/mL
        W
    end
    
    methods
        
        %% GET, SET
        
        function g    = get.datetime0(this)
            g = this.timingData_.datetime0;
        end
        function this = set.datetime0(this, s)
            this.timingData_.datetime0 = s;
            %this = this.updateActivities;
        end
        function g    = get.decays(this)
            g = this.specificActivity.*this.taus*this.visibleVolume;
        end
        function this = set.decays(this, s)
            assert(isnumeric(s));
            s(s < 0) = 0;
            this.specificActivity_ = s./this.taus/this.visibleVolume;
        end
        function g    = get.doseAdminDatetime(this)
            g = this.datetime0;
        end
        function this = set.doseAdminDatetime(this, s)
            assert(isa(s, 'datetime'));
            this.datetime0 = s;
            %this = this.updateActivities;
        end
        function g    = get.dt(this)
            g = this.timingData_.dt;
        end
        function this = set.dt(this, s)
            assert(s > 0);
            this.timingData_.dt = s;
        end
        function g    = get.index0(this)
            g = this.timingData_.index0;
        end
        function this = set.index0(this, s)
            this.timingData_.index0 = s;
        end
        function g    = get.indexF(this)
            g = this.timingData_.indexF;
        end
        function this = set.indexF(this, s)
            this.timingData_.indexF = s;
        end
        function g    = get.time0(this)
            g = this.timingData_.time0;
        end
        function this = set.time0(this, s)
            this.timingData_.time0 = s;
        end
        function g    = get.timeF(this)
            g = this.timingData_.timeF;
        end
        function this = set.timeF(this, s)
            this.timingData_.timeF = s;
        end
        function g    = get.timeDuration(this)
            g = this.timingData_.timeDuration;
        end
        function this = set.timeDuration(this, s)
            this.timingData_.timeDuration = s;
        end
        function g    = get.times(this)
            g = this.timingData_.times;
        end
        function this = set.times(this, s)
            this.timingData_.times = s;
        end
        function g    = get.timeMidpoints(this)
            g = this.timingData_.timeMidpoints;
        end
        function g    = get.taus(this)
            g = this.timingData_.taus;
        end
        function g    = get.isotope(this)
            if (~isempty(this.isotope_))
                g = this.isotope_;
                return
            end
            g = '';
        end
        function g    = get.counts(this)
            g = this.counts_;
        end
        function this = set.counts(this, s)
            assert(isnumeric(s));
            assert(length(s) == length(this.times));
            s(s < 0) = 0;
            this.counts_ = s;            
        end
        function g    = get.activity(this)
            g = this.specificActivity_.*this.visibleVolume;
        end
        function this = set.activity(this, s)
            assert(isnumeric(s));
            s(s < 0) = 0;
            this.specificActivity = s./this.visibleVolume;
        end
        
        function g    = get.decayCorrection(this)
            g = this.decayCorrection_;
        end
        function g    = get.scannerData(this)
            g = this.scannerData_;
        end
        function g    = get.specificActivity(this)
            g = this.specificActivity_;
        end
        function this = set.specificActivity(this, s)
            assert(isnumeric(s));
            s(s < 0) = 0;
            this.specificActivity_ = s;
        end
        function g    = get.specificDecays(this)
            g = this.specificActivity.*this.taus;
        end
        function this = set.specificDecays(this, s)
            assert(isnumeric(s));
            s(s < 0) = 0;
            this.specificActivity_ = s./this.taus;
        end
        function g    = get.W(this)
            if (isempty(this.W_))
                g = this.invEfficiency;
                return
            end
            g = this.W_;
        end  
        function this = set.W(this, s)
            assert(isnumeric(s));
            this.W_ = s;
        end        
        function g    = get.sessionData(this)
            g = this.sessionData_;
        end
        
        %% 
                
        function bi       = activityIntegral(this)
            idx0 = this.index0;
            idxF = this.indexF;
            bi = trapz(this.times(idx0:idxF), this.activity(idx0:idxF));
        end     
        function b        = activityInterpolants(this, varargin)
            b = pchip(this.times, this.activity, this.timeInterpolants);            
            if (~isempty(varargin))
                b = b(varargin{:}); end
        end
        function this     = buildCalibrated(this)
        end
        function this     = correctedActivities(this, tzero)
            if (~isempty(this.counts_))
                this.counts_ = ...
                    this.decayCorrection_.correctedActivities( ...
                    this.counts_, tzero);
            end
            if (~isempty(this.specificActivity_))
                this.specificActivity_ = ...
                    this.decayCorrection_.correctedActivities( ...
                    this.specificActivity_, tzero);
            end
        end
        function c        = countInterpolants(this, varargin)
            c = pchip(this.times, this.counts, this.timeInterpolants);            
            if (~isempty(varargin))
                c = c(varargin{:}); end
        end
        function ci       = countsIntegral(this)
            idx0 = this.index0;
            idxF = this.indexF;
            ci = trapz(this.times(idx0:idxF), this.counts(idx0:idxF));
        end   
        function dt_      = datetime(this)
            dt_ = this.timingData_.datetime;
        end
        function s        = datetime2sec(this, dt_)
            s = this.timingData_.datetime2sec(dt_);
        end
        function di       = decayInterpolants(this)
            di = [];
        end      
        function dt       = sec2datetime(this, s)
            dt = this.timingData_.sec2datetime(s);
        end
        function this     = shiftTimes(this, Dt)
            if (Dt == 0)
                return
            end
            this.timingData_ = this.timingData_.shiftTimes(Dt);
        end
        function this     = shiftWorldlines(this, Dt, varargin)
            %% SHIFTWORLDLINES
            %  @param required Dt, or \Delta t of worldline. 
            %  Dt > 0 => event occurs at later time and further away in space; boluses are smaller and arrive later.
            %  Dt < 0 => event occurs at earlier time and closer in space; boluses are larger and arrive earlier.
            %  @param optional tzero sets the Lorentz coord for decay-correction and uncorrection.  
            
            ip = inputParser;
            addParameter(ip, 'tzero', this.time0, @isnumeric);
            parse(ip, varargin{:});
            
            if (Dt == 0)
                return
            end
            this = this.correctedActivities(ip.Results.tzero);
            this = this.shiftTimes(Dt);
            this = this.uncorrectedActivities(ip.Results.tzero);
        end
        function bi       = specificActivityIntegral(this)
            idx0 = this.index0;
            idxF = this.indexF;
            bi = trapz(this.times(idx0:idxF), this.specificActivity(idx0:idxF));
        end
        function sa       = specificActivityInterpolants(this)
        end        
        function di       = specificDecaysIntegral(this)
            idx0 = this.index0;
            idxF = this.indexF;
            di = trapz(this.times(idx0:idxF), this.specificDecays(idx0:idxF));
        end   
        function [t,this] = timeInterpolants(this, varargin)
            [t,this] = this.timingData_.timeInterpolants(varargin{:});
        end
        function [t,this] = timeMidpointInterpolants(this, varargin)
            [t,this] = this.timingData_.timeMidpointInterpolants(varargin{:});
        end  
        function this     = uncorrectedActivities(this, tzero)
            if (~isempty(this.counts_))
                this.counts_ = ...
                    this.decayCorrection_.uncorrectedActivities( ...
                    this.counts_, tzero);
            end
            if (~isempty(this.specificActivity_))
                this.specificActivity_ = ...
                    this.decayCorrection_.uncorrectedActivities( ...
                    this.specificActivity_, tzero);
            end
        end
        function v        = visibleVolume(~)
            v = nan;
        end
    end 
    
    %% PROTECTED
    
    properties (Abstract, Access = protected)
        timingData_
    end
    
    properties (Access = protected)
        calibrated_ = false;
        counts_
        decayCorrection_
        isotope_
        manualData_
        scannerData_
        sessionData_
        specificActivity_
        W_
    end  
    
    methods (Access = protected)            
 		function this = AbstractAifData(varargin)
            %  @param named fqfilename of crv file.
            %  @param named sessionData.
            %  @param named manualData is mldata.IManualMeasurements.
            %  @param named isotope is char supported by mlpet.Radionuclides.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'fqfilename', '',  @(x) lexist(x, 'file'));
            addParameter(ip, 'sessionData',     @(x) isa(x, 'mlpipeline.SessionData'));
            addParameter(ip, 'scannerData', [], @(x) isa(x, 'mlpet.IScannerData') || isempty(x));
            addParameter(ip, 'manualData', [],  @(x) isa(x, 'mldata.IManualMeasurements'));
            addParameter(ip, 'isotope', '',     @(x) ischar(x) && lstrfind(x, mlpet.Radionuclides.SUPPORTED_ISOTOPES));
            parse(ip, varargin{:});            
            this.fqfilename       = ip.Results.fqfilename;
            this.sessionData_     = ip.Results.sessionData;
            this.scannerData_     = ip.Results.scannerData;
            this.manualData_      = ip.Results.manualData;
            this.isotope_         = ip.Results.isotope;
            this.decayCorrection_ = mlpet.DecayCorrection.factoryFor(this);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

