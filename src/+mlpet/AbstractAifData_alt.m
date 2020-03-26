classdef (Abstract) AbstractAifData_alt < mlio.AbstractIO & mlpet.IAifData
	%% ABSTRACTAIFDATA
    %  Yet abstract:  properties counts, becquerels; static method load; method save

	%  $Revision$
 	%  was created 29-Jan-2017 18:46:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

    properties (Constant)
        SPECIFIC_ACTIVITY_KIND = 'becquerelsPerCCIntegral' % 'decaysPerCCIntegral'
    end
    
    properties
        pumpRate = 5 % mL/min
    end
    
	properties (Dependent)
        
        %% IAifData
        
        sessionData
        datetime0 % determines datetime of this.times(1)
        doseAdminDatetime
 		dt
        index0
        interpolatedTimeShift
        indexF
        time0
        timeF
        timeDuration
        times
        timeMidpoints
        taus
        efficiencyFactor
        isotope        
        counts
        becquerels
        
        %% new
        
        becquerelsPerCC % Bq/cc
        decaysPerCC % Bq*s/cc
        specificActivity
        W
    end
    
    methods %% GET, SET
        
        %% IAifData
        
        function g    = get.sessionData(this)
            g = this.scannerData_.sessionData;
        end
        function this = set.sessionData(this, s)
            assert(isa(s, 'mlpipeline.SessionData'));
            this.scannerData_.sessionData = s;
        end
        function g    = get.datetime0(this)
            g = this.timingData_.datetime0;
        end
        function this = set.datetime0(this, s)
            this.timingData_.datetime0 = s;
        end
        function g    = get.doseAdminDatetime(this)
            g = this.scannerData_.doseAdminDatetime;
        end
        function this = set.doseAdminDatetime(this, s)
            assert(isa(s, 'datetime'));
            this.scannerData_.doseAdminDatetime = s;
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
        function g    = get.interpolatedTimeShift(this)
            g = this.timingData_.interpolatedTimeShift;
        end
        function this = set.interpolatedTimeShift(this, s)
            if (abs(s) > 0)
                this.timingData_.interpolatedTimeShift = s;
                this.decayCorrection_ = mlpet.DecayCorrection(this);
                [~,this.counts] = this.decayCorrection_.shiftUncorrectedCounts(this.times, this.counts, s);
            end
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
        function g    = get.efficiencyFactor(this)
            g = this.efficiencyFactor_;
        end
        function g    = get.isotope(this)
            g = this.scannerData_.isotope;
        end
        function g    = get.counts(this)
            assert(~isempty(this.counts_));
            g = this.counts_;
        end
        function this = set.counts(this, s)
            assert(isnumeric(s));
            assert(length(s) == length(this.times));
            s(s < 0) = 0;
            this.counts_ = s;            
        end
        function g    = get.becquerels(this)
            g = this.becquerelsPerCC_.*this.visibleVolume;
        end
        function this = set.becquerels(this, s)
            assert(isnumeric(s));
            s(s < 0) = 0;
            this.becquerelsPerCC = s./this.visibleVolume;
        end
        
        %% new
        
        function g    = get.becquerelsPerCC(this)
            g = this.becquerelsPerCC_;
        end
        function this = set.becquerelsPerCC(this, s)
            assert(isnumeric(s));
            s(s < 0) = 0;
            this.becquerelsPerCC_ = s;
        end
        function g    = get.decaysPerCC(this)
            g = this.becquerelsPerCC.*this.taus;
        end
        function this = set.decaysPerCC(this, s)
            assert(isnumeric(s));
            s(s < 0) = 0;
            this.becquerelsPerCC_ = s./this.taus;
        end
        function g    = get.specificActivity(this)
            g = this.(this.scannerData_.SPECIFIC_ACTIVITY_KIND);
        end
        function this = set.specificActivity(this, s)
            assert(isnumeric(s));
            this.(this.scannerData_.SPECIFIC_ACTIVITY_KIND) = s;
        end
        function g    = get.W(this)
            assert(this.dt == this.scannerData_.dt);
            g = this.scannerData_.W;
        end
    end
    
    methods (Abstract)
        v = visibleVolume(this)
    end

	methods 
 		function this = AbstractAifData_alt(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'scannerData', [], @(x) isa(x, 'mlpet.IScannerData'));
            parse(ip, varargin{:});
            
            this.scannerData_ = ip.Results.scannerData;
            this.timingData_ = mldata.TimingData;
            this.timingData_.dt = this.scannerData_.dt;
        end
        
        %% IAifData
        
        function len      = length(this)
            len = this.timingData_.length;
        end
        function [t,this] = timeInterpolants(this, varargin)
            [t,this] = this.timingData_.timeInterpolants(varargin{:});
        end
        function [t,this] = timeMidpointInterpolants(this, varargin)
            [t,this] = this.timingData_.timeMidpointInterpolants(varargin{:});
        end
        function [t,this] = tauInterpolants(this, varargin)
            [t,this] = this.timingData_.tauInterpolants(varargin{:});
        end    
        function c        = countInterpolants(this, varargin)
            c = pchip(this.times, this.counts, this.timeInterpolants);            
            if (~isempty(varargin))
                c = c(varargin{:}); end
        end
        function b        = becquerelInterpolants(this, varargin)
            b = pchip(this.times, this.becquerels, this.timeInterpolants);            
            if (~isempty(varargin))
                b = b(varargin{:}); end
        end
        function ci       = countsIntegral(this)
            idx0 = this.index0;
            idxF = this.indexF;
            ci = trapz(this.times(idx0:idxF), this.counts(idx0:idxF));
        end
        function bi       = becquerelsIntegral(this)
            idx0 = this.index0;
            idxF = this.indexF;
            bi = trapz(this.times(idx0:idxF), this.becquerels(idx0:idxF));
        end
        
        %% new
        
        function bi       = becquerelsPerCCIntegral(this)
            idx0 = this.index0;
            idxF = this.indexF;
            bi = trapz(this.times(idx0:idxF), this.becquerelsPerCC(idx0:idxF));
        end
        function di       = decaysPerCCIntegral(this)
            idx0 = this.index0;
            idxF = this.indexF;
            di = trapz(this.times(idx0:idxF), this.decaysPerCC(idx0:idxF));
        end
        function sa       = specificActivityIntegral(this)
            sa = this.(this.SPECIFIC_ACTIVITY_KIND);
        end      
        function s        = datetime2sec(this, dt)
            s = this.timingData_.datetime2sec(dt);
        end
        function dt       = sec2datetime(this, s)
            dt = this.timingData_.sec2datetime(s);
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        becquerelsPerCC_
        counts_
        decayCorrection_
        efficiencyFactor_ = nan
        scannerData_
        timingData_
    end  

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

