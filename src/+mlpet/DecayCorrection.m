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
    
    properties (Dependent)
        isotope
        halfLife
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
    end

    methods
        function this = DecayCorrection(varargin)
            %% DECAYCORRECTION
 			%  Usage:  this = this@mlpet.DecayCorrection(IWellData_client);

            p = inputParser;
            addRequired(p, 'client',   @(x) isa(x, 'mlpet.IWellData'));
            parse(p, varargin{:});
            
            this.client_ = p.Results.client;
            this.petio_ = mlpet.PETIO(p.Results.client.fqfilename);
            this.isotope = this.client_.guessIsotope;            
        end
        function cnts = correctedCounts(this, cnts, varargin)
            %% CORRECTEDCOUNTS corrects positron decay
            %  Usage:  counts = this.correctedBetaCounts(counts[, times, denom]) % numeric counts  
            
            p = inputParser;
            addRequired(p, 'cnts',                      @isnumeric);
            addOptional(p, 'times', this.client_.times, @isnumeric);
            parse(p, cnts, varargin{:});
            
            denom = ones(size(cnts));
            if (isa(this.client_, 'mlpet.IScannerData'))
                cnts = correctedScannerCounts(this, cnts, p.Results.times, denom, 1);
            elseif (isa(this.client_, 'mlpet.IBetaCurve'))
                cnts = correctedBetaCounts(   this, cnts, p.Results.times, denom, 1);
            elseif (isa(this.client_, 'mlpet.IWellData'))
                cnts = correctedWellCounts(   this, cnts, p.Results.times, denom, 1);
            else
                error('mlpet:unsupportedTypeClass', ...
                      'DecayCorrection.correctedCounts does not support clients of type %s', class(this.client_));
            end
        end
        function cnts = uncorrectedCounts(this, cnts, varargin)
            %% UNCORRECTEDCOUNTS reintroduces positron decay
            %  Usage:  counts = this.uncorrectedBetaCounts(counts[, times, denom]) % numeric counts  
            
            p = inputParser;
            addRequired(p, 'cnts',                      @isnumeric);
            addOptional(p, 'times', this.client_.times, @isnumeric);
            parse(p, cnts, varargin{:});
            
            denom = ones(size(cnts));
            if (isa(this.client_, 'mlpet.IScannerData'))
                cnts = correctedScannerCounts(this, cnts, p.Results.times, denom, -1);
            elseif (isa(this.client_, 'mlpet.IBetaCurve'))
                cnts = correctedBetaCounts(   this, cnts, p.Results.times, denom, -1);
            elseif (isa(this.client_, 'mlpet.IWellData'))
                cnts = correctedWellCounts(   this, cnts, p.Results.times, denom, -1);
            else
                error('mlpet:unsupportedTypeClass', ...
                      'DecayCorrection.correctedCounts does not support clients of type %s', class(this.client_));
            end
        end
        function l    = lambda(this)
            l = log(2) / this.halfLife;
        end
    end
    
    %% PRIVATE
    
    properties (Access = 'private')
        client_
        
        petio_
        isotope_
        wellMatrix_
    end
    
    methods (Access = 'private')
        function cnts = correctedBetaCounts(this, cnts, times, denom, sig)
            sig = sign(sig);
            cnts = cnts .* exp(sig * this.lambda * times) ./ denom;
        end
        function cnts = correctedWellCounts(this, cnts, times, denom, sig)
            sig = sign(sig);
            cnts = cnts .* exp(sig * this.lambda * times) ./ denom;
        end
        function cnts = correctedScannerCounts(this, cnts, times, denom, sig)
            sig = sign(sig);
            switch (length(size(cnts)))
                case 2
                    cnts = cnts .* exp(sig * this.lambda * times(t)) ./ denom;
                case 3
                    for t = 1:size(cnts,3)
                        cnts(:,:,t) = cnts(:,:,t) .* exp(sig * this.lambda * times(t)) ./ denom(t);
                    end
                case 4
                    for t = 1:size(cnts,4)
                        cnts(:,:,:,t) = cnts(:,:,:,t) .* exp(sig * this.lambda * times(t)) ./ denom(t);
                    end
                otherwise
                    error('mlpet:unsupportedArraySize', 'size(DecayCorrection.correctedScannerCounts.cnts) -> %s', mat2str(size(cnts)));
            end 
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

