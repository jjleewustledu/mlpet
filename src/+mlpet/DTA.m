classdef DTA < mlpet.AbstractWellData
	%% DTA objectifies direct arterial sampling recorded in Videen *.dta files.   
    %  Dta files record well-counter events, corrected for positron half-life.  
    %  Cf. man dta, makedta, blood, metproc
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

    properties (Constant)
        EXTENSION = '.dta'        
        TIMES_UNITS = 'sec'
        COUNTS_UNITS = 'well-counter events/mL/sec'
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
        function this = load(fileLoc)
            this = mlpet.DTA(fileLoc);
        end
    end
    
	methods 
  		function this = DTA(fileLoc) 
 			%% DTA 
 			%  Usage:  this = DTA(file_location) 
            %          this = DTA('/path/to/p1234data/p1234ho1.crv')
            %          this = DTA('/path/to/p1234data/p1234ho1')
            %          this = DTA('p1234ho1')

            this = this@mlpet.AbstractWellData(fileLoc);
            if (isempty(this.filesuffix))
                this.petio_.filesuffix = this.EXTENSION; end
            this = this.readdta;
        end      
        function save(~)
            error('mlpet:notImplemented', 'DTA.save');
        end   
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function this = readdta(this)
            fid = fopen(this.fqfilename);
            if (str2double(this.fileprefix(2:5)) > 6000)
                this = this.readheader2(fid);
            else
                this = this.readheader(fid);
            end
            this = this.readdata(fid);           
        end           
        function this = readheader(this, fid)
            textscan(fid, '%s', 8, 'Delimiter', '\n');
            
            len = textscan(fid, '%d', 1, 'Delimiter', '\n'); 
            this.header_.length = len{1};
        end
        function this = readheader2(this, fid)
            str = textscan(fid, '%s', 1, 'Delimiter', '\n');            
            str = str{1}; str = str{1};
            h = regexp(str, ...
                '(?<pnumber>p\d{4})\s+(?<dateScan>\d+-\d+-\d+)\s+(?<studyCode>\w+)(?<petIndex>\d)\s+(?<dateProcessing>\d+/\d+/\d+)\s+(?<author>\w+)', ...
                'names');
            h.petIndex = str2double(h.petIndex);
            h.string = strtrim(str);
            this.header_ = h;
            this.assertHeader;
            
            len = textscan(fid, '%d', 1, 'Delimiter', '\n'); 
            this.header_.length = len{1};
        end
        function assertHeader(this)            
            assert(strncmp(this.fileprefix, this.header.pnumber, 5));
            assert(strcmp(this.fileprefix(end), num2str(this.header.petIndex)));
        end
        function this = readdata(this, fid)            
            ts = textscan(fid, '%f %f %f %f %f %f %f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
            this.times_ = ts{1}';
            this.taus_ = this.times_(2:end) - this.times_(1:end-1);
            this.taus_(this.length) = this.taus_(end);
            this.counts_ = ts{2}';
            this.syringeWeightDry = ts{3}';
            this.syringeWeightWet = ts{4}';
            this.sampleTimesDrawn = ts{5}';
            this.sampleTimesCounted = ts{6}';
            this.measuredCounts = ts{7}';
            this.countPeriod = ts{8}';            
            
            this.assertLength; 
        end
        function assertLength(this)            
            if (length(this.times_) ~= this.header.length) %#ok<*ALIGN>
                error('mlpet:unexpectedDataLength', 'DTA.header.length -> %i, but length(.times_) -> %i', ...
                      this.header.length, length(this.times_)); end
            if (length(this.counts_) ~=  this.header.length)
                error('mlpet:unexpectedDataLength', 'DTA.header.length -> %i, but length(.counts_) -> %i', ...
                      this.header.length, length(this.counts_)); end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end


