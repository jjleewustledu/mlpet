classdef DecayCorrection
	%% DECAYCORRECTION.
    %  Method functions corrected* uncorrected* adjust* are synonyms.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$  	 
    
    
    properties (Dependent)
        decayConstant % \alpha = log(2)/\tau_{1/2}
        halflife
        isotope
        nuclide % legacy synonym
    end
    
    methods 
        
        %% GET
        
        function g = get.decayConstant(this)
            g = this.radionuclide_.decayConstant;
        end
        function g = get.halflife(this)
            g = this.radionuclide_.halflife;
        end
        function g = get.isotope(this)
            g = this.radionuclide_.isotope;
        end
        function g = get.nuclide(this)
            g = this.radionuclide_.nuclide;
        end
    
        %%
        
        function c = adjustActivities(this, varargin)
            %% ADJUSTACTIVITIES (un)corrects positron decay from zero-time or this.client_.time0. 
            
            c = this.adjustCounts(varargin{:});
        end
        function c = adjustCounts(this, varargin)
            %% ADJUSTCOUNTS (un)corrects positron decay from zero-time or this.client_.time0. 
            %  @param c is counts, activity, specific activity
            %  @param sgn is the sign of the adjustment 2^{sgn*t/t_halflife}
            %  @param tzero is the timepoint for the reference activity
            
            ip = inputParser;
            addRequired(ip, 'c', @isnumeric);
            addRequired(ip, 'sgn', @(x) abs(x) == 1);
            addOptional(ip, 'tzero', this.client_.time0, @(x) isnumeric(x) || isdatetime(x));
            parse(ip, varargin{:});
            tzero = ip.Results.tzero;
            if (isdatetime(tzero))
                tzero = seconds(tzero - this.client_.datetime0);                
            end
            
            if (abs(tzero) < eps)
                error('mlpet:unexpectedInputValue', 'DecayCorrection.adjustCounts.tzero->%g', tzero);
                %c = ip.Results.c;
                %return
            end
            if (isa(this.client_, 'mlpet.IScannerData'))
                c = adjustScannerCounts(this, ip.Results.c, ip.Results.sgn, tzero);
                return
            end
            if (isa(this.client_, 'mlpet.IAifData') || isa(this.client_, 'mlpet.IWellData') || isstruct(this.client_))
                c = adjustAifCounts(    this, ip.Results.c, ip.Results.sgn, tzero);
                return
            end
            error('mlpet:unsupportedTypeClass', ...
                'DecayCorrection.correctedCounts does not support clients of type %s', class(this.client_));
        end
        function c = correctedActivities(this, c, varargin)
            %% CORRECTEDACTIVITIES removes effects of positron decay from zero-time or this.client_.time0. 
            %  @param c is counts, activity, specific activity
            %  @param zeroTime is numeric, optional
            
            c = this.correctedCounts(c, varargin{:});
        end
        function c = correctedCounts(this, c, varargin)
            %% CORRECTEDCOUNTS removes effects of positron decay from zero-time or this.client_.time0. 
            %  @param c is counts, activity, specific activity
            %  @param zeroTime is numeric, optional
            
            c = this.adjustCounts(c, 1, varargin{:});
        end
        function c = uncorrectedActivities(this, c, varargin)
            %% UNCORRECTEDACTIVITIES removes effects of positron decay from zero-time or this.client_.time0. 
            %  @param c is counts, activity, specific activity
            %  @param zeroTime is numeric, optional
            
            c = this.uncorrectedCounts(c, varargin{:});
        end
        function c = uncorrectedCounts(this, c, varargin)
            %% UNCORRECTEDCOUNTS reintroduces effects of positron decay from zero-time or this.client_.time0.
            %  @param c is counts, activity, specific activity
            %  @param zeroTime is numeric, optional
            
            c = this.adjustCounts(c, -1, varargin{:});
        end
        
        function this = DecayCorrection(varargin)
            %% DECAYCORRECTION
 			%  @param client is IAifData_obj | IWellData_obj | struct.
            %  struct should have at minimum fields:  isotope, time0, times, counts.

            ip = inputParser;
            addRequired( ip, 'client',  @(x) isa(x, 'mlpet.IScannerData') || ...
                                             isa(x, 'mlpet.IAifData') || ...
                                             isa(x, 'mlpet.IWellData') || ...
                                             isstruct(x));
            parse(ip, varargin{:});
            
            this.client_ = ip.Results.client;
            this.radionuclide_ = mlpet.Radionuclides(this.client_.isotope);
        end
    end
    
    %% PRIVATE
    
    properties (Access = 'private')
        client_
        radionuclide_
    end
    
    methods (Access = 'private')        
        function c = adjustAifCounts(this, c, sgn, tzero)
            sgn   = sign(sgn);
            times = this.client_.times - tzero;
            c     = c.*exp(sgn*this.decayConstant*times);
        end
        function c = adjustScannerCounts(this, c, sgn, tzero)
            sgn   = sign(sgn);
            times = this.client_.times - tzero;
            switch (length(size(c)))
                case 2
                    c = c.*exp(sgn*this.decayConstant*times);
                case 3
                    for t = 1:size(c,3)
                        c(:,:,t) = c(:,:,t).*exp(sgn*this.decayConstant*times(t));
                    end
                case 4
                    for t = 1:size(c,4)
                        c(:,:,:,t) = c(:,:,:,t).*exp(sgn*this.decayConstant*times(t));
                    end
                otherwise
                    error('mlpet:unsupportedArraySize', ...
                          'size(DecayCorrection.adjustScannerCounts.cnts) -> %s', mat2str(size(c)));
            end 
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

