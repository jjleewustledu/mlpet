classdef DecayCorrection
	%% DECAYCORRECTION   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$  	 
    
    
    properties (Dependent)
        isotope
        halfLife
    end
    
    methods %% GET
        function g = get.isotope(this)
            g = this.client_.isotope;
        end
        function g = get.halfLife(this)
            switch (this.isotope)
                case '11C'
                    g = 20.334*60; % sec
                case '15O'
                    g = 122.1; % sec
                case '18F'
                    g = 109.77120*60; % sec
                otherwise
                    error('mlpet:unsupportedSwitchCase', ...
                        'DecayCorrection.get.halflife did not recognize this.isotope -> %s', this.isotope);
            end
        end
    end

    methods
        function this = DecayCorrection(varargin)
            %% DECAYCORRECTION
 			%  Usage:  this = this@mlpet.DecayCorrection(IAifData_obj|IWellData_obj);

            ip = inputParser;
            addRequired( ip, 'client',  @(x) isa(x, 'mlpet.IAifData') || isa(x, 'mlpet.IWellData'));
            parse(ip, varargin{:});
            
            this.client_ = ip.Results.client;
        end
        function [t,c] = shiftCorrectedCounts(~, t, c, Dtzero)
            assert(isnumeric(c));
            assert(isnumeric(Dtzero));
            if (abs(Dtzero) < eps)
                return
            end
            [t,c] = shiftNumeric(t, c, Dtzero, false);
        end
        function [t,c] = shiftUncorrectedCounts(this, t, c, Dtzero)
            assert(isnumeric(c));
            assert(isnumeric(Dtzero));
            tzero = seconds(this.client_.doseAdminDatetime - this.client_.datetime0) - Dtzero;
            if (abs(tzero) < eps)
                return
            end
            c = this.correctedCounts(c, tzero);
            [t,c] = shiftNumeric(t, c, Dtzero, false);
            c = this.uncorrectedCounts(c, tzero);
        end
        function c = correctedCounts(this, c, varargin)
            %% CORRECTEDCOUNTS corrects positron decay from zero-time or this.client_.times(1). 
            
            c = this.adjustCounts(c, 1, varargin{:});
        end
        function c = uncorrectedCounts(this, c, varargin)
            %% UNCORRECTEDCOUNTS reintroduces positron decay from zero-time or this.client_.times(1).
            
            c = this.adjustCounts(c, -1, varargin{:});
        end
    end
    
    %% PRIVATE
    
    properties (Access = 'private')
        client_
    end
    
    methods (Access = 'private')        
        function c = adjustCounts(this, varargin)
            %% ADJUSTCOUNTS (un)corrects positron decay from zero-time this.client_.times(1). 
            
            ip = inputParser;
            addRequired(ip, 'c', @isnumeric);
            addRequired(ip, 'sgn', @(x) abs(x) == 1);
            addOptional(ip, 'tzero', 0, @isnumeric);
            parse(ip, varargin{:});            
            if (abs(ip.Results.tzero) < eps)
                c = ip.Results.c;
                return
            end
            if (isa(this.client_, 'mlpet.IScannerData'))
                c = adjustScannerCounts(this, ip.Results.c, ip.Results.sgn, ip.Results.tzero);
                return
            end
            if (isa(this.client_, 'mlpet.IAifData') || isa(this.client_, 'mlpet.IWellData'))
                c = adjustAifCounts(    this, ip.Results.c, ip.Results.sgn, ip.Results.tzero);
                return
            end
            error('mlpet:unsupportedTypeClass', ...
                'DecayCorrection.correctedCounts does not support clients of type %s', class(this.client_));
        end
        function c = adjustAifCounts(this, c, sgn, tzero)
            sgn   = sign(sgn);
            times = this.client_.times - tzero;
            c     = c.*exp(sgn*this.lambdaHalflife*times);
        end
        function c = adjustScannerCounts(this, c, sgn, tzero)
            sgn   = sign(sgn);
            times = this.client_.times - tzero;
            switch (length(size(c)))
                case 2
                    c = c.*exp(sgn*this.lambdaHalflife*times);
                case 3
                    for t = 1:size(c,3)
                        c(:,:,t) = c(:,:,t).*exp(sgn*this.lambdaHalflife*times(t));
                    end
                case 4
                    for t = 1:size(c,4)
                        c(:,:,:,t) = c(:,:,:,t).*exp(sgn*this.lambdaHalflife*times(t));
                    end
                otherwise
                    error('mlpet:unsupportedArraySize', ...
                          'size(DecayCorrection.adjustScannerCounts.cnts) -> %s', mat2str(size(c)));
            end 
        end
        function l = lambdaHalflife(this)
            l = log(2) / this.halfLife;
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

