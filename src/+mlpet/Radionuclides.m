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
        decayConstant % \alpha = log(2)/\tau_{1/2}
        halflife
        isotope
        lifetime
        nuclide % legacy synonym
    end
 		
    methods %% GET
        function g = get.decayConstant(this)
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
                case '18F'
                    g = 109.77120*60;
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
            this = mlpet.Radionuclides(name);
            dc = this.decayConstant;
        end
        function hl = halflifeOf(name)
            this = mlpet.Radionuclides(name);
            hl = this.halflife;
        end
    end
    
	methods		  
 		function this = Radionuclides(name)
 			%% RADIONUCLIDES
 			%  Usage:  this = Radionuclides(name)
            %  @param name is a string containing one of:  15O, 13N, 11C, 68Ga, 18F

            name = lower(name);
            assert(ischar(name));
            if (lstrfind(name,  '15o') || ...
                lstrfind(name,   'oo') || lstrfind(name, 'ho') || lstrfind(name, 'oc') || lstrfind(name, 'co'))
                this.isotope_ = '15O';
                return
            end
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
            if (lstrfind(name,  '18f'))
                this.isotope_ = '18F';
                return
            end
            error('mlpet:unsupportedParamValue', 'Radionuclide.ctor.name->%s', name);
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        isotope_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

