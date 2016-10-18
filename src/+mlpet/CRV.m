classdef CRV < mlpet.AbstractWellData 
	%% CRV objectifies Snyder-Videen *.crv files, which directly records beta-detected events from an arterial line.
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
        EXTENSION = '.crv'
        TIMES_UNITS = 'sec'
        COUNTS_UNITS = 'beta-detector events'
    end
    
    methods (Static)
        function this = load(fileLoc)
            this = mlpet.CRV(fileLoc);
        end
    end
    
	methods 
  		function this = CRV(fileLoc) 
 			%% CRV 
 			%  Usage:  this = CRV(file_location) 
            %          this = CRV('/path/to/p1234data/p1234ho1.crv')
            %          this = CRV('/path/to/p1234data/p1234ho1')
            %          this = CRV('p1234ho1')

            this = this@mlpet.AbstractWellData(fileLoc);
            if (isempty(this.filesuffix))
                this.petio_.filesuffix = this.EXTENSION; end
            this = this.readcrv;
        end  
        function save(~)
            error('mlpet:notImplemented', 'CRV.save');
        end
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function this = readcrv(this)
            assert(lexist(this.fqfilename));            
            this = this.readheader;
            this = this.readdata;
        end
        function this = readheader(this) 
            fid = fopen(this.fqfilename);   
            
            line = fgets(fid);
            h = regexp(line, '(?<fqfilename>\S+.crv)\s+(?<date>.+)\s+BinWidth=(?<binwidth>\d+.?\d*)\s+seconds', 'names');
            h.string = line;
            h.binwidth = str2double(h.binwidth); 
            
            line = fgets(fid);
            h1 = regexp(line, '(?<rows>\d+)\s+(?<cols>\d+)', 'names');
            h.rows = str2double(h1.rows);
            h.cols = str2double(h1.cols);
            h.string = [h.string line];  
            
            this.header_ = h;
            fclose(fid);
        end
        function this = readdata(this)
            tab = readtable(this.fqfilename, 'FileType', 'text', 'ReadVariableNames', false, 'Delimiter', ' ','HeaderLines', 2);
            this.times_  = tab.Var1';
            this.taus_   = ones(size(this.times_));
            this.counts_ = tab.Var2';
            this.counts_(1) = this.counts_(3); % legacy defect of .crv format:  first two points are artifacts
            this.counts_(2) = this.counts_(3);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

