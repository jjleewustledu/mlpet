classdef CCIRRadMeasurements < handle & mldata.Xlsx & mlpet.RadMeasurements
    %% CCIRRADMEASUREMENTS has dynamic properties named by this.tableNames.
    
    % capracHeader
    % this.capracHeader -> 4×4 table
    %     Var1             Var2                   Var3                   Var4
    % _____________    _____________    _________________________    ____________
    %
    % 'DATE:'          '41916'          'PROJECT ID:'                'CCIR_00754'
    % 'SUBJECT ID:'    'NP995-24 V1'    'PRINCIPLE INVESTIGATOR:'    'Arbelaez'
    % 'ISOTOPES:'      ''               'DOSES DELIVERED / mCi:'     '138.9'
    % 'COMMENTS:'      ''               'OPERATOR:'                  'JJL'
    
    % countsFdg
    % this.fdg -> 40×16 table
    %          Time_Hh_mm_ss        COUNTS_Cpm    countsS_E__Cpm    ENTERED     TRACER       TIMEDRAWN_Hh_mm_ss     TIMECOUNTED_Hh_mm_ss    W_01_Kcpm    CF_Kdpm     Ge_68_Kdpm    MASSDRY_G    MASSWET_G      MASSSAMPLE_G       apertureCorrGe_68_Kdpm_G    TRUEDECAY_APERTURECORRGe_68_Kdpm_G    COMMENTS
    %       ____________________    __________    ______________    _______    _________    ____________________    ____________________    _________    ________    __________    _________    _________    _________________    ________________________    __________________________________    ________
    %
    % 5     05-Oct-2018 16:08:01       200             14.1          true      '[18F]DG'    05-Oct-2018 14:26:48    05-Oct-2018 16:29:53      0.007        0.0207     -0.09514       3.841       4.5773                 0.7363        -0.12918749818931               -0.281348311829075              NaN
    % 6                      NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:26:52    05-Oct-2018 16:31:06       0.07         0.207      0.04757      3.8361       4.4571                  0.621       0.0758195958455315                0.166392146979404              NaN
    % 7                      NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:26:57    05-Oct-2018 16:32:16     -0.017      -0.05026     -0.03171      3.8356       4.5221                 0.6865      -0.0459628136917478               -0.101619245732655              NaN
    % 8                      NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:01    05-Oct-2018 16:34:49     -0.005      -0.01478     -0.01586      3.8379       4.5261                 0.6882      -0.0229353571410184              -0.0515275763162243              NaN
    % 9                      NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:06    05-Oct-2018 16:35:53      0.745         2.203        1.792      3.8339       4.4853                 0.6514         2.72926257166415                 6.17356861012121              NaN
    % 10                     NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:09    05-Oct-2018 16:13:31      88.83         262.6        198.1      3.7794       4.4246                 0.6452         304.459835848605                 597.933202809271              NaN
    % 11                     NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:13    05-Oct-2018 16:37:24      651.9          1927         1511      3.8272       4.4827                 0.6555         2287.65961939905                  5224.0929451511              NaN
    % 12                     NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:18    05-Oct-2018 16:39:22        889          2628         2093      3.8089       4.4226                 0.6137         3373.83831017725                 7800.75501445661              NaN
    % 13                     NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:22    05-Oct-2018 17:09:19        556          1644         1279      3.8416       4.3686                  0.527         2388.41478440257                 6672.36133296334              NaN
    % 14                     NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:26    05-Oct-2018 17:10:16        509          1505         1170      3.8234       4.5486      0.725200000000001         1611.23340955198                 4528.23970944984              NaN
    % 15                     NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:30    05-Oct-2018 17:11:11      284.2         840.2          642      3.7815       4.3371      0.555600000000001         1138.87093457769                 3219.27444240335              NaN
    % 16                     NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:34    05-Oct-2018 17:12:50      287.5           850        657.5      3.7294       4.3428                 0.6134         1060.36130342402                 3028.57117496513              NaN
    % 17                     NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:38    05-Oct-2018 17:14:42      222.6         658.2        504.8      3.7991       4.3367                 0.5376         924.571618156552                 2672.06456583468              NaN
    % 18                     NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:42    05-Oct-2018 17:15:53      154.8         457.8        349.1      3.8384       4.2698                 0.4314         793.665389349395                 2311.00712832259              NaN
    % 19                     NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:45    05-Oct-2018 17:16:56      214.9         635.3        481.9      3.7776       4.5322      0.754599999999999         639.696689994506                 1875.15911895423              NaN
    % 20                     NaT       NaN              NaN          false     '[18F]DG'    05-Oct-2018 14:27:50    05-Oct-2018 16:14:59      197.2         583.1        445.1      3.8075       4.3445                  0.537         816.113155081437                 1617.67707088754              NaN
    
    % countsOcOo
    % this.oo -> 8×16 table
    %          Time_Hh_mm_ss        COUNTS_Cpm    countsS_E__Cpm    ENTERED     TRACER      TIMEDRAWN_Hh_mm_ss     TIMECOUNTED_Hh_mm_ss    W_01_Kcpm    CF_Kdpm    Ge_68_Kdpm    MASSDRY_G    MASSWET_G      MassSample_G       apertureCorrGe_68_Kdpm_G    DECAY_APERTURECORRGe_68_Kdpm_G    COMMENTS
    %       ____________________    __________    ______________    _______    ________    ____________________    ____________________    _________    _______    __________    _________    _________    _________________    ________________________    ______________________________    ________
    %
    % 1     05-Oct-2018 10:36:49       188             13.7          true      'C[15O]'    05-Oct-2018 11:55:51    05-Oct-2018 11:56:57      864.4         NaN         NaN        3.8615       5.2036                 1.3421                       0                                0         ''
    % P1                     NaT       NaN              NaN          false     'C[15O]'                     NaT                     NaT      0.222         NaN         NaN        3.8232       4.4086                 0.5854                       0                              NaN         'Plasma'
    % 2     05-Oct-2018 12:02:36       186             13.6          true      'O[15O]'    05-Oct-2018 12:43:07    05-Oct-2018 12:44:27      251.7       744.3       543.9         3.789       5.1649                 1.3759        440.246681839941             9.96636183980027e-06         ''
    % P2    05-Oct-2018 12:49:50       NaN              NaN          false     'O[15O]'                     NaT    05-Oct-2018 12:46:51      30.83       91.16       66.67        3.8263       4.5374                 0.7111        93.5053785723642             4.79722617332878e-06         'Plasma'
    % 3                      NaT       NaN              NaN          false     'C[15O]'    05-Oct-2018 13:20:34    05-Oct-2018 13:21:30       1130        3342        2542        3.7576       5.1112                 1.3536        2080.92902993269                 14.0788155046763         ''
    % P3                     NaT       NaN              NaN          false     'C[15O]'                     NaT    05-Oct-2018 13:22:51      1.604       4.724       3.774        3.8063       4.5799      0.773600000000001        4.89675891469724               0.0524073739308756         'Plasma'
    % 4                      NaT       NaN              NaN          false     'O[15O]'    05-Oct-2018 13:38:24    05-Oct-2018 13:39:24      299.1       884.3       643.6         3.841       4.8352                 0.9942        669.354408632683                 1989.32744662306         ''
    % P4                     NaT       NaN              NaN          false     'O[15O]'                     NaT    05-Oct-2018 13:40:51      47.16       139.4       97.93        3.8142       4.4457                 0.6315        153.610739365271                 749.985717973356         'Plasma'
    
    % tracerAdmin
    % this.tracerAdmin -> 7×4 table
    %              ADMINistrationTime_Hh_mm_ss    TrueAdmin_Time_Hh_mm_ss    dose_MCi     COMMENTS
    %              ___________________________    _______________________    ________    ___________
    %
    % C[15O]          05-Oct-2018 11:51:10         05-Oct-2018 11:51:12          17      ''
    % O[15O]          05-Oct-2018 12:40:28         05-Oct-2018 12:40:30          23      '2 breaths'
    % H2[15O]         05-Oct-2018 12:58:27         05-Oct-2018 12:58:29        26.4      ''
    % C[15O]_1        05-Oct-2018 13:16:21         05-Oct-2018 13:16:23          22      ''
    % O[15O]_1        05-Oct-2018 13:36:10         05-Oct-2018 13:36:12          19      ''
    % H2[15O]_1       05-Oct-2018 14:09:21         05-Oct-2018 14:09:23        26.3      ''
    % [18F]DG         05-Oct-2018 14:26:36         05-Oct-2018 14:26:38         5.2      ''
    
    % clocks
    % this.clocks -> 6×1 table
    %                     TimeOffsetWrtNTS____s
    %                     _____________________
    %
    % mMR console                  -72
    % PMOD workstation               0
    % mMR PEVCO lab                  0
    % CT radiation lab               0
    % hand timers                    2
    % 2nd PEVCO lab                  0
    
    % doseCalibrator
    % this.doseCalibrator -> 3×8 table
    %                       time_Hh_mm_ss        dose_MCi        CYCLOTRONLOTID    CYCLOTRONTIME    CyclotronActivity_MCi_ML    CyclotronVolume_ML    ExpectedDose_MCi         COMMENTS
    %                       _____________    ________________    ______________    _____________    ________________________    __________________    ________________    ___________________
    %
    % syringe + cap dose    '41916.6114'                 1.72         NaN               NaT                   NaN                      NaN                  NaN           'sum of 3 syringes'
    % residual dose         '41916.6428'                0.155         NaN               NaT                   NaN                      NaN                  NaN           ''
    % net dose              ''               1.51384029354954         NaN               NaT                   NaN                      NaN                  NaN           ''
    
    % phantom
    % this.phantom -> 1×5 table
    % PHANTOM    OriginalVolume_ML    NetVolume_phantom_Dose__ML    DECAYCorrSpecificActivity_KBq_mL    COMMENTS
    % _______    _________________    __________________________    ________________________________    ________
    %
    %   NaN             690                      690                        73.9990112792118              NaN
    
    % wellCounter
    % this.wellCounter -> 15×18 table
    %            Time_Hh_mm_ss        COUNTS_Cpm    countsS_E__Cpm    ENTERED     TRACER      TIMEDRAWN_Hh_mm_ss    TIMECOUNTED_Hh_mm_ss    W_01_Kcpm    CF_Kdpm    Ge_68_Kdpm    MASSDRY_G    MASSWET_G      MassSample_G       apertureCorrGe_68_Kdpm_G    DECAY_APERTURECORRGe_68_Kdpm_G    DECAYCorrSpecificActivity_KBq_mL    S_A__S_A_OFDOSECALIB_           COMMENTS
    %         ____________________    __________    ______________    _______    _________    __________________    ____________________    _________    _______    __________    _________    _________    _________________    ________________________    ______________________________    ________________________________    _____________________    ______________________
    %
    % GE                       NaT       NaN              NaN          false     '[68Ge]'            NaT            05-Oct-2018 10:42:10      46.47       137.4       97.93           NaN          NaN                      0                     NaN                            NaN                                NaN                            NaN      '60 s counting [68Ge]'
    % NA                       NaT       NaN              NaN          false     '[22Na]'            NaT            05-Oct-2018 10:47:31      11.28       33.34       19.17           NaN          NaN                      0                     NaN                            NaN                                NaN                            NaN      '60 s counting [22Na]'
    % CS                       NaT       NaN              NaN          false     '[137Cs]'           NaT            05-Oct-2018 10:53:25      239.2       707.1         294           NaN          NaN                      0                     NaN                            NaN                                NaN                            NaN      '60 s [137Cs]'
    % C1                       NaT       NaN              NaN          false     '[18F]DG'           NaT            05-Oct-2018 15:28:01       1428        4223        3445        3.7575       4.6976      0.940100000000001        3757.89954413136               3478.76971391443                   60.8784699935024              0.822693019016117      ''
    % C2                       NaT       NaN              NaN          false     '[18F]DG'           NaT            05-Oct-2018 15:29:50       1487        4396        3581        3.7746       4.7946                   1.02        3645.18455949683               3413.20106961463                   59.7310187182561              0.807186713520808      ''
    % C3                       NaT       NaN              NaN          false     '[18F]DG'           NaT            05-Oct-2018 15:31:14       1413        4178        3384        3.8075       4.7977                 0.9902        3531.40291678455               3336.11613151312                   58.3820323014796              0.788956923778259      ''
    
    % twilite
    % this.twilite -> 3×10 table
    %                                                     CathPlace_mentTime_Hh_mm_ss    EnclosedCatheterLength_Cm    VISIBLEVolume_ML    TwiliteBaseline_CoincidentCps    TwiliteLoaded_CoincidentCps    SpecificCountRate_Kcps_mL    SpecificACtivity_KBq_mL    DECAYCORRSpecificActivity_KBq_mL    S_A__S_A_OFDOSECALIB_    COMMENTS
    %                                                     ___________________________    _________________________    ________________    _____________________________    ___________________________    _________________________    _______________________    ________________________________    _____________________    ________
    %
    % Braun ref V5424, 48 cm len, 0.642 mL priming vol         40454.6529513889                     20                     0.2675                      84                              316                    0.867289719626168            70.036073271028                 70.036073271028              0.946446068134197        NaN
    % Braun                                                    40454.6529513889                     20                     0.2675                      84                              316                    0.867289719626168            70.036073271028                70.0213334612791              0.946246878854582        NaN
    % Braun_1                                                  40454.6529513889                     20                     0.2675                      84                              316                    0.867289719626168            70.036073271028                 70.036073271028              0.946446068134197        NaN
    
    % mMR
    % this.mMR -> 3×9 table
    %         scanStartTime_Hh_mm_ss    ROIMean_KBq_mL    ROIS_d__KBq_mL    ROIArea_Cm2    ROIPIXELS    ROIMin_KBq_mL    ROIMax_KBq_mL    DECAYCorrSpecificActivity_KBq_mL    S_A__S_A_OFDOSECALIB_
    %         ______________________    ______________    ______________    ___________    _________    _____________    _____________    ________________________________    _____________________
    %
    % ROI1     05-Oct-2018 15:39:03         54.881            3.1985            49.1         1204          45.063            66.72                     54.881                   0.741645044322605
    % ROI2     05-Oct-2018 15:39:03        54.9284             3.245            48.9         1181          46.774           66.393                    54.9284                   0.742285593421581
    % ROI3     05-Oct-2018 15:39:03        55.7337            3.7927           56.45         1398          42.257           70.529                    55.7337                   0.753168171257135
    
    % pmod
    % this.pmod -> 1×5 table
    %                       TwiliteSpecificActivity_CoincidentKcps_mL    mMRSPECIFICActivity_KBq_mL    REPORTEDPMODFACTOR    MAGICPMODFACTOR    COMMENTS
    %                       _________________________________________    __________________________    __________________    _______________    ________
    %
    % Calibration Window                 70.036073271028                      55.1810333333333                0.24               336.47           NaN
    
    % fromPamStone
    % this.fromPamStone -> 12x1 table
    %                        Var1
    %                   _______________
    %
    % Row1              {'measurement'}
    % Hct               {'39.8'       }
    % glc Baseline      {'102'        }
    % glc OC1           {'113'        }
    % glc OO1           {'112'        }
    % glc HO1           {'107'        }
    % glc OC2           {'101'        }
    % glc OO2           {'97'         }
    % glc HO2           {'100'        }
    % glc FDG 0 min     {'104'        }
    % glc FDG 30 min    {'104'        }
    % glc FDG 60 min    {'101'        }
    
    
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
            'pmod' ...
            'fromPamStone'}
        sheetNames = { ...
            'Radiation Counts Log - Table 1' ...
            'Radiation Counts Log - Runs' 'Radiation Counts Log - Runs-1' 'Radiation Counts Log - Runs-2' ...
            'Twilite Calibration - Runs' 'Twilite Calibration - Runs-2' 'Twilite Calibration - Runs-2-1' ...
            'Twilite Calibration - Runs-2-2' 'Twilite Calibration - Runs-2-1-' 'Twilite Calibration - Runs-2-11' ...
            'Twilite Calibration - Runs-2-12' ...
            'Laboratory - From Pam Stone'}
        hasVarNames = [ ...
            0 ...
            1 1 1 ...
            1 1 1 ...
            1 1 1 ...
            1 ...
            1] % top row in sheet
        hasRowNames = [ ...
            0 ...
            1 1 1 ...
            1 1 0 ...
            1 1 1 ...
            1 ...
            1] % left-most column in sheet
        datetimeTypes = { ...
            'exceldatenum' ...
            'exceldatenum' 'exceldatenum' 'exceldatenum' ...
            'exceldatenum' 'exceldatenum' 'exceldatenum' ...
            'exceldatenum' 'exceldatenum' 'exceldatenum' ...
            'exceldatenum' ...
            'exceldatenum'}
    end
    
    properties (Dependent)
        sessionData
    end
    
    methods (Static)
        function this = createFromDate(aDate, varargin)
            import mlpet.CCIRRadMeasurements.*;
            this = createFromFilename(date2filename(aDate), varargin{:});
        end
        function this = createFromFilename(fqfn, varargin)
            this = mlpet.CCIRRadMeasurements(varargin{:});
            this = this.readtables(fqfn);
        end
        function this = createFromSession(sesd, varargin)
            %  @param required sessionData is an mlpipeline.ISessionData.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired(ip, 'sesd', @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, sesd, varargin{:})
            ipr = ip.Results;            
            this = mlpet.CCIRRadMeasurements('session', ipr.sesd, varargin{:});
        end
        function fqfn = date2filename(aDate)
            %% DATE2FILENAME looks in env var CCIR_RAD_MEASUREMENTS_DIR for a measurements file matching the
            %  requested datetime.
            %  @param aDate is datetime.
            
            assert(isdatetime(aDate));
            CRMD = getenv('CCIR_RAD_MEASUREMENTS_DIR');
            assert(isfolder(CRMD), ...
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
        
        %% GET
        
        function g = get.sessionData(this)
            g = this.session_;
        end
        
        %%
        
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
        function tbl  = correctDates2(this, tbl, varargin)
            %% CORRECTDATES2 overrides mlio.AbstractXlsxIO
            
            vars = tbl.Properties.VariableNames;
            for v = 1:length(vars)
                col = tbl.(vars{v});
                if (this.hasTimings(vars{v}))
                    if (any(isnumeric(col)))
                        lrows = logical(~isnan(col) & ~isempty(col));
                        dt_   = this.datetimeConvertFromExcel(tbl{lrows,v});
                        col   = NaT(size(col));
                        col.TimeZone = dt_.TimeZone;
                        col(lrows) = dt_;
                    end
                    if (any(isdatetime(col)))
                        col.TimeZone = this.preferredTimeZone;
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
        function dt   = datetime(this)
            %% DATETIME for all the measurements as determined from internal mlpet.Session or readtables.
            
            dt1 = datetime(this.session_);
            dt2 = this.datetimeTracerAdmin('earliest', true);
            dt  = NaT;
            if ~isnat(dt1) && ~isnat(dt2)
                if ~this.equivDates(dt1, dt2)
                    warning('mlpet:ValueWarning', ...
                        'CCIRRadMeasurements.datetime().dt1->%s but dt2->%s; using dt1 for session', dt1, dt2)
                end
                dt = dt1;
                return
            end
            if ~isnat(dt1)
                dt = dt1;
            end
            if ~isnat(dt2)
                dt = dt2;
            end
            if isnat(dt)
                re = regexp(this.fileprefix, 'CCIRRadMeasurements (?<dt>\d{4}\w{3}\d+)', 'names');
                if ~isempty(re)
                    dt = datetime(re.dt, 'InputFormat', 'yyyyMMMdd');
                end
            end
            if isempty(dt.TimeZone)
                dt.TimeZone = this.preferredTimeZone;
            end
        end
        function trac = datetime2tracer(this, dt)
            assert(isdatetime(dt));
            trac = this.tracerAdmin.Properties.RowNames( ...
                abs(this.tracerAdmin.TrueAdmin_Time_Hh_mm_ss - dt) < minutes(10));
            trac = trac{1};
            trac = strrep(trac, '[15', '');
            trac = strrep(trac, '[18', '');
            trac = strrep(trac, ']', '');
            trac = strrep(trac, '_1', '');
        end
        function iso  = datetime2isotope(this, dt)
            trac = this.datetime2tracer(dt);
            switch upper(trac)
                case {'CO' 'OO' 'HO'}
                    iso = '15O';
                case 'FDG'
                    iso = '18F';
                otherwise
                    error('mlpet:NotImplementedError', 'CCIRRadMeasurements.datetime2isotope for tracer %s', trac)
            end
        end
        function dt   = datetimeCapracHeader(this)
            assert(strcmp(this.capracHeader{1,1}, 'DATE:'));
            dt = this.datetimeConvertFromExcel(str2double(this.capracHeader{1,2}));
        end
        function dt   = datetimeDoseCalibrator(this)
            dt = this.datetimeConvertFromExcel(str2double(this.doseCalibrator{'residual dose', 'time_Hh_mm_ss'})) - ...
                seconds(this.clocks{'2nd PEVCO lab', 'TimeOffsetWrtNTS____s'});
        end
        function dt   = datetimeSession(this)
            dt = datetime(this.session_);
        end
        function dt   = datetimeTracerAdmin(this, varargin)
            %% DATETIMETRACERADMIN is the datetime recorded in table tracerAdmin for a tracer and snumber.
            %  @param earliest is logical; default := false.
            %  @param tracer is char:  'fdg', 'oc', 'oo', 'ho', 'cal'.  'cal' specifies datetime of calibration mMR.
            %  @param snumber is numeric.
            
            ip = inputParser;
            addParameter(ip, 'earliest', false, @islogical);
            addParameter(ip, 'tracer', '', @ischar);
            addParameter(ip, 'snumber', 1, @isnumeric);
            parse(ip, varargin{:});
            
            if strncmpi(ip.Results.tracer, 'cal', 3)
                dt = this.mMR.scanStartTime_Hh_mm_ss('ROI1');
                return
            end
            trueAdminTime = this.tracerTrueAdminDatetime;
            if (ip.Results.earliest)
                dt = min(trueAdminTime);
                return
            end
            dt = trueAdminTime( ...
                strcmp( ...
                this.tracerAdmin.Properties.RowNames, ...
                this.tracerCode(ip.Results.tracer, ip.Results.snumber)));
        end
        function        disp(this)
            disp(this.clocks)
            disp(this.tracerAdmin)
            disp(this.countsFdg)
            disp(this.countsOcOo)
            disp(this.wellCounter)
            disp(this.twilite)
            disp(this.mMR)
        end
        function wcrs = wellCounterRefSrc(this, varargin)
            %% WELLCOUNTERREFSRC
            %  @param isotope is char, e.g., '[137Cs]', '[22Na]' or '[68Ge]'; default := '' induces a search for available isotopes.
            %  @return table(TRACER, TIMECOUNTED_Hh_mm_ss, CF_Kdpm, Ge_68_Kdpm).
            %  @return [] if no references sources are available.
            
            ip = inputParser;
            addOptional(ip, 'isotope', '', @ischar);
            parse(ip, varargin{:});
            
            % recursion
            if (isempty(ip.Results.isotope))
                wcrs = [];
                for irs = 1:length(this.REFERENCE_SOURCES)
                    tbl_ = this.wellCounterRefSrc(this.REFERENCE_SOURCES{irs});
                    if (~isempty(tbl_))
                        wcrs = [wcrs; tbl_]; %#ok<AGROW>
                    end
                end
                return
            end
            
            % base case
            assert(lstrfind(ip.Results.isotope, this.REFERENCE_SOURCES));
            wc   = this.wellCounter;
            sel  = cellfun(@(x) strcmpi(x, ip.Results.isotope), wc.TRACER);
            wcrs = table(wc.TRACER(sel), wc.TIMECOUNTED_Hh_mm_ss(sel), wc.CF_Kdpm(sel), wc.Ge_68_Kdpm(sel), ...
                'VariableNames', {'TRACER' 'TIMECOUNTED_Hh_mm_ss' 'CF_Kdpm' 'Ge_68_Kdpm' ''});
        end
        function wcrs = wellCounterRefSyringes(this, varargin)
            %% WELLCOUNTERREFSYRINGES
            %  @param isotope is char; default := '[18F]DG'.
            %  @return table(TRACER, TIMECOUNTED_Hh_mm_ss, CF_Kdpm, Ge_68_Kdpm, MASSSAMPLE_G).
            
            ip = inputParser;
            addOptional(ip, 'isotope', '[18F]DG', @ischar);
            parse(ip, varargin{:});
            
            wc   = this.wellCounter;
            sel  = cellfun(@(x) strcmpi(x, ip.Results.isotope), wc.TRACER);
            wcrs = table( ...
                wc.TRACER(sel), wc.TIMECOUNTED_Hh_mm_ss(sel), wc.CF_Kdpm(sel), wc.Ge_68_Kdpm(sel), wc.MASSSAMPLE_G(sel), ...
                'VariableNames', {'TRACER' 'TIMECOUNTED_Hh_mm_ss' 'CF_Kdpm' 'Ge_68_Kdpm' 'MASSSAMPLE_G'});
        end
    end
    
    %% PROTECTED
    
    methods (Access = protected)
        function this = CCIRRadMeasurements(varargin)
            %% CCIRRADMEASUREMENTS reads tables from measurement files specified by env var CCIR_RAD_MEASUREMENTS_DIR
            %  and a datetime for the measurements.
            %  @param session is mlpet.Session; default := trivial ctor.
            %  @param alwaysUseReferenceDate is logical; default := true.
            
            this = this@mldata.Xlsx(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'session', mlxnat.Session, @(x) isa(x, 'mlxnat.Session') || isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'alwaysUseSessionDate', true, @islogical);
            parse(ip, varargin{:});
            this.session_ = ip.Results.session;
            this.alwaysUseSessionDate_ = ip.Results.alwaysUseSessionDate;
            
            if (isnat(datetime(this.session_)))
                return
            end
            try
                fqfn = this.date2filename(datetime(this.session_));
                matfn = [myfileprefix(fqfn) '.mat'];
                if isfile(matfn)
                    load(matfn, 'this')
                    return
                end
                this = this.readtables(fqfn);
                save(matfn, 'this')
            catch ME
                handwarning(ME)
                this = [];
            end
        end
        function this = readtables(this, fqfn)
            fprintf('mlpet.CCIRRadMeasurements.readtables:  reading %s\n', fqfn);
            if ~verLessThan('matlab', '9.8')
                error('mlpet:RuntimeError', 'CCIRRadMeasurements.readtables does not support\n%s', ver('matlab'))
            end
            for t = 1:length(this.tableNames)
                try
                    this.addgetprop( ...
                        this.tableNames{t}, ...
                        this.readtable(fqfn, this.sheetNames{t}, this.hasVarNames(t), this.hasRowNames(t), this.datetimeTypes{t}));
                catch ME
                    handwarning(ME)
                end
            end
            
            this.clocks = this.convertClocks2sec(this.clocks); % needed for dependencies
            this.tracerAdmin = this.correctDates2(this.tracerAdmin); % provides datetime(this)
            %this.capracHeader
            this.countsFdg = this.correctDates2(this.countsFdg);
            this.countsOcOo = this.correctDates2(this.countsOcOo);
            %this.doseCalibrator
            %this.phantom
            this.wellCounter = this.correctDates2(this.wellCounter, 'CT radiation lab');
            this.twilite = this.correctDates2(this.twilite, 'PMOD workstation');
            this.mMR = this.correctDates2(this.mMR);
            %this.pmod
        end
        function tbl  = readtable(this, fqfn, sheet, hasVarNames, hasRowNames, datetimeType)
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
                'ReadVariableNames', hasVarNames, 'ReadRowNames', hasRowNames, ...
                'DatetimeType', datetimeType);
            
            warning('on', 'MATLAB:table:ModifiedVarnames');
            warning('on', 'MATLAB:table:ModifiedAndSavedVarnames');
            warning('on', 'MATLAB:table:ModifiedDimnames');
        end
    end
    
    %% PRIVATE
    
    properties (Access = private)
        alwaysUseSessionDate_
        session_
        tracerTrueAdminDatetime_
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
                if (lstrfind(vN, 'drawn') || lstrfind(vN, 'administrationtime'))
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
            if (isnat(sessdt))
                return
            end
            dt.Year     = sessdt.Year;
            dt.Month    = sessdt.Month;
            dt.Day      = sessdt.Day;
            dt.TimeZone = this.preferredTimeZone;
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
        function dt   = tracerTrueAdminDatetime(this)
            if (isempty(this.tracerTrueAdminDatetime_))
                this.tracerTrueAdminDatetime_ = ...
                    this.datetimeConvertFromExcel(this.tracerAdmin.ADMINistrationTime_Hh_mm_ss) - ...
                    seconds(this.clocks{'hand timers', 'TimeOffsetWrtNTS____s'});
            end
            dt = this.tracerTrueAdminDatetime_;
        end
    end
    
    %  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

