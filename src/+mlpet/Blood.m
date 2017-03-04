classdef Blood  
	%% BLOOD   

	%  Revision 3.0 ports BLOOD to Matlab and
 	%  was created 2015 Sep 17
 	%  by John J. Lee,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a).
    %  Legacy variables, function-names, other objects are used when reasonable 
    %  for readability.  Historical revisions kept granularity of function methods
    %  for each data point and this has been retained for now for interoperability 
    %  with other frameworks from Tom Videen and Thomas Yang.

    % Revision 2.1  2009/01/09  15:07:20  tom
    % changed prompt for SCANNER to include 962
    % Revision 2.0  2004/02/20  16:38:58  tom
    % Feb 2004
    % Revision 1.7  2001/06/06  17:59:32  tom
    % add ntypes 7-9 for steady-state and steady-inhalation oxygen methods
    % Revision 1.6  1995/05/10  16:13:20  tom
    % default count time differs for different scanners
    % Revision 1.5  1995/05/10  15:44:32  tom
    % prompts for scanner and uses different default times for 953 and 961
    % Revision 1.4  1994/01/03  20:32:04  tom
    % altered bldparam
    % Revision 1.3  1992/10/14  20:52:06  ty7777
    % Release version of blood.
    % Revision 1.2  1992/10/13  19:08:09  ty7777
    % blood working version.
    % Revision 1.1  1992/10/12  16:17:30  ty7777
    % Initial revision
    
    %  Program:      blood.f
    %  Author:       Tom O. Videen
    %  Date:         27-Oct-86
    %  Written for:  Creating and modifying blood curve files (.dta)
    %  Revision & Reorganization of NS8:METENTRY.FTN/191 11/20/85
    %             by Mark Mintun
    %  History:
    %     Revised 26-Feb-87 by TOV with following changes:
    %        1) Correction factors introduced for TB syringes;
    %        2) 5 decimal places for syringe weights (instead of 3);
    %     Revised 19-Aug-87 by TOV so that SAVE=FALSE really deletes the
    %        DTA file instead of saving one with 0 records.
    %     Revised 24-Aug-87 by TOV so that blood counts are always reprocessed
    %        upon reading a blood curve whenever an existing DTA file is read.
    %        Previously, counts were reprocessed only if a curve was altered
    %        or if the user requested reprocessing.
    %     Modified 14-Jan-88 by TOV so decay correction is computed by
    %        including the average decay during the well counting period.
    %        This is now always computed through a single subroutine BLDDECOR.
    %     Modified BLDPARM 02-May-88 by TOV to allow lower values of
    %        oxygen content to be entered (requested by DIA).
    %        Modified message in BLOOD.FTN indicating the beige caps are
    %        identical to blue syringe caps.
    %     Modified BLOOD.INC 06-Oct-88 by TOV changing halflife for no decay
    %        to 1.0E+9 and altering BLDDECOR for processing with no decay.
    %     Modified blood.inc 12-Oct-92 by Tom Yang moving all the data 
    %        declarations to blood.c and ported the program to the from 
    %        PE2 to the Sun Unix environment.
    %     Modified blood.inc 09-May-95 by TOV to add SCANNER.
    %% 
    
    properties (Constant)
        % Densities of whole blood and plasma taken from:
        % Herscovitch & Raichle (1985) J. Cereb Blood Flow Metabol, 5:65
        BLOODDEN = 1.05 % density of blood (g/ml)
        PLASMADN = 1.03
        
        SC1NEW =  1.026
        SC2NEW = -0.0522
        SC1TB  =  1.063
        SC2TB  = -0.300
        
        DEFTIME = 12 % default count time (sec)
        
        AVAILABLE_RUNTYPES = { ...
            'O-15 Oxygen Metabolism Study  (OO)       ' ...
            'O-15 Water Blood Flow Study   (HO)       ' ...
            'O-15 Blood Volume Study       (OC)       ' ...
            'C-11 Butanol Blood Flow Study (BU)       ' ...
            'F-18 Study                               ' ...
            'Misc. Study                              ' ...
            'O-15 Oxygen Steady-State Study           ' ...
            'O-15 Oxygen Steady-Inhalation Plasma     ' ...
            'O-15 Oxygen Steady-Inhalation Whole Blood' ...
            '1-[11C]-D-glucose                        '};
    end

	properties
        
        bloodData % mlpet.IBloodData, mlpet.Bloodxlsx preferred
        drawn
        counted
        tbSyringeUsed = false
        header = '' % header string
        miscIsotope = nan % for use with SCANTYPE == 6
        wellCounterDeadtimeCorrection = nan
                
        %% COMMON BLDIPARM
        
        SCANNER = 3 % scanner (1=other, 2=953b, 3=961)

        %% COMMON BLDRPARM

        SCANSTART = 0.00 % start time of scan in MIN.SEC
        OXYCONT = 0 % oxygen content
        HEMATOCRIT = 0
        
        % Halflives are in seconds with same number of significant figures as
        % given in the following source:
        % Lederer & Shirley, Table of Isotopes, 1978 (7th edition), John Wiley.      
        COUNTIME % seconds summed in well counter (usually 10 or 12)        
        CORCNTS % decay corrected counts/(ml*sec); corrected to time of injection
        TIMESECS % (200)
    end 
    
    properties (Dependent)
        NPOINTS % number of points in blood curve; number of syringes        
        DRYWEIGHT % dry weight of syringe
        WETWEIGHT % weight of syringe with blood sample
        TIMEDRAW % time blood sample was taken (MIN.SEC)
        TIMECNT % time blood sample was counted (MIN.SEC)
        COUNTS % counts per COUNTIME seconds from well counter        
        HALFLIFE % halflife in seconds of ISOTOPE          
        ISOTOPE % isotope (1-6)    
        NUCLIDE % string for radionuclide        
        RUNTYPE    
        SCANLENGTH % length of scan in MIN.SEC        
        SCANNUM % e.g., last numerical label of 'p1234ho1'
        SCANTYPE % type of scan (1-10); many other utility variables reference SCANTYPE; cf. AVAILABLE_RUNTYPES
        VARYTIME % boolean option for varying well count times    
        tracerSymbol
        scanSymbol % scan id (scan file name without p-number)
        dtaFilename
        
        %  Different syringes were used prior to 11/17/86
        %  The old syringes had WHITE caps and fit held samples
        %  in the well counter in a different position than the
        %  new syringes with BLUE caps, as well as containing a
        %  different volume.
        %
        %  Note: BEIGE caps (which appeared in April 1988) are identical
        %  to BLUE caps.
        %
        %  These correction factors convert corrected counts to
        %  those which would have been obtained with 0.5 gm in a
        %  3 cc syringe.        
        SC1 % factor SC1 corrects for the position
        SC2 % factor SC2 corrects for the volume
    end

    methods %% GET
        function np = get.NPOINTS(this)
            np = this.bloodData.nSyringes;
        end
        function x  = get.DRYWEIGHT(this)
            x = this.bloodData.dryWeight;
        end
        function x  = get.WETWEIGHT(this)
            x = this.bloodData.wetWeight;
        end
        function x  = get.TIMEDRAW(this)
            m = this.bloodData.drawnMin;
            s = this.bloodData.drawnSec;
            assert(all(m - floor(m) < eps), 'unexpected Blood.TIMEDRAW');
            assert(all(s < 60),             'unexpected Blood.TIMEDRAW');
            x = m + s/100;
        end
        function x  = get.TIMECNT(this)
            m = this.bloodData.countedMin;
            s = this.bloodData.countedSec;
            assert(all(m - floor(m) < eps), 'unexpected Blood.TIMECNT');
            assert(all(s < 60),             'unexpected Blood.TIMECNT');
            x = m + s/100;
        end
        function x  = get.COUNTS(this)
            x = this.bloodData.counts;
        end
        function hl = get.HALFLIFE(this)
            list = [122.2416 9.97*60 20.33424*60 67.719*60 109.77120*60 1.0e9]; % wikipedia.org, 2017
            hl = list(this.ISOTOPE);
        end
        function is = get.ISOTOPE(this) 
            switch (this.SCANTYPE)
                case 1
                    is = 1;
                case 2
                    is = 1;
                case 3
                    is = 1;
                case 4
                    is = 3;
                case 5
                    is = 5;
                case 6
                    is = this.miscIsotope;
                case 7
                    is = 1;
                case 8
                    is = 1;
                case 9
                    is = 1;
                case 10
                    is = 3;
                otherwise
                    error('mlpet:unexpectedParamValue', 'Blood.SCANTYPE -> %g', this.SCANTYPE);
            end            
        end
        function n  = get.NUCLIDE(this)
            list = { ...
                'O-15           ' ...
                'N-13           ' ...
                'C-11           ' ...
                'Ga-68          ' ...
                'F-18           ' ...
                'NONE (no decay)'};
            n = list{this.ISOTOPE};
        end
        function n  = get.RUNTYPE(this)
            n = this.AVAILABLE_RUNTYPES{this.SCANTYPE};
        end
        function sl = get.SCANLENGTH(this)
            sl = this.bloodData.drawnMin(this.NPOINTS) + ...
                 this.bloodData.drawnSec(this.NPOINTS)/100;
        end
        function sn = get.SCANNUM(this)
            sn = this.bloodData.scanIndex;
        end
        function st = get.SCANTYPE(this)
            st = this.bloodData.scanType;
        end
        function tf = get.VARYTIME(this)
            tf = ~isempty(this.bloodData.variableCountTime);
        end
        function ts = get.tracerSymbol(this)
             list = {'oo' 'ho' 'oc' 'bu' 'sp' 'xx' 'oo' 'oo' 'oo' 'gluc'};
             ts = list{this.SCANTYPE};
        end
        function ss = get.scanSymbol(this)
            ss = sprintf('%s%i', this.tracerSymbol, this.SCANNUM);
        end
        function fn = get.dtaFilename(this)
            fn = sprintf('%s%s%i.dta', this.bloodData.pNumber, this.tracerSymbol, this.SCANNUM);
        end
        function sc = get.SC1(this)
            if (this.tbSyringeUsed)
                sc = this.SC1TB;
            else
                sc = this.SC1NEW;
            end
        end
        function sc = get.SC2(this)
            if (this.tbSyringeUsed)
                sc = this.SC2TB;
            else
                sc = this.SC2NEW;
            end
        end
    end
    
    methods (Static)
        function dtaObj = xlsx2dta(xlsxFn, sheetLbl, recFn, dtaFn)
            import mlpet.*;
            bldXlsx = Bloodxlsx(xlsxFn, sheetLbl);
            rec     = mlfourd.Rec.load(recFn);
            bldXlsx.scanDate = rec.scanDate;
            bldObj  = Blood(bldXlsx);
            dtaObj  = DTA.importBlood(bldObj);
            dtaObj.saveas(dtaFn);
        end
    end
    
	methods 
        
        %% BLOOD
        %
        %  Intent:
        %     This program is used for entering blood curve data from PET scans.
        %
        %     The program computes the counts per second for each blood sample
        %     corrected for decay from the time of sampling, the volume of the
        %     sample used in the well counter, and the position of the sample
        %     in the well counter.
        %     The user enters syringe dry & wet weights, times drawn & counted,
        %     and the counts per n seconds, as well as pertinent data concerning
        %     the PET scan.
        %     The program is intended for creating .DTA files (used by METEVAL)
        %     but may be used to display corrected counts without saving values.
        %     See mlpet.DTA for .DTA file structure.
        %
        %  Uses BLOOD Subroutines:
        %     BLDNEW   - create a new DTA file
        
        function this = Blood(bData)
            assert(isa(bData, 'mlpet.IBloodData'));
            this.bloodData = bData;            
            this.header = sprintf('@01@ %s %s %s %s %s', ...
                bData.pNumber, bData.scanDate, this.scanSymbol, datestr(now, 'mm/dd/yyyy'), getenv('USER'));
            this = this.BLDNEW;
        end
        
        %% BLDNEW
        %  Intent:
        %     This subroutine is called for entering new blood curves.
        %
        %     The program computes the counts per second for each blood sample
        %     corrected for decay from the time of sampling, the volume of the
        %     sample used in the well counter, and the position of the sample
        %     in the well counter.
        %     The user enters syringe dry & wet weights, times drawn & counted,
        %     and the counts per n seconds, as well as pertinent data concerning
        %     the PET scan.
        %
        %  Uses BLOOD Subroutines:
        %     BLDPARM  - gets scan parameters for each blood curve;
        %     BLDENTER - gets values of each point in blood curve and
        %        computes corrected counts;
        
        function this = BLDNEW(this)
        
            this.TIMESECS = zeros(this.NPOINTS, 1);
            this.COUNTIME =  ones(this.NPOINTS, 1) * double(this.DEFTIME);
            this.CORCNTS  =   nan(this.NPOINTS, 1);
            
            this = this.BLDPARM;            
            
            if (isa(this.bloodData, 'mlpet.Bloodxlsx'))
                fprintf('\nBLOOD POINTS ENTERED FROM %s\n', this.bloodData.xlsxFilename); end
            for p = 1:this.NPOINTS
                this = this.BLDENTER(p);
            end
            
            if (this.SCANTYPE == 1 && this.HEMATOCRIT ~= 0.0 && this.NPOINTS > 2)
                fprintf('The last point should be the well counts for plasma.\n');
                if (TIMEDRAW(this.NPOINTS) ~= TIMEDRAW(this.NPOINTS-1))
                    error('mlpet:unexpectedState', ...
                          'The last 2 points should be whole-blood & plasma counts sampled at the same time!\n');
                end
            end
            
            % Points sampled from plasma should have densities adjusted            
            if ((this.SCANTYPE == 1 || this.SCANTYPE == 7) && this.HEMATOCRIT ~= 0.0)
                this.CORCNTS(this.NPOINTS) = this.CORCNTS(this.NPOINTS)*this.PLASMADN/this.BLOODDEN;
            elseif (this.SCANTYPE == 8)
                for I = 1:this.NPOINTS
                    this.CORCNTS(I) = this.CORCNTS(I)*this.PLASMADN/this.BLOODDEN;
                end
            end
        end
                
        %% BLDPARM
        %
        %  Intent:
        %     This subroutine gets information from the user on parameters
        %     in each blood curve
        
        function this = BLDPARM(this)
            
            % Checking parameters for creating a .DTA file            
            
            % Q = 'Time delay until scan start (MIN.SEC)'
            if (this.ISOTOPE == 1)
                assert(this.inRange(this.SCANSTART, [0.0 10.0]));
            else
                assert(this.inRange(this.SCANSTART, [0.0 60.0]));
            end
            
            % Q = 'Length of Scan (MIN.SEC)'
            if (this.ISOTOPE == 1)
                assert(this.inRange(this.SCANLENGTH, [0.10 20.0]));
            else
                assert(this.inRange(this.SCANLENGTH, [0.10 1000.0]));
            end
            if (this.SCANTYPE == 1 || this.SCANTYPE == 7)
                
                % Q = 'Oxygen Content (ml/ml)'
                assert(this.inRange(this.OXYCONT, [0.01, 0.40]));
                fprintf('If the last blood point is NOT the well counts for plasma,\n');
                fprintf('  then enter 0 for hematocrit.\n');
                
                % Q = 'Hematocrit (percent)'
                assert(this.inRange(this.HEMATOCRIT, [0.0 60.0]));
            elseif (this.SCANTYPE == 8 || this.SCANTYPE == 9)
                
                % Q = 'Oxygen Content (ml/ml)'
                assert(this.inRange(this.OXYCONT, [0.01 0.40]));
                
                % Q = 'Hematocrit (percent)'
                assert(this.inRange(this.HEMATOCRIT, [0.0 60.0]));
            end            
        end        
        
        %% BLDENTER
        %
        %  Intent:
        %     This subroutine gets blood curve points from the user.
        %     It uses dependent variables which access this.bloodData for data values,
        %     checking ranges of validity used in earlier versions of BLOOD.
        %     Manual entry of data values is no longer supported.
        %
        %  Uses Function:
        %     BLDDECOR  - decay correct a single point in a blood curve;
        %     SECS in BLDSECS   
        
        function this = BLDENTER(this, p)
            
            % Q = 'Dry syringe weight (grams)'
            assert(this.inRange(this.DRYWEIGHT(p), [0.0 100.0]));
            % Q = 'Wet syringe weight (grams)'
            assert(this.inRange(this.WETWEIGHT(p), [0.0 100.0]));
            % Q = 'Time Drawn (MIN.SEC)'
            assert(this.inRange(this.TIMEDRAW(p),  [0.0 600.0]));
            this.TIMESECS(p) = this.SECS(this.TIMEDRAW(p));
            % Q = 'Time Counted (MIN.SEC)'
            assert(this.inRange(this.TIMECNT(p), [this.TIMEDRAW(p)+0.01 601.0]));
            if (this.VARYTIME)
                % Q = 'Well count period (seconds)'
                this.COUNTIME(p) = this.bloodData.variableCountTime(p);
                assert(this.inRange(this.COUNTIME(p), [1.0 1000.0]));
            end
            % Q = 'Number of counts'
            assert(this.inRange(this.COUNTS(p), [0 999999]));
            this = this.BLDDECOR(p);
        end
        
        %% BLDDECOR
        %
        %  Intent:
        %     This subroutine calculates the decay-corrected counts,
        %     CORCNTS for a single point in a blood curve.
        %
        %     Decay correction is computed from total activity within
        %     the syringe counting period which is corrected to the counts/sec
        %     at the beginning of the counting period which would produce this
        %     total activity with constant decay (i.e, based on average decay).
        %     This differs slightly from using the midpoint to correct counts
        %     and is theoretically the most accurate estimate.
        %
        %  Variables:
        %     WEIGHT = weight of blood sample (grams);
        %     CORRECTN = correction factor for well counts;
        %        (involves volume of sample and position in well counter)
        %     LAMBDA = decay constant (1/sec);
        %     COUNTS1 = well counts decay corrected to start of counting period;
        %        (based on average decay during the counting period)
        %     FAC,X = temporary
        %
        %  Uses Function
        %     BLDSECS - function name: SECS
        %
        %  Called by:
        %     BLDADDPT
        %     BLDALTER
        %     BLDCALC
        %     BLDENTER
        
        function this = BLDDECOR(this, p)
            
            WEIGHT = this.WETWEIGHT(p) - this.DRYWEIGHT(p);

            % Countrate Correction for well counter (see wellcounter_linearity_20070717_C11.xls)

            X   = (0.001 * this.COUNTS(p)) * (12 / this.COUNTIME(p));
            FAC =  0.000005298 * X * X + 0.0004575 * X + 1.0;
            this.wellCounterDeadtimeCorrection = FAC;

            if (this.ISOTOPE == 6)                         % no decay
                COUNTS1 = double(FAC * this.COUNTS(p)) / this.COUNTIME(p);
                this.CORCNTS(p)= this.BLOODDEN * COUNTS1 / WEIGHT;
            else                                           % decay-correct
                LAMBDA  = log(2) / this.HALFLIFE;
                COUNTS1 = double(FAC * this.COUNTS(p)) * LAMBDA / (1 - exp(-LAMBDA * this.COUNTIME(p)));
                this.CORCNTS(p)= this.BLOODDEN * COUNTS1 * exp(LAMBDA * this.SECS(this.TIMECNT(p))) / WEIGHT;
            end

            CORRECTN = this.SC1 + this.SC2*WEIGHT;
            if (CORRECTN > 0)
                this.CORCNTS(p) = this.CORCNTS(p)/CORRECTN;
            else
                error('mlpet:unexpectedParamValue', ...
                      '*** TOO MUCH BLOOD IN SYRINGE *** counts ~ %f ***', this.CORCNTS(p)*double(DEFTIME));
            end
        end
        
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        
        function s = SECS(~, timeSymbol)
            %% SECS
            %  Usage:  s = this.SECS(1.23)
            %          83
            
            assert(isnumeric(timeSymbol));
            minutes = floor(timeSymbol);
            seconds = 100*(timeSymbol - minutes);
            s       = 60*minutes + seconds;
        end
        function tf = inRange(~, var, rng)
            tf = false;
            if (rng(1) <= var && var <= rng(2))
                tf = true;
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

