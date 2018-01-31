classdef DecayCorrection < handle
	%% DECAYCORRECTION is a modestly implemented Visitor design pattern for operations on mlpet.{IAifData,IScannerData}
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
        halfLife
        isotope
        nuclide % legacy synonym
    end
    
    methods (Static)
        function this = factoryFor(client)
            if (isa(client, 'mlpet.IScannerData'))
                this = mlpet.DecayCorrectionForScanner(client);
                return
            end            
            if (     isa(client, 'mlpet.IAifData')  || ...
                     isa(client, 'mlpet.IWellData') || ...
                isstruct(client))            
                this = mlpet.DecayCorrectionForAif(client);
                return
            end
            error('mlpet:unsupportedTypeClass', ...
                'DecayCorrection.factoryFor does not support type %s', class(client));
        end
    end
    
    methods 
        
        %% GET
        
        function g = get.decayConstant(this)
            g = this.radionuclide_.decayConstant;
        end
        function g = get.halflife(this)
            g = this.radionuclide_.halflife;
        end
        function g = get.halfLife(this)
            g = this.halflife;
        end
        function g = get.isotope(this)
            g = this.radionuclide_.isotope;
        end
        function g = get.nuclide(this)
            g = this.radionuclide_.nuclide;
        end
    
        %%        

        function c = adjustActivities(this, varargin)
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
                %error('mlpet:unexpectedInputValue', 'DecayCorrection.adjustActivities.tzero->%g', tzero);
                c = ip.Results.c;
                return
            end
            c = adjustClient(this, ip.Results.c, ip.Results.sgn, tzero);
        end
        function c = correctedActivities(this, c, varargin)
            %% CORRECTEDCOUNTS removes effects of positron decay from zero-time or this.client_.time0. 
            %  @param c is counts, activity, specific activity
            %  @param zeroTime is numeric, optional
            
            c = this.adjustActivities(c, 1, varargin{:});
        end
        function c = uncorrectedActivities(this, c, varargin)
            %% UNCORRECTEDCOUNTS reintroduces effects of positron decay from zero-time or this.client_.time0.
            %  @param c is counts, activity, specific activity
            %  @param zeroTime is numeric, optional
            
            c = this.adjustActivities(c, -1, varargin{:});
        end
    end
    
    %% PROTECTED
    
    properties (Access = protected)
        client_
        radionuclide_
    end
    
    methods (Access = protected)
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
        function c = adjustClient(~, varargin) %#ok<STOUT>
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

