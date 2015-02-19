classdef DecayCorrection < mlpet.IDecayCorrection
	%% DECAYCORRECTION   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$  	 
    
    properties (Constant)
        ISOTOPES = {'15O' '11C'};
    end
    
    properties    
        pie
    end

    properties (Dependent)
        isotope
        halfLife
        wellFqfilename
        wellFactor
    end
    
    methods %% GET, SET
        function i = get.isotope(this)
            i = this.isotope_;
        end
        function this = set.isotope(this, i)
            assert(lstrfind(i, this.ISOTOPES));
            this.isotope_ = i;
        end
        function h = get.halfLife(this)
            switch (this.isotope)
                case '11C'
                    h = 20.334*60; % sec
                case '15O'
                    h = 122.1; % sec
                otherwise
                    error('mlpet:unsupportedState', ...
                        'DecayCorrection.get.halflife did not recognize this.isotope -> %s', this.isotope);
            end
        end
        function f = get.wellFqfilename(this)
            f = fullfile(this.petio_.filepath, sprintf('%s.wel', str2pnum(this.petio_.fileprefix)));
        end
        function w = get.wellFactor(this)
            assert(~isempty(this.wellMatrix_), ...
                'DecayCorrection.get.wellFactor:  this.wellMatrix_ was empty');
            w = this.wellMatrix_(5,1); 
        end
    end

    methods
        function this = DecayCorrection(varargin)
            %% DECAYCORRECTION
 			%  Usage:  this = this@mlpet.DecayCorrection(well_file_location, isotope[, pie_factor]);
            %          this = this@mlpet.DecayCorrection('/path/to/p1234data/p1234.wel', '15O', 4.88)
            %          this = this@mlpet.DecayCorrection('/path/to/p1234data/p1234', '15O')
            %          this = this@mlpet.DecayCorrection('p1234', '15O')

            p = inputParser;
            addRequired(p, 'fileLocation', @ischar);
            addRequired(p, 'isotope',      @(x) lstrfind(x, this.ISOTOPES));
            addOptional(p, 'pie', nan,     @isnumeric);
            parse(p, varargin{:});
            
            this.petio_ = mlpet.PETIO(p.Results.fileLocation);
            this = this.readWellMatrix;
            this.pie = p.Results.pie;
            this.isotope = p.Results.isotope;
            
            fprintf('mlpet.DecayCorrection:  pie = %f, well-factor = %f\n', this.pie, this.wellFactor);
        end
        function cnts = correctedBetaCounts(this, cnts, varargin)
            %% CORRECTEDBETACOUNTS corrects positron decay, converts to well-couunts
            %  Usage:  counts = this.correctedBetaCounts(counts[, times, taus]) % numeric counts            
            
            p = inputParser;
            addRequired(p, 'cnts',                    @isnumeric);
            addOptional(p, 'times', 1:length(cnts),   @isnumeric);
            addOptional(p, 'taus',  ones(size(cnts)), @isnumeric);
            parse(p, cnts, varargin{:});
            
            cnts = this.wellFactor * p.Results.cnts .* exp(this.lambda * p.Results.times) ./ p.Results.taus;
        end
        function cnts = correctedWellCounts(this, cnts, varargin)
            %% CORRECTEDWELLCOUNTS corrects positron decay, maintains well-couunts
            %  Usage:  counts = this.correctedWellCounts(counts[, times, taus]) % numeric counts            
            
            p = inputParser;
            p = inputParser;
            addRequired(p, 'cnts',                    @isnumeric);
            addOptional(p, 'times', 1:length(cnts),   @isnumeric);
            addOptional(p, 'taus',  ones(size(cnts)), @isnumeric);
            parse(p, cnts, varargin{:});
            
            cnts = p.Results.cnts .* exp(this.lambda * p.Results.times) ./ p.Results.taus;
        end
        function cnts = correctedScannerCounts(this, cnts, varargin)
            %% CORRECTEDSCANNERCOUNTS corrects positron decay, converts to well-couunts
            %  Usage:  counts = this.correctedScannerCounts(counts[, times, taus]) % numeric counts            
            
            p = inputParser;
            p = inputParser;
            addRequired(p, 'cnts',                    @isnumeric);
            addOptional(p, 'times', 1:length(cnts),   @isnumeric);
            addOptional(p, 'taus',  ones(size(cnts)), @isnumeric);
            parse(p, cnts, varargin{:});
            
            for t = 1:size(cnts,4)
                cnts(:,:,:,t) = 60 * this.pie * cnts(:,:,:,t) .* exp(this.lambda * p.Results.times(t)) ./ p.Results.taus(t);
            end
        end
    end
    
    %% PRIVATE
    
    properties (Access = 'private')
        petio_
        isotope_
        wellMatrix_
    end
    
    methods (Access = 'private')
        function this = readWellMatrix(this)
            try
                fid = fopen(this.wellFqfilename);
                tmp = textscan(fid, '%f %f %f %f %f');
                this.wellMatrix_ = cell2mat(tmp);
                fclose(fid);
            catch ME
                handexcept(ME);
            end
        end
        function l    = lambda(this)
            l = log(2) / this.halfLife;
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

