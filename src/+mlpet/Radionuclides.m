classdef Radionuclides 
	%% RADIONUCLIDES  

	%  $Revision$
 	%  was created 03-Mar-2017 17:21:28 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    properties (Constant)
        SUPPORTED_ISOTOPES = {'15O' '13N' '11C' '68Ga' '18F'}
    end
    
	properties (Dependent)
        decayConstant % legacy synonym for decayRate
        decayRate % \alpha = log(2)/\tau_{1/2}
        halflife
        isotope
        lifetime
        nuclide % legacy synonym for isotope
    end
 		
    methods %% GET
        function g = get.decayConstant(this)
            g = this.decayRate;
        end
        function g = get.decayRate(this)
            g = log(2)/this.halflife;            
        end
        function g = get.halflife(this)
            % wikipedia.org, 2017, in sec
            switch (this.isotope)
                case '15O'
                    g = 122.2416;
                case '13N'
                    g = 9.97*60;
                case '11C'
                    g = 20.33424*60;
                case '68Ga'
                    g = 67.719*60;
                case '68Ge'
                    g = 270.8*86400; % days * (sec/day)
                case '18F'
                    g = 109.77120*60;
                case '22Na'
                    g = 2.6018*365.2422*86400; % years * (days/year) * (sec/day)
                otherwise
                    g = nan;
            end
        end
        function g = get.isotope(this) 
            g = this.isotope_;          
        end
        function g = get.lifetime(this)
            g = 10*this.halflife;
        end
        function g = get.nuclide(this)
            g = this.isotope;
        end
    end

    methods (Static)
        function dc = decayConstantOf(name)
            dc = mlpet.Radionuclides.decayRateOf(name);
        end
        function dc = decayRateOf(name)
            this = mlpet.Radionuclides(name);
            dc = this.decayRate;
        end
        function hl = halflifeOf(name)
            this = mlpet.Radionuclides(name);
            hl = this.halflife;
        end
    end
    
	methods		  
 		function this = Radionuclides(name)
 			%% RADIONUCLIDES
            %  @param name is a string containing one of:  15O, 13N, 11C, 68Ga, 68Ge, 18F, 22Na; FDG, HO, OO, OC, CO.
            %  @throws mlpet:ValueError.

            assert(ischar(name));
            name = lower(name);
            if (lstrfind(name,  '13n'))
                this.isotope_ = '13N';
                return
            end
            if (lstrfind(name,  '11c'))
                this.isotope_ = '11C';
                return
            end
            if (lstrfind(name,  '68ga'))
                this.isotope_ = '68Ga';
                return
            end
            if (lstrfind(name,  '68ge'))
                this.isotope_ = '68Ge';
                return
            end
            if (lstrfind(name,  '18f') || lstrfind(name, 'fdg'))
                this.isotope_ = '18F';
                return
            end
            if (lstrfind(name,  '22na'))
                this.isotope_ = '22Na';
                return
            end
            if (lstrfind(name,  '15o') || ...
                lstrfind(name,   'oo') || lstrfind(name, 'ho') || lstrfind(name, 'oc') || lstrfind(name, 'co'))
                this.isotope_ = '15O';
                return
            end
            error('mlpet:ValueError', 'Radionuclide.ctor.name->%s', name);
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        isotope_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

