classdef Caprac < mlpet.AbstractAifData
	%% CAPRAC  

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties 
        dryWeight % as col vector
        wetWeight % as col vector
        drawn     % datetime
        counted   % datetime        
        drawnMin   % as col vector
        drawnSec   % as col vector
        countedMin % as col vector
        countedSec % as col vector
        nSyringes  % quantity of syringes used        
        
        uncorrected = false
    end 
    
	properties (Dependent)
        clockDurationOffsets
        datetimeDrawn
        DACGe68      
        scannerData
        tableCaprac        
    end
    
    methods %% GET/SET
        function g = get.clockDurationOffsets(this)
            c = this.tableCaprac_.clocks{:,'TimeOffsetWrtNTS____s'};
            s = sign(c);
            c = datetime(abs(c), 'ConvertFrom', 'excel') - datetime(1899,12,31);
            g = s.*duration(c);
        end
        function g = get.datetimeDrawn(this)
            g = this.datetimes;
        end
        function g = get.DACGe68(this)
            g = this.tableCaprac_.well.DECAY_APERTURECORRGE_68_Kdpm_G;
            g = g(this.validSamples_);
        end
        function g = get.scannerData(this)
            g = this.scannerData_;
        end
        function g = get.tableCaprac(this)
            g = this.tableCaprac_;
        end
    end

    methods (Static)
        function this = load(varargin)
            this = mlpet.Caprac(varargin{:});
        end
    end
      
	methods 		  
 		function this = Caprac(varargin)
 			%% CAPRAC
 			%  Usage:  this = Caprac()

            ip = inputParser;
            addParameter(ip, 'scannerData', @(x) isa(x, 'mlpet.IScannerData'));
            addParameter(ip, 'capracXlsx', '', @(x) lexist(x, 'file'));
            addParameter(ip, 'aifTimeShift', 0, @isnumeric);
            addParameter(ip, 'efficiencyFactor', 1/0.9499, @isnumeric);
            parse(ip, varargin{:});
            
            this = this@mlpet.AbstractAifData('scannerData', ip.Results.scannerData);    
            this.fqfilename = this.sessionData.CCIRRadMeasurementsTable;        
 			[~,this] = readtable(this); 
            this.scannerData_ = this.updatedScannerData;
            this.timingData_ = this.updatedTimingData;
            this.efficiencyFactor_ = ip.Results.efficiencyFactor;
            this.counts_ = this.tableCaprac2counts;
            this.interpolatedTimeShift = ip.Results.aifTimeShift;              
            this.becquerelsPerCC_ = this.tableCaprac2becquerelsPerCC;
            
            dc = mlpet.DecayCorrection(this);
            tshift = seconds(this.doseAdminDatetime - this.datetime0);
            if (tshift > 3600); tshift = 0; end %% KLUDGE
            if (this.uncorrected)
                this.becquerelsPerCC_ = dc.uncorrectedCounts(this.becquerelsPerCC_, tshift);
            end
        end
        
        function this = crossCalibrate(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.IScanner'));
            addParameter(ip, 'wellCounter', [], @(x) isa(x, 'mlpet.IBloodData'));
            addParameter(ip, 'aifSampler', this, @(x) isa(x, 'mlpet.IAifData'));
            parse(ip, varargin{:});
            
            cc = mlpet.CrossCalibrator(varargin{:});
            this.efficiencyFactor_ = cc.wellCounterEfficiency;
        end
        function dt = datetimes(this, varargin)
            dt = this.tableCaprac_.well.TIMEDRAWN_Hh_mm_ss;
            dt = dt(this.validSamples_);
            dt.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            dt = dt - this.clockDurationOffsets(5);
            if (~isempty(varargin))
                dt = dt(varargin{:});
            end
        end
        function save(~)
            error('mlpet:notImplemented', 'Caprac.save');
        end
        function [tbl,this] = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfnXlsx', this.fqfilename, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            warning('off', 'MATLAB:table:ModifiedVarnames');
            well = readtable(ip.Results.fqfnXlsx, 'Sheet', 'Radiation Counts Log - Runs', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            tradmin = readtable(ip.Results.fqfnXlsx, 'Sheet', 'Radiation Counts Log - Runs-2', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            clocks0 = readtable(ip.Results.fqfnXlsx, 'Sheet', 'Twilite Calibration - Table 1', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', false, 'ReadRowNames', false);
            clocks = readtable(ip.Results.fqfnXlsx, 'Sheet', 'Twilite Calibration - Runs', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', true);
            warning('on', 'MATLAB:table:ModifiedVarnames');
            tbl.well = well;
            tbl.tradmin = tradmin;
            tbl.clocks0 = clocks0;
            tbl.clocks = clocks;            
            this.tableCaprac_ = tbl;
            this.validSamples_ = ~isnat(tbl.well.TIMEDRAWN_Hh_mm_ss) & ...
                                 strcmp(tbl.well.TRACER, '[18F]DG');
        end
        function this = shiftTimes(this, Dt)
            assert(isnumeric(Dt) && isscalar(Dt));
            this.timingData_.interpolatedTimeShift = Dt;
        end
        function v    = visibleVolume(this)
            mass = this.tableCaprac_.well.MassSample_G;
            mass = mass(this.validSamples_);
            mass = mass/mlpet.AbstractHerscovitch1985.BRAIN_DENSITY;
            v    = ensureRowVector(mass); % empirically measured on Caprac
        end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        validSamples_
        tableCaprac_
    end

    methods (Access = protected)
        function t = tableCaprac2times(this)
            t = seconds(this.datetimes - this.datetimes(1));
            t = ensureRowVector(t);
        end
        function c = tableCaprac2counts(this)
            c = 1000*this.tableCaprac_.well.W_01_Kcpm(this.validSamples_);
            c = ensureRowVector(c);
        end
        function b = tableCaprac2becquerelsPerCC(this)
            b = (1000/60)*this.DACGe68*mlpet.AbstractHerscovitch1985.BRAIN_DENSITY;
            b = ensureRowVector(b);
        end
        function td = updatedTimingData(this)
            td = this.timingData_;
            td.times = this.tableCaprac2times;
            td.datetime0 = this.datetimes(1);
            td.time0 = td.datetime2sec(this.scannerData_.sec2datetime(this.scannerData_.time0));
            td.timeF = td.datetime2sec(this.scannerData_.sec2datetime(this.scannerData_.timeF));
            td.dt = min(td.taus);
        end
        function sd = updatedScannerData(this)
            sd = this.scannerData_;
            adminDatetime = this.tableCaprac_.tradmin{7, 'ADMINistrationTime_Hh_mm_ss'};
            adminDatetime.Year = adminDatetime.Year + 4; % KLUDGE
            adminDatetime.Day  = adminDatetime.Day + 1;  % KLUDGE
            sd.doseAdminDatetime = adminDatetime - this.clockDurationOffsets(5);
            sd.doseAdminDatetime.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
            sd.datetime0 = sd.datetime0 - this.clockDurationOffsets(1);
            sd.datetime0.TimeZone = mldata.TimingData.PREFERRED_TIMEZONE;
        end
    end
    
    %% HIDDEN, DEPRECATED
    
    properties (Hidden)        
        variableCountTime = nan
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

