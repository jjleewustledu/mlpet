classdef DCV < mlpet.AbstractWellData
	%% DCV objectifies Snyder-Videen *.dcv files, replacing the first two count measurements with the third,
    %  adding hand-measured counts at the end for assessment of detector drift.  Dcv files record beta-detector events,
    %  which have been corrected for positron-emitter half-life, with deconvolution of the dispersion of the cannulated
    %  arterial line and with beta-detector events multiplied by well-factors to yield well-counter-normalized units.
    %  Cf. man betadcv, metproc

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 
    
    
    methods (Static)
        function this = load(varargin)
            this = mlpet.DCV(varargin{:});
        end
    end
    
	methods 
  		function this = DCV(fileLoc)
 			%  Usage:  this = DCV(file_location) 
            %          this = DCV('/path/to/p1234data/p1234ho1.crv')
            %          this = DCV('/path/to/p1234data/p1234ho1')
            %          this = DCV('p1234ho1')

            this = this@mlpet.AbstractWellData(fileLoc);
            if (isempty(this.filesuffix))
                this.petio_.filesuffix = '.dcv'; end
            
            this = this.readdcv;
        end  
        function this = save(this)
            fid = fopen(this.fqfilename, 'w');
            fprintf(fid, '%s\n', this.header.string);
            for f = 1:length(this.counts)
                fprintf(fid, '%9.1f\t%14.1f\n', this.times(f), this.counts(f));
            end
            fclose(fid);            
            %dlmwrite(this.fqfilename, round([this.times' this.counts']), '-append', 'delimiter', '\t');
        end       
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        DCV_HEADER_EXPRESSION_ = ...
            ['(?<clock>\d+:\d+)\s+(?<samples>\d+)\s+(?<n1>\d+.\d+)\s+(?<n2>\d+.\d+)\s+' ...
             'WELLF=\s*(?<wellf>\d+.\d+)\s+T0=\s*(?<t0>\d+.\d+)\s+K1=\s*(?<k1>\d+.\d+)\s+E=\s*(?<e>\d*.\d+)\s+NSMO=\s*(?<nsmo>\d+)\s+' ...
             '(?<fqfilename>\w+.\w+)']
        % matches contents similar to:
        % '2:19       121  0.0000  28.4  WELLF= 22.7400 T0= 3.66 K1= 0.331 E=.087 NSMO= 2  p8425ho2.crv        '
    end
    
    methods (Access = 'private')
        function this = readdcv(this)
            fid = fopen(this.fqfilename);
            this = this.readheader(fid);
            this = this.readdata(fid);
            fclose(fid);            
        end
        function this = readheader(this, fid)
            str = textscan(fid, '%s', 1, 'Delimiter', '\n');
            str = str{1}; str = str{1};
            h   = regexp(str, this.DCV_HEADER_EXPRESSION_, 'names');
            
            h.string  = strtrim(str);
            h.samples = uint8(str2double(h.samples));
            h.n1      = str2double(h.n1);
            h.n2      = str2double(h.n2);
            h.wellf   = str2double(h.wellf);
            h.t0      = str2double(h.t0);
            h.k1      = str2double(h.k1);
            h.e       = str2double(h.e);
            h.nsmo    = uint8(str2double(h.nsmo));
            
            this.header_ = h;
            this.wellFactor_ = h.wellf;
        end
        function this = readdata(this, fid)
            ts = textscan(fid, '%f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
            this.times_  = ts{1}';
            this.taus_   = this.times_(2:end) - this.times_(1:end-1);
            this.taus_(length(this.times_)) = this.taus_(end);
            this.counts_ = ts{2}';
            this = this.cullZeros;
            this = this.cullDropoff;
            this = this.cullZeros;
        end
        function this = cullDropoff(this)
            t_max = this.timeOfMax(this.counts_);
            t_min = this.timeOfMin(this.counts_(floor(t_max):end));
            this.counts_(t_min) = 0;
        end
        function t_max = timeOfMax(this, y)
            for t = 1:length(this.times_)
                if (this.counts_(t) == max(y))
                    t_max = t;
                    break
                end
            end
        end
        function t_min = timeOfMin(this, y)
            for t = 1:length(this.times_)
                if (this.counts_(t) == min(y))
                    t_min = t;
                    break
                end
            end
        end
        function this = cullZeros(this)
            exclusions   = this.counts_ ~= 0;
            this.counts_ = this.counts_(exclusions);
            this.taus_   = this.taus_(exclusions);
            this.times_  = this.times_(exclusions);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

