classdef DTA < mlpet.AbstractWellData
	%% DTA objectifies direct arterial sampling recorded in Videen *.dta files.   
    %  Dta files record well-counter events, corrected for positron half-life.  
    %  Cf. man dta, makedta, blood, metproc

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
        COUNTS_UNITS = 'well-counter events'
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
            this = this.readheader(fid);
            this = this.readdata(fid);           
        end        
        function this = readheader(this, fid)
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
            this.taus_ = ones(size(this.times_));
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


