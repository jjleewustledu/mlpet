classdef Twilite < mlpet.AbstractAifData
	%% TWILITE  

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

    properties
        pumpRate = 5 % mL/min
    end
    
	properties (Dependent)
        becquerelsPerCC % Bq/cc
        tableTwilite
    end
    
    methods %% GET, SET
        function g = get.becquerelsPerCC(this)
            g = this.becquerels/(this.pumpRate/60);
        end
        function g = get.tableTwilite(this)
            g = this.tableTwilite_;
        end
    end

    methods (Static)
        function this = load(varargin)
            this = mlpet.Twilite(varargin{:});
        end
    end
    
	methods
 		function this = Twilite(varargin)
 			%% TWILITE
 			%  Usage:  this = Twilite()

            ip = inputParser;
            addRequired( ip, 'scannerData', @(x) isa(x, 'mlpet.IScannerData'));
            addParameter(ip, 'twiliteCrv', '', @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
 			this = this@mlpet.AbstractAifData('scannerData', ip.Results.scannerData);
            this.fqfilename = ip.Results.twiliteCrv;
            this.tableTwilite_ = this.readtable;
            this.counts_ = this.tableTwilite2counts;
            this.timingData_ = this.updatedTimingData;
        end
        
        function b = becquerelPerCCInterpolants(this, varargin)
            b = pchip(this.times, this.becquerelsPerCC, this.timeInterpolants);            
            if (~isempty(varargin))
                b = b(varargin{:}); end
        end
        function bi = becquerelsPerCCIntegral(this)
            [~,idx0] = max(this.times >= this.time0);
            [~,idxF] = max(this.times >= this.timeF);
            bi = trapz(this.times(idx0:idxF), this.becquerelsPerCC(idx0:idxF));
        end
        function this = crossCalibrate(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.IScanner'));
            addParameter(ip, 'wellCounter', [], @(x) isa(x, 'mlpet.IBloodData'));
            addParameter(ip, 'aifSampler', this, @(x) isa(x, 'mlpet.IAifData'));
            parse(ip, varargin{:});
            
            cc = mlpet.CrossCalibrator(varargin{:});
            this.efficiencyFactor_ = cc.aifSamplerEfficiency;
        end
        function dt = datetime(this)
            tt = this.tableTwilite_;
            dt = datetime(tt.year, tt.month, tt.day, tt.hour, tt.min, tt.sec);
        end
        function save(~)
            error('mlpet:notImplemented', 'Twilite.save');
        end
        function tbl = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfnCrv', this.fqfilename, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            tbl = readtable(ip.Results.fqfnCrv, ...
                'FileType', 'text', 'ReadVariableNames', false, 'ReadRowNames', false);
            tbl.Properties.VariableNames{'Var1'} = 'year';
            tbl.Properties.VariableNames{'Var2'} = 'month';
            tbl.Properties.VariableNames{'Var3'} = 'day';
            tbl.Properties.VariableNames{'Var4'} = 'hour';
            tbl.Properties.VariableNames{'Var5'} = 'min';
            tbl.Properties.VariableNames{'Var6'} = 'sec';
            tbl.Properties.VariableNames{'Var7'} = 'coincidence';
            tbl.Properties.VariableNames{'Var8'} = 'channel1';
            tbl.Properties.VariableNames{'Var9'} = 'channel2';
        end
        function this = shiftTimes(this, Dt)
            assert(isnumeric(Dt));
            [this.times_,this.counts_] = shiftVector(this.times_, this.counts_, Dt);
            this.scannerData_ = this.scannerData_.shiftTimes(Dt);
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        tableTwilite_
    end
    
    methods (Access = protected)
        function s = datetime2seconds(this)
            tt = this.tableTwilite_;
            d = duration(tt.hour,tt.min,tt.sec);
            s = seconds(d - d(1));
            s = ensureRowVector(s);
        end
        function c = tableTwilite2counts(this)
            c = ensureRowVector(this.tableTwilite_.coincidence);
        end
        function td = updatedTimingData(this)
            td = this.timingData_;
            dt = datetime(this);
            td.datetime0 = dt(1);
            td.times = this.datetime2seconds;
            [~,idx0] = max(this.counts > 0.3*max(this.counts)); % KLUDGE
            td.time0 = td.times(idx0);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

