classdef Twilite < mlpet.AbstractAifData
	%% TWILITE  

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:08
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	
    
	properties (Dependent)
        tableTwilite
    end
    
    methods %% GET, SET
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
            addParameter(ip, 'scannerData', @(x) isa(x, 'mlpet.IScannerData'));
            addParameter(ip, 'twiliteCrv', '', @(x) lexist(x, 'file'));
            addParameter(ip, 'aifTimeShift', 0, @isnumeric);
            addParameter(ip, 'efficiencyFactor', 51.74, @isnumeric); % 0.5654*0.487/7.775e-3, 223*0.304
            parse(ip, varargin{:});
            
 			this = this@mlpet.AbstractAifData('scannerData', ip.Results.scannerData);
            this.fqfilename = ip.Results.twiliteCrv;
            this.tableTwilite_ = this.readtable;
            this.timingData_ = this.updatedTimingData;
            this.timingData_.interpolatedTimeShift = ip.Results.aifTimeShift;
            this.counts_ = this.tableTwilite2counts;
            this.efficiencyFactor_ = ip.Results.efficiencyFactor;
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
        function dt = datetimes(this, varargin)
            tt = this.tableTwilite_;
            dt = datetime(tt.year, tt.month, tt.day, tt.hour, tt.min, tt.sec, 'TimeZone', this.timingData_.PREFERRED_TIMEZONE);
            if (~isempty(varargin))
                dt = dt(varargin{:});
            end
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
            assert(isnumeric(Dt) && isscalar(Dt));
            this.timingData_.interpolatedTimeShift = Dt;
        end
        function v    = visibleVolume(~)
            v = 0.14; % empirically measured on Twilite
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        tableTwilite_
    end
    
    methods (Access = protected)
        function s = tableTwilite2times(this)
            tt = this.tableTwilite_;
            d = duration(tt.hour,tt.min,tt.sec);
            s = seconds(d - d(1));
            s = ensureRowVector(s);
        end
        function c = tableTwilite2counts(this)
            c = ensureRowVector(this.tableTwilite_.coincidence).*ensureRowVector(this.taus);
        end
        function td = updatedTimingData(this)
            td = this.timingData_;
            td.datetime0 = this.datetimes(1);
            td.times = this.tableTwilite2times;
            td.time0 = td.datetime2sec(this.scannerData_.sec2datetime(this.scannerData_.time0));
            td.timeF = td.datetime2sec(this.scannerData_.sec2datetime(this.scannerData_.timeF));
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

