classdef (Abstract) AbstractAifData < mlio.AbstractIO & mlpet.IAifData
	%% ABSTRACTAIFDATA
    %  Yet abstract:  properties counts, becquerels; static method load; method save

	%  $Revision$
 	%  was created 29-Jan-2017 18:46:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties (Dependent)
        
        %% IAifData
        
        sessionData
        datetime0
        doseAdminDatetime
 		dt
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
            this.timingData_.dt = s;
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
            if (isnumeric(s) && s < this.times(end) - this.time0)
                this.timeF = this.time0 + s;
                return
            end            
            warning('mlpet:setPropertyIgnored', 'AbstractAifData.set.timeDuration');
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
            if (length(this.counts_) > length(this.times)) 
                warning('mlpet:unexpectedDataSize', ...
                        'BloodSucker.get.counts found size(this.counts_)->%s, length(this.times)->%i', ...
                        num2str(length(this.counts_)), length(this.times)); 
                this.counts_ = this.counts_(1:length(this.times));
            end
            g = this.counts_;
        end
        function this = set.counts(this, s)
            assert(isnumeric(s));
            assert(length(s) == length(this.times));
            this.counts_ = s;            
        end
        function g    = get.becquerels(this)
            g = this.efficiencyFactor*this.counts./this.taus;
        end
        
        %% new
        
        function g = get.W(this)
            g = this.scannerData_.W*this.dt/this.scannerData_.dt;
        end
    end

	methods 
 		function this = AbstractAifData(varargin)
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'scannerData', [], @(x) isa(x, 'mlpet.IScannerData'));
            parse(ip, varargin{:});
            
            this.scannerData_ = ip.Results.scannerData;
            this.timingData_ = mldata.TimingData;
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
        function ci       = countsIntegral(this)
            [~,idx0] = max(this.times >= this.time0);
            [~,idxF] = max(this.times >= this.timeF);
            ci = trapz(this.times(idx0:idxF), this.counts(idx0:idxF));
        end
        function b        = becquerelInterpolants(this, varargin)
            b = pchip(this.times, this.becquerels, this.timeInterpolants);            
            if (~isempty(varargin))
                b = b(varargin{:}); end
        end
        function bi       = becquerelsIntegral(this)
            [~,idx0] = max(this.times >= this.time0);
            [~,idxF] = max(this.times >= this.timeF);
            bi = trapz(this.times(idx0:idxF), this.becquerels(idx0:idxF));
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        counts_
        efficiencyFactor_ = nan
        scannerData_
        timingData_
    end  

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

