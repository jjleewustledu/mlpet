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
        isPlasma 
        time0Shift = -2 % sec
    end
    
	properties (Dependent)
        activity          % in Bq := specificActivity*voxelVolume
        counts            % in Bq/mL := specificActivity without efficiency adjustments; native to scanner
        decayCorrection
        decays            % in Bq*s := specificActivity*voxelVolume*tau
        doseAdminDatetime
        isDecayCorrected
        isotope  
        scannerData
        sessionData  
        specificActivity  % activity/volume in Bq/mL
        specificDecays    % decays/volume in Bq*s/mL := specificActivity*tau
        tracer
        W                 % legacy notation from Videen
        
        %% IAifData
        
        times
        taus
        time0
        timeF
        timeDuration
        datetime0 
        index0
        indexF
 		dt
    end
    
    methods (Static)        
        function fluc = flucSpecificActivity(this)
            assert(isa(this, 'mlpet.AbstractAifData'));
            smpl = this.specificActivity(this.index0:this.index0+10);
            fluc = max(smpl) - min(smpl);
        end
    end
    
    methods
        
        %% GET, SET
        
        function g    = get.activity(this)
            g = this.specificActivity_.*this.visibleVolume;
        end
        function this = set.activity(this, s)
            assert(isnumeric(s));
            s(s < 0) = 0;
            this.specificActivity = s./this.visibleVolume;
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
        function g    = get.decayCorrection(this)
            g = this.decayCorrection_;
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
            g = this.doseAdminDatetime_;
        end
        function this = set.doseAdminDatetime(this, s)
            assert(isa(s, 'datetime'));
            this.doseAdminDatetime_ = s;
            %this = this.updateActivities;
        end        
        function g    = get.isDecayCorrected(this)
            g = this.isDecayCorrected_;
        end
        function this = set.isDecayCorrected(this, s)
            assert(islogical(s));
            if (this.isDecayCorrected_ == s)
                return
            end
            if (this.isDecayCorrected_)  
                this.counts_ = ...
                    this.decayCorrection_.uncorrectedActivities(this.counts_, this.time0);
                this.specificActivity_ = ...
                    this.decayCorrection_.uncorrectedActivities(this.specificActivity_, this.time0);
            else
                this.counts_ = ...
                    this.decayCorrection_.correctedActivities(this.counts_, this.time0);
                this.specificActivity_ = ...
                    this.decayCorrection_.correctedActivities(this.specificActivity_, this.time0);
            end     
            this.isDecayCorrected_ = s;
        end
        function g    = get.isotope(this)
            if (~isempty(this.isotope_))
                g = this.isotope_;
                return
            end
            if (~isempty(this.sessionData))
                g = this.sessionData.isotope;
                return
            end
            g = '';
        end
        function g    = get.scannerData(this)
            g = this.scannerData_;
        end
        function g    = get.sessionData(this)
            g = this.sessionData_;
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
        function g    = get.tracer(this)
            g = this.sessionData.tracer;
        end
        function g    = get.W(this)
            g = this.invEfficiency;
        end  
        function this = set.W(this, s)
            this.invEfficiency = s;
        end  
        
        function g    = get.times(this)
            g = this.timingData_.times;
        end
        function this = set.times(this, s)
            this.timingData_.times = s;
        end
        function g    = get.taus(this)
            g = this.timingData_.taus;
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
        function g    = get.datetime0(this)
            g = this.timingData_.datetime0;
        end
        function this = set.datetime0(this, s)
            this.timingData_.datetime0 = s;
            %this = this.updateActivities;
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
        function g    = get.dt(this)
            g = this.timingData_.dt;
        end
        function this = set.dt(this, s)
            assert(s > 0);
            this.timingData_.dt = s;
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
        function this     = calibrated(this)
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
        function di       = decayInterpolants(this)
            di = [];
        end    
        function this     = setTime0ToInflow(this)
            % ensure already deconvolved; is smooth
            sa_ = this.specificActivity;
            dsa_ = diff(sa_);                        
            [~,idx] = max(dsa_ > max(dsa_)/20);
            this.index0 = max(1, idx + this.time0Shift);
        end  
        function this     = shiftTimes(this, Dt)
            if (Dt == 0)
                return
            end
            this.timingData_ = this.timingData_.shiftTimes(Dt);
        end
        function this     = shiftWorldlines(this, t0c, t0uc)
            %% SHIFTWORLDLINES
            
            this = this.correctedActivities(t0c);
            this = this.uncorrectedActivities(t0uc); % Anzatz
        end
        function bi       = specificActivityIntegral(this)
            idx0 = this.index0;
            idxF = this.indexF;
            if (strcmpi(this.sessionData.tracer, 'OC'))
                idx0 = idx0 + 120;
                assert(idx0 < idxF);
            end
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
        doseAdminDatetime_
        isDecayCorrected_
        isotope_
        sessionData_
        specificActivity_
        
        manualData_
        scannerData_
    end  
    
    methods (Access = protected)
        function this = updateDecayCorrection(this)
            %% for adding more data by constructors of subclasses of AbstractAifData.
            
            this.decayCorrection_ = mlpet.DecayCorrection.factoryFor(this);
        end
        
 		function this = AbstractAifData(varargin)
            %  @param fqfilename of crv file.
            %  @param sessionData.
            %  @param manualData.
            %  @param scannerData.
            %  @param doseAdminDatetime is a datetime; default == NaT.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'fqfilename', '', @isfile)
            addParameter(ip, 'sessionData', [])
            addParameter(ip, 'manualData', [])
            addParameter(ip, 'scannerData', [])
            addParameter(ip, 'isotope', '', @ischar)
            addParameter(ip, 'doseAdminDatetime', NaT, @isdatetime)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.fqfilename = ipr.fqfilename;            
            if ~isfile(this.fqfilename)
                error('mlpet:fileNotFound', 'AbstractAifData.ctor');
            end
            
            this.sessionData_ = ipr.sessionData;
            this.manualData_  = ipr.manualData;
            this.scannerData_ = ipr.scannerData;
            this.isotope_     = ipr.isotope;
            if isempty(this.isotope_) && ~isempty(this.sessionData_)
                this.isotope_ = this.sessionData_.isotope;
            end
            if strncmpi(this.isotope_, 'cal', 3)
                this.isotope_ = 'FDG';
            end
            this.doseAdminDatetime_ = ipr.doseAdminDatetime;
            
            this.decayCorrection_ = mlpet.DecayCorrection.factoryFor(this);  
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

