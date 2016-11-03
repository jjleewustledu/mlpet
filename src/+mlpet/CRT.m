classdef CRT < mlpet.AbstractBetaCurve 
	%% CRT objectifies Snyder-Videen *.crv files, which directly records beta-detected events from an arterial line.
    %  It is not decay-corrected.  It replaces the first two count measurements with the third.
    %  Cf. man metproc

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$  	 

    properties (Constant)
        EXTENSION = '.crt'
        TIMES_UNITS = 'sec'
        COUNTS_UNITS = 'beta-detector events'
    end
    
    methods (Static)
        function this = load(fileLoc)
            this = mlpet.CRT(fileLoc);
        end
    end
    
	methods 
  		function this = CRT(fileLoc) 
 			%% CRT 
 			%  Usage:  this = CRT(file_location) 
            %          this = CRT('/path/to/p1234data/p1234ho1.crv')
            %          this = CRT('/path/to/p1234data/p1234ho1')
            %          this = CRT('p1234ho1')

            this = this@mlpet.AbstractBetaCurve(fileLoc);
            if (isempty(this.filesuffix))
                this.petio_.filesuffix = this.EXTENSION; end
            this = this.readcrv;
        end  
        function save(~)
            error('mlpet:notImplemented', 'CRT.save');
        end
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function this = readcrv(this)
            assert(lexist(this.fqfilename));   
            fid  = fopen(this.fqfilename);           
            this = this.readheader(fid);
            this = this.readdata(fid);
            fclose(fid);
        end
        function this = readheader(this, fid)  
            
            line = fgets(fid);
            h = regexp(line, '(?<fqfilename>\S+.(crv|CRV))\s+(?<date>.+)\s+BinWidth=(?<binwidth>\d+.?\d*)\s+seconds', 'names');
            h.string = line;
            h.binwidth = str2double(h.binwidth); 
            
            line = fgets(fid);
            h1 = regexp(line, '(?<rows>\d+)\s+(?<cols>\d+)', 'names');
            h.rows = str2double(h1.rows);
            h.cols = str2double(h1.cols);
            h.string = [h.string line];  
            
            this.header_ = h;
        end
        function this = readdata(this, fid)
            
            ts = textscan(fid, '%f %f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
            this.times_  = ts{1}';
            this.taus_   = ones(size(this.times_));
            this.counts_ = ts{2}';
            this.counts_(1) = this.counts_(3); % legacy defect of .crv format:  first two points are artifacts
            this.counts_(2) = this.counts_(3);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

