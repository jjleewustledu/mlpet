classdef BloodSucker < mlpet.AbstractAifData
	%% BLOODSUCKER  

	%  $Revision$
 	%  was created 31-Jan-2017 18:43:38
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.

    properties        
        invEfficiency
        pumpRate = 5 % mL/min            
    end
    
    properties (Dependent)
        bloodSuckerCrv
        bloodSuckerDcv
        wellCounts
        aifTimeShift
    end
    
    methods %% GET
        function g = get.bloodSuckerCrv(this)
            g = this.bloodSuckerCrv_;
        end
        function g = get.bloodSuckerDcv(this)
            g = this.bloodSuckerDcv_;
        end
        function g = get.wellCounts(this)
            g = this.counts;
        end
        function g = get.aifTimeShift(this)
            g = this.aifTimeShift_;
        end
    end
    
    methods (Static)
        function this = load(varargin)
            this = mlpet.BloodSucker(varargin{:});
        end
    end
    
	methods
 		function this = BloodSucker(varargin)
 			this = this@mlpet.AbstractAifData(varargin{:});
 			
            import mlpet.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'bloodSuckerCrv', CRV(this.scannerData.sessionData.crv('typ','fqfn')), @(x) lexist(x, 'file'));
            addParameter(ip, 'bloodSuckerDcv', DCV(this.scannerData.sessionData.dcv('typ','fqfn')), @(x) lexist(x, 'file'));
            addParameter(ip, 'aifTimeShift',   0, @isnumeric);
            parse(ip, varargin{:});            
            this.bloodSuckerCrv_ = ip.Results.bloodSuckerCrv;
            this.bloodSuckerDcv_ = ip.Results.bloodSuckerDcv;
            this.aifTimeShift_   = ip.Results.aifTimeShift;
            this.counts_         = this.bloodSuckerDcv_.counts;
            this.fqfilename      = this.bloodSuckerDcv_.fqfilename;            
            
            this.timingData_ = mldata.TimingData( ...
                'times', this.bloodSuckerDcv_.times, ...
                'dt', 1); 
            
            this = this.shiftTimes(this.aifTimeShift);
            this = this.estimateEfficiencyFactor;   
            dc = Decay('isotope', '15O', 'activities', this.counts_, 'zerotime', -this.aifTimeShift, 'isdecaying', false);
            this.counts_ = dc.decayActivities(this.times);
            assert(length(this.counts) == length(this.taus), 'mlpet:arraySizeMismatch', 'Twilite.ctor');
            this.specificActivity_ = this.invEfficiency*this.counts./this.taus./this.visibleVolume;
            
            this = this.updateDecayCorrection;
        end
        
        function save(~)
            error('mlpet:notImplemented', 'BloodSucker.save');
        end
        function this = shiftTimes(this, Dt)
            %% SHIFTTIMES provides time-coordinate transformation
            
            assert(isnumeric(Dt));
            if (Dt == 0); return; end
            [this.times,this.counts_] = shiftVector(this.times, this.counts_, Dt);
        end
        function wc   = wellCountInterpolants(this, varargin)
            wc = this.countInterpolants(varargin{:});
        end
        function wi   = wellCountsIntegral(this)
            wi = this.countsIntegral;
        end
        function v    = visibleVolume(this)
            v = this.pumpRate*min(this.taus)/60;
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        bloodSuckerCrv_
        bloodSuckerDcv_
        aifTimeShift_
        timingData_
    end
    
    methods (Access = protected)
        function this = estimateEfficiencyFactor(this)
            try
                if (isempty(this.bloodSuckerDcv_.wellFactor))
                    this.bloodSuckerDcv_ = this.bloodSuckerDcv_.readdcv; end
                this.invEfficiency = this.bloodSuckerDcv_.wellFactor;
            catch ME
                handwarning(ME);
                try
                    if (isempty(this.bloodSuckerDcv_.wellFactor))
                        this.bloodSuckerDcv_ = this.bloodSuckerDcv_.readWellFactor; end
                    this.invEfficiency = this.bloodSuckerDcv_.wellFactor;
                catch ME1
                    handwarning(ME1);
                    try                        
                        if (isempty(this.bloodSuckerDcv_.wellFactor))
                            this.bloodSuckerDcv_ = this.bloodSuckerDcv_.readWellMatrix; end
                        this.invEfficiency = this.bloodSuckerDcv_.wellFactor;
                    catch ME2
                        handexcept(ME2);
                    end
                end
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

