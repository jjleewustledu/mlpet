classdef AbstractTwilite < mlpet.AbstractAifData
	%% ABSTRACTTWILITE  

	%  $Revision$
 	%  was created 20-Jul-2017 00:21:47 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
    methods (Abstract)        
    end
    
    properties (Constant)
        VISIBLE_VOLUME = 0.14
        BASELINE_TIMEPOINTS = 60
    end
    
	properties (Dependent)
        countsBaseline
        tableTwilite
    end

	methods 
        
        %% GET 
        
        function g = get.countsBaseline(this)
            baselineSmpl = this.counts(1:this.BASELINE_TIMEPOINTS);
            baselineDyn = max(baselineSmpl)/min(baselineSmpl);
            assert(0.5 < baselineDyn && baselineDyn < 2);
            g = mean(baselineSmpl);
        end
        function g = get.tableTwilite(this)
            g = this.tableTwilite_;
        end
                
        %%        
        
        function this = crossCalibrate(this, varargin)
        end
        function dt = datetime(this, varargin)
            tt = this.tableTwilite_;
            dt = datetime(tt.year, tt.month, tt.day, tt.hour, tt.min, tt.sec, 'TimeZone', this.timingData_.PREFERRED_TIMEZONE);
            if (~isempty(varargin))
                dt = dt(varargin{:});
            end
        end
        function this = readtable(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfnCrv', this.fqfilename, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});            
            
            warning('off', 'MATLAB:table:ModifiedVarnames');   
            warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');  
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
            this.tableTwilite_ = tbl;
            warning('on', 'MATLAB:table:ModifiedVarnames');
            warning('on', 'MATLAB:table:ModifiedAndSavedVarnames');
            
            this.isPlasma = false;                   
        end
        function save(~)
            error('mlpet:notImplemented', 'Twilite.save');
        end
        function v    = visibleVolume(this)
            v = this.arterialCatheterVisibleVolume*ones(size(this.times)); % empirically measured on Twilite
        end
        
 		function this = AbstractTwilite(varargin)
 			%% ABSTRACTTWILITE
 			%  Usage:  this = AbstractTwilite()

 			this = this@mlpet.AbstractAifData(varargin{:});
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        tableTwilite_
    end
    
    methods (Access = protected)
        function vv = arterialCatheterVisibleVolume(this)
            %% approx. visible volume of 1mm outer-diam. catheter fed into Twilite
            
            entry = this.xlsxObj_.twilite.TWILITE(1);
            entry = entry{1};
            assert(ischar(entry));
            if (lstrfind(entry, 'Medex REF 536035')) % 152.4 cm  Ext. W/M/FLL Clamp APV = 1.1 mL; cut at 40 cm
                vv = 0.14; % mL
                return
            end
            if (lstrfind(entry, 'Braun ref V5424')) % 48 cm len, 0.642 mL priming vol
                vv = 0.27; % mL
                return
            end
            error('mpet:unsupportedParamValue', 'AbstractTwilite:arterialCatheterVisibleVolume');
        end
        function s = tableTwilite2times(this)
            tt = this.tableTwilite_;
            d = duration(tt.hour,tt.min,tt.sec);
            s = seconds(d - d(1));
            s = ensureRowVector(s);
        end
        function c = tableTwilite2counts(this)
            c = ensureRowVector(this.tableTwilite_.coincidence);
        end
        function this = updateTimingData(this)
            td = this.timingData_;
            td.datetime0 = this.datetime(1);
            td.times = this.tableTwilite2times;
            td.time0 = td.datetime2sec(this.scannerData_.sec2datetime(this.scannerData_.time0));
            td.timeF = td.datetime2sec(this.scannerData_.sec2datetime(this.scannerData_.timeF));
            td.dt = min(td.taus); % N.B. consistency of dt between instruments
            this.timingData_ = td;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

