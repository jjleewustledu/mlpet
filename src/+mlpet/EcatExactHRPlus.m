classdef EcatExactHRPlus < mlpet.AbstractScannerData 
	%% ECATEXACTHRPLUS   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 

    properties (Constant)
        EXTENSION = '.nii.gz'
        TIMES_UNITS = 'sec'
        COUNTS_UNITS = 'scanner-array events'
    end    

    methods (Static)
        function this = load(fileLoc)
            this = mlpet.EcatExactHRPlus(fileLoc);
        end
    end
    
	methods 		  
 		function this = EcatExactHRPlus(fileLoc) 
 			%% ECATEXACTHRPLUS 
 			%  Usage:  this = EcatExactHRPlus(file_location) 
            %          this = EcatExactHRPlus('/path/to/p1234data/p1234ho1.nii.gz')
            %          this = EcatExactHRPlus('/path/to/p1234data/p1234ho1')
            %          this = EcatExactHRPlus('p1234ho1') 

 			this = this@mlpet.AbstractScannerData(fileLoc); 
            if (isempty(this.filesuffix))
                this.petio_.filesuffix = this.EXTENSION; end
            this = this.readEcat;
 		end 
        function this = save(this)
            this.nifti_.img = this.counts_;
            this.nifti_.fqfileprefix = [this.petio_.fqfileprefix sprintf('_%s', datestr(now, 30))];
            this.nifti_.save;
        end
 	end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function this = readEcat(this)            
            assert(lexist(this.recFqfilename));            
            this = this.readRec;
            this = this.readNifti;
        end
        function this = readRec(this)
            try
                tp = mlio.TextParser.load(this.recFqfilename);
                this = this.readHeader(tp);
                this = this.readSchedule(tp);                
                this = this.readTimes;
                this = this.readTaus;
            catch ME
                handexcept(ME);
            end
        end
        function this = readHeader(this, txtPars)
            this.header_.injectionTime = txtPars.parseAssignedNumeric('Start time');
            this.header_.numberOfFrames = txtPars.parseColonNumeric('number of frames');
            this.header_.string = char(txtPars);
        end
        function this = readSchedule(this, txtPars)
            [~,first] = txtPars.findFirstCell('Frame  Start  Duration (sec)'); 
            first = first + 2;
            last = first + this.header.numberOfFrames - 2;
            this.header_.frame    = zeros(1,last-first+1);
            this.header_.start    = zeros(1,last-first+1);
            this.header_.duration = zeros(1,last-first+1);
            for c = first:last
                expr = '(?<frame>\d+\.?\d*)\s+(?<start>-?\d+\.?\d*)\s+(?<duration>\d+\.?\d*)';
                names = regexp(txtPars.cellContents{c}, expr, 'names');
                cc = c - first + 1;
                this.header_.frame(cc)    = str2double(names.frame);
                this.header_.start(cc)    = str2double(names.start);
                this.header_.duration(cc) = str2double(names.duration);
            end
        end
        function this = readTimes(this)
            this.times_ = this.header.start;
        end
        function this = readTaus(this)
            this.taus_ = this.header.duration;
        end
        function this = readNifti(this)
            this.nifti_ = mlfourd.NIfTI.load(this.fqfilename);
            this.counts_ = this.nifti_.img;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

