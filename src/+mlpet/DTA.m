classdef DTA < mlpet.AbstractWellData
	%% DTA objectifies direct arterial sampling recorded in Videen *.dta files.   
    %  Dta files record well-counter events, corrected for positron half-life.  
    %  Cf. man dta, makedta, blood, metproc
    %
    %  DESCRIPTION
    %
    %    dta files are used by metproc and petproc to create hdr files.  The hdr files are necessary to process or display PET
    %    images as metabolic images.  Dta files are created by blood, betadta, or fastdta.  Each dta file may contain informa-
    %    tion about 1 or more scans.
    %
    %  DTA FILE STRUCTURE
    %
    %    First  line  is  a  4-character  code string followed by text.  The second and third lines are column
    %    headers for the blood points.  The fourth line has the number of curves in this file.
    % 
    %    _________________________________________________________________
    %    @01@ blood.f,v 1.6 1995/05/10 on p1376
    %       Corrected     Syringe Weight      Sample Time    Measured   Per
    %     Sec   Counts     Dry      Wet      Drawn  Counted    Counts   Sec
    %           3
    %    _________________________________________________________________
    % 
    %    For each blood curve:
    %    _________________________________________________________________
    %    Type of Scan                Scan ID          (I1, 1X, A4)
    %    Start Time (s)              Scan Length (s)  (2F9.0)
    %    Peak Bank Pairs (thousands)                  (F10.4)
    %    Oxygen Content (ml/ml)      Hematocrit (%)   (2F10.4)
    %    Number of Blood Points                       (I)
    %    Corrected Time, Corrected Counts, Dry Wt, Wet Wt, Sample
    %       Time, Count Time, Counts, Count Period    (6F, I, F)
    %          .
    %          .
    %          .
    %    _________________________________________________________________
    %    Notes:
    % 
    %    1) Corrected Time = sample time (seconds after injection;
    %       shifted);
    % 
    %    2) Corrected Counts = decay-corrected wellcounts/(ml*sec);
    %       Decay correction is to the time of injection;
    %       Conversion is from counts/(g*time) to counts/(ml*sec);
    %       (using density of whole blood or plasma, as appropriate)
    %       (time is the period given in the last column)
    % 
    %    3) For scantype=1, if the hematocrit is not 0, then the
    %       last point in the blood curve is the well counts for
    %       plasma taken from the same sample as the whole blood in
    %       the next to last point;
    % 
    %    4) Scan ID is the last 3-4 characters of the scan file name;
    %       e.g., for p1000ho1.img, the scan ID would be ho1;
    % 
    %    5) Scan Types: (aka ntype)
    %       1 = O-15 Oxygen Metabolism Study  (oo)
    %       2 = O-15 Water Blood Flow Study   (ho)
    %       3 = O-15 Blood Volume Study       (co)
    %       4 = C-11 Butanol Blood Flow Study (bu)
    %       5 = F-18 Study
    %       6 = Misc. Study
    %       7 = O-15 Oxygen Steady-State Study (oo)
    %       8 = O-15 Oxygen Steady-Inhalation plasma curve (oo)
    %       9 = O-15 Oxygen Steady-Inhalation whole-blood  (oo)

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 
    %%

    properties (Constant)
        READ_HEADER_EXP1 = ...
            '(?<pnumber>p\d{4})\s+\w*\s*\w*\s*(?<dateScan>\d+(/|-)\d+(/|-)\d+)\s+(?<studyCode>\w+)(?<petIndex>\d)\s+(?<dateProcessing>\d+(/|-)\d+(/|-)\d+)\s+(?<author>\w+)'
        READ_HEADER_EXP2 = ...
            '@\d+@\s+(?<pnumber>p\d{4})\s+\w*\s*\w*\s*(?<dateScan>\d+(/|-)\d+(/|-)\d+)\s+(?<studyCode>\w+)(?<petIndex>\d)\s+(?<author>\w+)'
    end
    
    properties (Dependent)
        activity
        specificActivity
    end
    
    methods % GET
        function b = get.activity(this)
            b = this.counts; % DTA file column counts is divided by taus; cf. mlpet.Blood
        end
        function g = get.specificActivity(this)
            g = this.counts;
        end
        function this = set.specificActivity(this, s)
            assert(isnumeric(s));
            this.counts = s;
        end
    end
    
    properties
        syringeWeightDry
        syringeWeightWet
        sampleTimesDrawn
        sampleTimesCounted
        measuredCounts
        countPeriod
    end
    
    methods (Static)
        function this = load(fileLoc, varargin)
            ip = inputParser;
            addRequired(ip, 'fileLoc',          @ischar);
            addOptional(ip, 'shortHead', false, @islogical);
            parse(ip, fileLoc, varargin{:});
            
            this = mlpet.DTA(fileLoc);
            if (ip.Results.shortHead)
                this = this.readShortDta;
            else
                this = this.readDta;
            end
        end
        function this = loadSessionData(sessDat, varargin)
            ip = inputParser;
            addRequired(ip, 'sessDat',          @(x) isa(x, 'mlpipeline.ISessionData'));
            addOptional(ip, 'shortHead', false, @islogical);
            parse(ip, sessDat, varargin{:});
            
            this = mlpet.DTA(sessDat.dta_fqfn);
            if (ip.Results.shortHead)
                this = this.readShortDta;
            else
                this = this.readDta;
            end
        end
        function this = importBlood(b)
            assert(isa(b, 'mlpet.Blood'));
            this = mlpet.DTA(b.dtaFilename); 
            
            this.syringeWeightDry   = b.DRYWEIGHT;
            this.syringeWeightWet   = b.WETWEIGHT;
            this.sampleTimesDrawn   = b.TIMEDRAW;
            this.sampleTimesCounted = b.TIMECNT;
            this.measuredCounts     = b.COUNTS;
            this.countPeriod        = b.COUNTIME;
            
            this.header_.string        = b.header;
            this.header_.scanType      = b.SCANTYPE;
            this.header_.scanSymbol    = b.scanSymbol;
            this.header_.scanStart     = this.secs(b.SCANSTART);
            this.header_.scanLength    = this.secs(b.SCANLENGTH);
            this.header_.oxygenContent = b.OXYCONT;
            this.header_.Hct           = b.HEMATOCRIT;
            this.times_                = b.TIMESECS;
            this.counts_               = b.CORCNTS;
            
            this.isPlasma = false;
        end
    end
    
	methods
  		function this = DTA(fileLoc)
 			%% DTA 
 			%  Usage:  this = DTA(file_location[, read_short_header]) 
            %          this = DTA('/path/to/p1234data/p1234ho1.crv', true)
            %          this = DTA('/path/to/p1234data/p1234ho1')
            %          this = DTA('p1234ho1')

            this = this@mlpet.AbstractWellData(fileLoc);
            
            if (isempty(this.filesuffix))
                this.petio_.filesuffix = '.dta'; 
            end
        end
        function b    = activityInterpolants(this, varargin)
            b = this.countInterpolants(varargin{:});
        end
        function        save(this)
            fid = fopen(this.fqfilename, 'w');
            fprintf(fid, '%s\n', this.header.string);
            fprintf(fid, '       Corrected     Syringe Weight      Sample Time    Measured   Per\n');
            fprintf(fid, '     Sec   Counts     Dry      Wet      Drawn  Counted    Counts   Sec\n');
            fprintf(fid, '  1\n'); % number of scans/tracers            
            fprintf(fid, '%i %s\n', this.header.scanType, this.header.scanSymbol);
            fprintf(fid, '%9.0f%9.0f\n', this.header.scanStart, this.header.scanLength);
            fprintf(fid, '%10.4f%10.4f\n', 0, 0); % bank pairs
            fprintf(fid, '%10.4f%10.4f\n', this.header.oxygenContent, this.header.Hct);
            fprintf(fid, '%i\n', this.length);            
            for f = 1:this.length
                fprintf(fid, '%8.0f%10.0f%9.5f%9.5f%9.2f%9.2f%10i%6.0f\n', ...
                        this.times(f),            this.counts(f),             this.syringeWeightDry(f), this.syringeWeightWet(f), ...
                        this.sampleTimesDrawn(f), this.sampleTimesCounted(f), this.measuredCounts(f),   this.countPeriod(f));
            end
            fprintf(fid, '\n');
            fclose(fid);
        end   
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function this = readShortDta(this)
            fid  = fopen(this.fqfilename);
            this = this.readShortHeader(fid);
            this = this.readData(fid);
            fclose(fid);
        end
        function this = readDta(this)
            fid  = fopen(this.fqfilename);
            this = this.readHeader(fid);
            this = this.readData(fid);
            fclose(fid);
        end
        function this = readShortHeader(this, fid)
            str = textscan(fid, '%s', 1, 'Delimiter', '\n');            
            str = str{1}; str = str{1};
            try
                h = regexp(str, this.READ_HEADER_EXP1, 'names');
                h.petIndex = str2double(h.petIndex);
                h.string = strtrim(str);
                this.header_ = h;
            catch %#ok<CTCH>
                this.header_.string = str;
            end            
            len = textscan(fid, '%d', 1, 'Delimiter', '\n'); 
            this.header_.length = len{1};
        end
        function this = readHeader(this, fid)
            str = textscan(fid, '%s', 1, 'Delimiter', '\n');            
            str = str{1}; str = str{1};
            try
                h = regexp(str, this.READ_HEADER_EXP1, 'names');
                if (~isempty(h))
                    this = this.readHeader1(fid, str, h);
                else
                    h = regexp(str, this.READ_HEADER_EXP2, 'names');
                    this = this.readHeader2(fid, str, h);
                end
                if (0 == this.header_.length)
                    this = this.readHeader3(fid); %% KLUDGE
                end
            catch ME
                handerror(ME);
            end
        end        
        function this = readHeader1(this, fid, str, h)
            h.petIndex   = str2double(h.petIndex);
            h.string     = strtrim(str);
            this.header_ = h;
            
                  textscan(fid, '%s',    1, 'Delimiter', '\n');
                  textscan(fid, '%s',    1, 'Delimiter', '\n');
            ts  = textscan(fid, '%d',    1, 'Delimiter', '\n');
            this.header_.numberScans = ts{1};
            
            ts  = textscan(fid, '%d %s', 1, 'Delimiter', '\n');
            this.header_.scanType   = ts{1};
            tmp                     = ts{2};
            this.header_.scanSymbol = tmp{1};
            
            ts  = textscan(fid, '%d %d', 1, 'Delimiter', '\n');
            this.header_.scanStart  = ts{1};
            this.header_.scanLength = ts{2};
            
            ts  = textscan(fid, '%d %d', 1, 'Delimiter', '\n');
            this.header_.bankPairs = [ts{1} ts{2}];
            
            ts  = textscan(fid, '%d %d', 1, 'Delimiter', '\n');
            this.header_.oxygenContent = ts{1};
            this.header_.length = ts{2};
        end        
        function this = readHeader2(this, fid, str, h)
            h.petIndex   = str2double(h.petIndex);
            h.string     = strtrim(str);
            this.header_ = h;
            
                  textscan(fid, '%s',    1, 'Delimiter', '\n');
                  textscan(fid, '%s',    1, 'Delimiter', '\n');
            ts  = textscan(fid, '%d',    1, 'Delimiter', '\n');
            this.header_.numberScans = ts{1};
            
            ts  = textscan(fid, '%d %s', 1, 'Delimiter', '\n');
            this.header_.scanType   = ts{1};
            tmp                     = ts{2};
            this.header_.scanSymbol = tmp{1};
            
            ts  = textscan(fid, '%d %d', 1, 'Delimiter', '\n');
            this.header_.scanStart  = ts{1};
            this.header_.scanLength = ts{2};
            
            ts  = textscan(fid, '%d', 1, 'Delimiter', '\n');
            this.header_.bankPairs = ts{1};
            
            ts  = textscan(fid, '%d %d', 1, 'Delimiter', '\n');
            this.header_.oxygenContent = ts{1};
            this.header_.Hct           = ts{2};
            
            len = textscan(fid, '%d',    1, 'Delimiter', '\n'); 
            this.header_.length = len{1};
        end
        function this = readHeader3(this, fid)            
            ts  = textscan(fid, '%d', 1, 'Delimiter', '\n');
            this.header_.length = ts{1};
        end  
        function this = readData(this, fid)
            ts = textscan(fid, '%f %f %f %f %f %f %f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
            this.times_ = ts{1}';
            this.counts_ = ts{2}';
            this.syringeWeightDry = ts{3}';
            this.syringeWeightWet = ts{4}';
            this.sampleTimesDrawn = ts{5}';
            this.sampleTimesCounted = ts{6}';
            this.measuredCounts = ts{7}';
            this.countPeriod = ts{8}';
            this.taus_ = this.times_(2:end) - this.times_(1:end-1);
            this.assertLength; 
            this.isPlasma = false;
        end
        function assertLength(this)
            if (length(this.times_) ~= this.header.length) %#ok<*ALIGN>
                error('mlpet:unexpectedDataLength', 'DTA.header.length -> %i, but length(.times_) -> %i', ...
                       this.header.length, length(this.times_)); end
            if (length(this.counts_) ~=  this.header.length)
                error('mlpet:unexpectedDataLength', 'DTA.header.length -> %i, but length(.counts_) -> %i', ...
                       this.header.length, length(this.counts_)); end
        end        
        function s = secs(~, timeSymbol)
            %% SECS
            %  Usage:  s = this.SECS(1.23)
            %          83
            
            assert(isnumeric(timeSymbol));
            minutes = floor(timeSymbol);
            seconds = 100*(timeSymbol - minutes);
            s       = 60*minutes + seconds;
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end


