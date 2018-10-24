classdef CCIRRadMeasurements < handle & mldata.Xlsx & mlpet.RadMeasurements
	%% CCIRRADMEASUREMENTS has dynamic properties named by this.tableNames.

    % capracHeader
    % this.capracHeader -> 4×4 table
    %     Var1             Var2                   Var3                   Var4    
    % _____________    _____________    _________________________    ____________
    % 'DATE:'          '09-Sep-2016'    'PROJECT ID:'                'CCIR_00754'
    % 'SUBJECT ID:'    'HYGLY28'        'PRINCIPLE INVESTIGATOR:'    'Arbelaez'  
    % 'ISOTOPES:'      ''               'DOSES DELIVERED / mCi:'     '115.9'     
    % ''               ''               'OPERATOR:'                  'JJL'   

    % countsFdg
    % this.fdg -> 38×17 table
    % TUBE       Time_Hh_mm_ss        COUNTS_Cpm    countsS_E__Cpm    ENTERED     TRACER       TIMEDRAWN_Hh_mm_ss     TIMECOUNTED_Hh_mm_ss    W_01_Kcpm    CF_Kdpm    Ge_68_Kdpm    MASSDRY_G    MASSWET_G      MASSSAMPLE_G       apertureCorrGe_68_Kdpm_G    TRUEDECAY_APERTURECORRGe_68_Kdpm_G          COMMENTS      
    % ____    ____________________    __________    ______________    _______    _________    ____________________    ____________________    _________    _______    __________    _________    _________    _________________    ________________________    __________________________________    ____________________
    % 26      09-Sep-2016 11:37:00    '813'         NaN               false      '[18F]DG'    09-Sep-2016 12:01:02    09-Sep-2016 12:09:18      NaN          NaN           0        3.7736       4.3328                  0.5592                    0                           0                     ''                  
    % ...

    % countsOcOo
    % this.oo -> 4×17 table
    % TUBE       Time_Hh_mm_ss        COUNTS_Cpm    countsS_E__Cpm    ENTERED     TRACER      TIMEDRAWN_Hh_mm_ss     TIMECOUNTED_Hh_mm_ss    W_01_Kcpm    CF_Kdpm    Ge_68_Kdpm    MASSDRY_G    MASSWET_G    MassSample_G    apertureCorrGe_68_Kdpm_G    DECAY_APERTURECORRGe_68_Kdpm_G    COMMENTS
    % ____    ____________________    __________    ______________    _______    ________    ____________________    ____________________    _________    _______    __________    _________    _________    ____________    ________________________    ______________________________    ________
    % '1'     09-Sep-2016 09:12:00    189           NaN               true       'O[15O]'    09-Sep-2016 10:23:08    09-Sep-2016 10:29:57    NaN          NaN        442.8         3.7859       5.5693       1.7834          307.050645885317            1589.89417549421                  ''      
    % 'P1'    09-Sep-2016 10:14:00    210           NaN               true       'O[15O]'    09-Sep-2016 10:23:08    09-Sep-2016 10:34:37    NaN          NaN        21.07         3.8478       4.5595       0.7117          29.5276730836604            748.030808434861                  'Plasma'
    % '2'     09-Sep-2016 10:44:00    224           NaN               true       'O[15O]'    09-Sep-2016 11:23:45    09-Sep-2016 11:32:10    NaN          NaN        126.3         3.8263       5.3021       1.4758          97.5833310265788            734.626175043027                  ''      
    % 'P2'    NaT                     NaN           NaN               false      'O[15O]'    09-Sep-2016 11:23:45    09-Sep-2016 11:34:52    NaN          NaN        21.98         3.7965       4.4618       0.6653            32.81426432084             619.00902301696                  'Plasma'

    % tracerAdmin       
    % this.tracerAdmin -> 7×4 table
    %              ADMINistrationTime_Hh_mm_ss    TrueAdmin_Time_Hh_mm_ss    dose_MCi    COMMENTS
    %              ___________________________    _______________________    ________    ________
    % C[15O]       09-Sep-2016 10:11:36           09-Sep-2016 10:09:19         21        NaN     
    % O[15O]       09-Sep-2016 10:27:24           09-Sep-2016 10:25:07         18        NaN     
    % H2[15O]      09-Sep-2016 10:43:04           09-Sep-2016 10:40:47       20.7        NaN     
    % C[15O]_1     09-Sep-2016 10:59:56           09-Sep-2016 10:57:39         15        NaN     
    % O[15O]_1     09-Sep-2016 11:28:31           09-Sep-2016 11:26:14         16        NaN     
    % H2[15O]_1    09-Sep-2016 11:43:35           09-Sep-2016 11:41:18       20.3        NaN     
    % [18F]DG      09-Sep-2016 12:03:00           09-Sep-2016 12:00:43        4.9        NaN      

    % clocks        
    % this.clocks -> 6×1 table
    %                     TimeOffsetWrtNTS____s
    %                     _____________________
    % mMR console            7                 
    % PMOD workstation       0                 
    % mMR PEVCO lab       -118                 
    % CT radiation lab       0                 
    % hand timers          137                 
    % 2nd PEVCO lab          0  

    % doseCalibrator
    % this.cyclotron -> 3×8 table
    %                           time_Hh_mm_ss             dose_MCi        CYCLOTRONLOTID       CYCLOTRONTIME        CyclotronActivity_MCi_ML    CyclotronVolume_ML    ExpectedDose_MCi            COMMENTS        
    %                       ______________________    ________________    ______________    ____________________    ________________________    __________________    ________________    ________________________
    % syringe + cap dose    '09-Sep-2016 12:33:30'                3.02    'F1-090916'       09-Sep-2016 06:12:00    69.2                        0.4                   2.51974444007394    ''                      
    % residual dose         '09-Sep-2016 12:33:30'                 0.5    ''                NaT                      NaN                        NaN                                NaN    'guessing residual dose'
    % net dose              ''                        2.48889898928836    ''                NaT                      NaN                        NaN                                NaN    ''                      

    % phantom
    % this.phantom -> 1×5 table
    % PHANTOM    OriginalVolume_ML    NetVolume_phantom_Dose__ML    DECAYCorrSpecificActivity_KBq_mL    COMMENTS
    % _______    _________________    __________________________    ________________________________    ________
    % NaN        500                  500                           136.810825779928                    NaN     

    % wellCounter
    % this.capracCalibration -> 3×19 table
    % WELLCOUNTER       Time_Hh_mm_ss        COUNTS_Cpm    countsS_E__Cpm    ENTERED     TRACER       TIMEDRAWN_Hh_mm_ss     TIMECOUNTED_Hh_mm_ss    W_01_Kcpm    CF_Kdpm    Ge_68_Kdpm    MASSDRY_G    MASSWET_G    MassSample_G    apertureCorrGe_68_Kdpm_G    DECAY_APERTURECORRGe_68_Kdpm_G    DECAYCorrSpecificActivity_KBq_mL    S_A__S_A_OFDOSECALIB_        COMMENTS    
    % ___________    ____________________    __________    ______________    _______    _________    ____________________    ____________________    _________    _______    __________    _________    _________    ____________    ________________________    ______________________________    ________________________________    _____________________    ________________
    % NaN            09-Sep-2016 12:45:45    266           NaN               true       '[18F]DG'    09-Sep-2016 12:31:13    09-Sep-2016 12:43:09    NaN          NaN        2977          3.8113       5.8967       2.0854          1928.97650059354            1504.106976004                    25.0684496000667                    0.183234400181105        'failed mixing?'
    % NaN            NaT                     NaN           NaN               false      '[18F]DG'    NaT                     NaT                     NaN          NaN         NaN             NaN          NaN            0                       NaN                       NaN                                 NaN                                  NaN        ''              
    % NaN            NaT                     NaN           NaN               false      '[18F]DG'    NaT                     NaT                     NaN          NaN         NaN             NaN          NaN            0                       NaN                       NaN                                 NaN                                  NaN        ''              

    % twilite
    % this.twilite -> 3×11 table
    %                            TWILITE                               CathPlace_mentTime_Hh_mm_ss    EnclosedCatheterLength_Cm    VISIBLEVolume_ML     TwiliteBaseline_CoincidentCps    TwiliteLoaded_CoincidentCps    SpecificCountRate_Kcps_mL    SpecificACtivity_KBq_mL    DECAYCORRSpecificActivity_KBq_mL    S_A__S_A_OFDOSECALIB_    COMMENTS
    % _____________________________________________________________    ___________________________    _________________________    _________________    _____________________________    ___________________________    _________________________    _______________________    ________________________________    _____________________    ________
    % 'Medex REF 536035, 152.4 cm  Ext. W/M/FLL Clamp APV = 1.1 mL'    08-Sep-2012 13:22:33           20                           0.144356955380577    91.3                             148.3                          0.394854545454546            116.60378508               116.60378508                        0.852299402589435        NaN     
    % 'Medex'                                                          08-Sep-2012 13:22:33           20                           0.144356955380577     NaN                               NaN                                          0                       0                        NaN                                      NaN        NaN     
    % 'Medex'                                                          08-Sep-2012 13:22:33           20                           0.144356955380577     NaN                               NaN                                          0                       0                        NaN                                      NaN        NaN     

    % mMR
    % this.mMR -> 3×9 table
    %         scanStartTime_Hh_mm_ss    ROIMean_KBq_mL    ROIS_d__KBq_mL    ROIVol_Cm3    ROIPIXELS    ROIMin_KBq_mL    ROIMax_KBq_mL    DECAYCorrSpecificActivity_KBq_mL    S_A__S_A_OFDOSECALIB_
    %         ______________________    ______________    ______________    __________    _________    _____________    _____________    ________________________________    _____________________
    % ROI1    09-Sep-2016 13:22:40      103.61            22.81             518           129746       41.14            134.8            103.533699821761                    0.756765403845334    
    % ROI2    NaT                          NaN              NaN             NaN              NaN         NaN              NaN                           0                                    0    
    % ROI3    NaT                          NaN              NaN             NaN              NaN         NaN              NaN                           0                                    0    

	%  $Revision$
 	%  was created 21-Oct-2018 23:44:15 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    properties         
        tableNames = { ...
            'capracHeader' ...
            'countsFdg' 'countsOcOo' 'tracerAdmin' ...
            'clocks' 'doseCalibrator' 'phantom' ...
            'wellCounter' 'twilite' 'mMR' ...
            'pmod'}
        sheetNames = { ...
            'Radiation Counts Log - Table 1' ...
            'Radiation Counts Log - Runs' 'Radiation Counts Log - Runs-1' 'Radiation Counts Log - Runs-2' ...
            'Twilite Calibration - Runs' 'Twilite Calibration - Runs-2' 'Twilite Calibration - Runs-2-1' ...
            'Twilite Calibration - Runs-2-2' 'Twilite Calibration - Runs-2-1-' 'Twilite Calibration - Runs-2-11' ...
            'Twilite Calibration - Runs-2-12'}
        hasRowNames = [ ...
            0 ...
            1 1 1 ...
            1 1 0 ...
            1 1 1 ...
            1] % left-most column in sheet
        datetimeTypes = { ...
            'exceldatenum' ...
            'exceldatenum' 'exceldatenum' 'exceldatenum' ...
            'exceldatenum' 'exceldatenum' 'exceldatenum' ...
            'exceldatenum' 'exceldatenum' 'exceldatenum' ...
            'exceldatenum'}
    end
    
    methods (Static)
        function fqfn = date2filename(aDate)
            %% DATE2FILENAME looks in env var CCIR_RAD_MEASUREMENTS_DIR for a measurements file matching the 
            %  requested datetime.
            %  @param aDate is datetime.
            
            assert(isdatetime(aDate));
            CRMD = getenv('CCIR_RAD_MEASUREMENTS_DIR');
            assert(isdir(CRMD), ...
                'mlpet:ValueError', ...
                'environment variable CCIR_RAD_MEASUREMENTS_DIR->%s must be a dir', CRMD);
            mon = lower(month(aDate, 'shortname'));
            fqfn = fullfile( ...
                getenv('CCIR_RAD_MEASUREMENTS_DIR'), ...
                sprintf('CCIRRadMeasurements %i%s%i.xlsx', aDate.Year, mon{1}, aDate.Day));
            assert(lexist(fqfn, 'file'), ...
                'mlpet:FileNotFoundError', ...
                'file %s must be accessible', fqfn)
        end
    end

	methods 
        function cath = catheterInfo(this)
            switch (this.twilite{1,1})
                case 'Medex REF 536035, 152.4 cm  Ext. W/M/FLL Clamp APV = 1.1 mL'
                    cath.vendor = 'Medex';
                    cath.ref = '536035';
                    cath.primingVolume = 1.1;
                    cath.enclosedLength = 20;
                    cath.length = 152.4; % trimmed to ~40 cm
                case 'Braun ref V5424, 48 cm len, 0.642 mL priming vol'
                    cath.vendor = 'Braun';
                    cath.ref = 'V5424';
                    cath.primingVolume = 0.642;
                    cath.enclosedLength = 20;
                    cath.length = 48;
                otherwise
                    error('mlpet:ValueError', 'CCIRRadMeasurements.catheterInfo');
            end
        end
        function dt   = datetime(this)
            %% DATETIME for all the measurements as determined from internal mlpet.Session or readtables.
            
            dt1 = datetime(this.session_);
            dt  = dt1;
            return
            
            dt2 = this.tracerAdminDatetime('earliest', true);
            if (~isnat(dt1) && ~isnat(dt2))
                assert(this.equivDates(dt1, dt2), 'mlpet:ValueError', 'internally inconsistent datetime');
                dt = dt1;
            end
            if (~isnat(dt1))
                dt = dt1;
            end
            if (~isnat(dt2))
                dt = dt2;
            end
        end
        function dt   = tracerAdminDatetime(this, varargin)
            %% TRACERADMINDATETIME is the datetime recorded in table tracerAdmin for a tracer and snumber.
            %  @param tracer is char.
            %  @param snumber is numeric.
            %  @param earliest is logical; default := true.
            
            ip = inputParser;
            addParameter(ip, 'datetime', NaT, @isdatetime);
            addParameter(ip, 'earliest', false, @islogical);
            addParameter(ip, 'tracer', '', @ischar);
            addParameter(ip, 'snumber', 1, @isnumeric);
            parse(ip, varargin{:});
            
            if (~isnat(ip.Results.datetime))
                dt = this.tracerAdmin.TrueAdmin_Time_Hh_mm_ss( ...
                     this.tracerAdmin.TrueAdmin_Time_Hh_mm_ss == ip.Results.datetime);
                return
            end
            if (ip.Results.earliest)
                dt = min(this.tracerAdmin.TrueAdmin_Time_Hh_mm_ss);
                return
            end
            dt = this.tracerAdmin.TrueAdmin_Time_Hh_mm_ss( ...
                 this.tracerCode(ip.Results.tracer, ip.Results.snumber));
            dt.TimeZone = this.PREFERRED_TIMEZONE;
        end
        function wcrs = wellCounterRefSrc(this, isotope)
            %% WELLCOUNTERREFSRC
            %  @param isotope is char.
            %  @return table(TRACER, TIMECOUNTED_Hh_mm_ss, CF_Kdpm, Ge_68_Kdpm).
            
            assert(lstrfind(isotope, this.REFERENCE_SOURCES));
            wc   = this.wellCounter;
            sel  = cellfun(@(x) strcmpi(x, isotope), wc.TRACER);
            wcrs = table(wc.TRACER{sel}, wc.TIMECOUNTED_Hh_mm_ss(sel), wc.CF_Kdpm(sel), wc.Ge_68_Kdpm(sel), ...
                'VariableNames', {'TRACER' 'TIMECOUNTED_Hh_mm_ss' 'CF_Kdpm' 'Ge_68_Kdpm'});
        end
    end
    
    %% PROTECTED
    
    methods (Access = protected)	
 		function this = CCIRRadMeasurements(varargin)
 			%% CCIRRADMEASUREMENTS reads tables from measurement files specified by env var CCIR_RAD_MEASUREMENTS_DIR
            %  and a datetime for the measurements.
            %  @param session is mlraichle.Session; default := trivial ctor.
            %  @param alwaysUseReferenceDate is logical; default := true.
 			
 			this = this@mldata.Xlsx(varargin{:});
            ip = inputParser;
            addParameter(ip, 'session', mlraichle.Session, @(x) isa(x, 'mlraichle.Session'));
            addParameter(ip, 'alwaysUseSessionDate', true, @islogical);
            parse(ip, varargin{:});
            this.session_ = ip.Results.session;
            this.alwaysUseSessionDate_ = ip.Results.alwaysUseSessionDate;
            
            if (isnat(datetime(this.session_)))
                warning('mlraichle:ValueWarning', ...
                    'ctor:  instance of CCIRRadMeasurements contains neither datetime nor tables');
                return
            end
            this = this.readtables( ...
                this.date2filename(datetime(this.session_)));
 		end
        function this = readtables(this, fqfn)
            fprintf('mlpet.CCIRRadMeasurements.readtables:  reading %s\n', fqfn);
            for t = 1:length(this.tableNames)
                this.addgetprop( ...
                    this.tableNames{t}, ...
                    this.readtable(fqfn, this.sheetNames{t}, this.hasRowNames(t), this.datetimeTypes{t}));
            end
            
            this.clocks = this.convertClocks2sec(this.clocks); % needed for dependencies
            %this.capracHeader
            this.countsFdg = this.correctDates2(this.countsFdg);
            this.countsOcOo = this.correctDates2(this.countsOcOo);
            this.tracerAdmin = this.correctDates2(this.tracerAdmin); % provides datetime(this)
            this.doseCalibrator = this.correctDates2(this.doseCalibrator);
            %this.phantom
            this.wellCounter = this.correctDates2(this.wellCounter);
            %this.twilite
            this.mMR = this.correctDates2(this.mMR);
        end
        function tbl  = readtable(this, fqfn, sheet, hasRowNames, datetimeType)
            %% READTABLE
            %  @param fqfn is char.
            %  @param sheet is char.
            %  @param hasRowNames is logical.
            %  @param datetimeTypes is char value for native readtable param DatetimeType.
            
            warning('off', 'MATLAB:table:ModifiedVarnames');   
            warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');  
            warning('off', 'MATLAB:table:ModifiedDimnames');
            
            this.fqfn = fqfn;
            tbl = readtable( ...
                fqfn, ...
                'Sheet', sheet, ...
                'FileType', 'spreadsheet', ...
                'ReadVariableNames', true, 'ReadRowNames', hasRowNames, ...
                'DatetimeType', datetimeType);
            
            warning('on', 'MATLAB:table:ModifiedVarnames');
            warning('on', 'MATLAB:table:ModifiedAndSavedVarnames');
            warning('on', 'MATLAB:table:ModifiedDimnames');
        end          
    end 
    
    %% PROTECTED
    
    methods (Access = protected)        
        function tbl  = correctDates2(this, tbl, varargin)
            %% CORRECTDATES2 overrides mlio.AbstractXlsxIO
            
            vars = tbl.Properties.VariableNames;
            for v = 1:length(vars)
                col = tbl.(vars{v});
                if (this.hasTimings(vars{v}))
                    if (any(isnumeric(col)))                        
                        lrows = logical(~isnan(col) & ~isempty(col));
                        dt_   = this.datetimeConvertFromExcel2(tbl{lrows,v});
                        col   = NaT(size(col));
                        col.TimeZone = dt_.TimeZone;
                        col(lrows) = dt_;
                        if (~this.isTrueTiming(vars{v}))
                            col(lrows) = col(lrows) - this.adjustClock4(vars{v}, varargin{:});
                        end
                    end
                    if (any(isdatetime(col)))
                        col.TimeZone = this.PREFERRED_TIMEZONE;
                        lrows = logical(~isnat(col));
                        col(lrows) = this.correctDateToSessionDate(col(lrows));
                        if (~this.isTrueTiming(vars{v}))
                            col(lrows) = col(lrows) - this.adjustClock4(vars{v}, varargin{:});
                        end
                    end
                end
                tbl.(vars{v}) = col;
            end
        end 
    end
    
    %% PRIVATE
    
    properties (Access = private)
        alwaysUseSessionDate_
        session_        
    end
    
    methods (Access = private) 
        function dur  = adjustClock4(this, varargin)
            ip = inputParser;
            addRequired(ip, 'varName', @ischar);
            addOptional(ip, 'wallClockName', '', @ischar);
            parse(ip, varargin{:});            
            vN = lower(ip.Results.varName);
            wCN = ip.Results.wallClockName;
            
            if (ismember('TimeOffsetWrtNTS____s', this.clocks.Properties.VariableNames))
                if (~isempty(wCN))
                    dur = seconds(this.clocks.TimeOffsetWrtNTS____s(wCN));
                    return
                end
                if (lstrfind(vN, 'drawn') || lstrfind(vN, 'administrationtime'))
                    dur = seconds(this.clocks.TimeOffsetWrtNTS____s('hand timers')); 
                    return
                end
            elseif (ismember('TIMEOFFSETWRTNTS____S', this.clocks.Properties.VariableNames))
                if (~isempty(wCN))
                    dur = seconds(this.clocks.TIMEOFFSETWRTNTS____S(wCN));
                    return
                end
                if (lstrfind(vN, 'drawn'))
                    dur = seconds(this.clocks.TIMEOFFSETWRTNTS____S('hand timers')); 
                    return
                end
            else
                error('mlpet:ValueError', 'CCIRRadMeasurements.convertClocks2sec');
            end
            dur = seconds(0);
        end
        function dt   = correctDateToSessionDate(this, dt)
            if (~this.alwaysUseSessionDate_)
                return
            end            
            if (~isdatetime(dt))
                dt = this.datetime(dt);
            end
            sessdt      = datetime(this);
            dt.Year     = sessdt.Year;
            dt.Month    = sessdt.Month;
            dt.Day      = sessdt.Day;
            dt.TimeZone = sessdt.TimeZone;
        end
        function c    = convertClocks2sec(this, c)
            if (ismember('TimeOffsetWrtNTS____s', c.Properties.VariableNames))
                for ic = 1:length(c.TimeOffsetWrtNTS____s)
                    c.TimeOffsetWrtNTS____s(ic) = this.excelNum2sec(c.TimeOffsetWrtNTS____s(ic));
                end
            elseif (ismember('TIMEOFFSETWRTNTS____S', c.Properties.VariableNames))
                for ic = 1:length(c.TIMEOFFSETWRTNTS____S)
                    c.TIMEOFFSETWRTNTS____S(ic) = this.excelNum2sec(c.TIMEOFFSETWRTNTS____S(ic));
                end
            else
                error('mlpet:ValueError', 'CCIRRadMeasurements.convertClocks2sec');
            end
        end
        function tf   = hasTimings(~, var)
            tf = lstrfind(lower(var), 'time') | ...
                 lstrfind(lower(var), 'hh_mm_ss') | ...
                 lstrfind(lower(var), 'hhmmss');
        end
        function tf   = isTrueTiming(~, var)
            tf = lstrfind(lower(var), 'true');
        end
        function tc   = tracerCode(~, tr, snumber)
            assert(ischar(tr));
            if (lstrfind(upper(tr), 'CS'))
                tc = '[137Cs]';
                return
            end
            assert(isnumeric(snumber));
            if (lstrfind(upper(tr), 'FDG') || ...
                strcmp(tr(1:2), '18') || ...
                strcmp(tr(1), '['))
                tc = '[18F]DG';
                return
            end
            if (lstrfind(upper(tr), 'GE'))
                tc = '[68Ge]';
                return
            end
            if (lstrfind(upper(tr), 'NA'))
                tc = '[22Na]';
                return
            end
            switch (upper(tr(1:2)))
                case 'CO'
                    tc = 'C[15O]';
                case 'OC'
                    tc = 'C[15O]';
                case 'OO'
                    tc = 'O[15O]';
                case 'HO'
                    tc = 'H2[15O]';
                otherwise
                    error('mlpet:ValueError', 'CCIRRadMeasurements.tracerCode');
            end
            if (snumber > 1)
                tc = sprintf('%s_%i', tc, snumber-1);
            end
        end
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

