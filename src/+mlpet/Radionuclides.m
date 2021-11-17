classdef Radionuclides 
	%% RADIONUCLIDES  

	%  $Revision$
 	%  was created 03-Mar-2017 17:21:28 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    properties (Constant)
        SUPPORTED_ISOTOPES = {'11C' '13N' '15O' '18F' '22Na' '68Ga' '68Ge' '137Cs'}
    end
    
	properties (Dependent)
        branchingRatio % true_activity := measured_activity / branching_ratio
        decayConstant % legacy synonym for decayRate
        decayRate % \alpha = log(2)/\tau_{1/2}
        halflife
        isotope
        lifetime
        nuclide % legacy synonym for isotope
    end
 		
    methods 
        
        %% GET
        
        function g = get.branchingRatio(this)
            % http://www.turkupetcentre.net/petanalysis/branching_ratio.html
            switch (this.isotope)
                case '11C'
                    g = 0.998;
                case '13N'
                    g = 0.998;
                case '15O'
                    g = 0.999;
                case '18F'
                    g = 0.967;
                case '22Na'
                    g = 0.9;
                case '68Ga'
                    g = 0.891;
                case '68Ge'
                    g = 0.891;
                otherwise
                    g = nan;
            end
        end
        function g = get.decayConstant(this)
            g = this.decayRate;
        end
        function g = get.decayRate(this)
            g = log(2)/this.halflife;            
        end
        function g = get.halflife(this)
            % wikipedia.org, 2017, in sec
            % https://www.nist.gov/pml/radionuclide-half-life-measurements-data
            % final units in sec
            switch (this.isotope)
                case '11C'
                    g = 20.33424*60; % min * sec/min
                case '13N'
                    g = 9.97*60; % min * sec/min
                case '15O'
                    g = 122.2416;
                case '18F'
                    g = 1.82951 * 3600; % +/- 0.00034 h * sec/h
                case '22Na'
                    g = 950.97 * 86400; % +/-0.15 days * sec/day
                case '68Ga'
                    g = 67.719 * 60; % min * sec/min
                case '68Ge'
                    g = 270.8 * 86400; % days * sec/day
                case '137Cs'
                    g = 11018.386400 * 86400; % +/-9.5 days * sec/day
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
            import mlpet.Radionuclides;
            dc = Radionuclides.decayRateOf(name);
        end
        function dc = decayRateOf(name)
            import mlpet.Radionuclides;
            this = Radionuclides(name);
            dc = this.decayRate;
        end
        function hl = halflifeOf(name)
            import mlpet.Radionuclides;
            this = Radionuclides(name);
            hl = this.halflife;
        end
    end
    
	methods		  
 		function this = Radionuclides(name)
 			%% RADIONUCLIDES
            %  @param name is a string containing one of this.SUPPORTED_ISOTOPES.
            %  @throws mlpet:ValueError.

            assert(ischar(name));
            name = lower(name);
            if (lstrfind(name,  '11c'))
                this.isotope_ = '11C';
                return
            end
            if (lstrfind(name,  '13n'))
                this.isotope_ = '13N';
                return
            end
            if lstrfind(name, '15o') || ...
               lstrfind(name, 'oc') || lstrfind(name, 'co') || ...
               lstrfind(name, 'ho') || lstrfind(name, 'oh') || ...
               lstrfind(name, 'oo')
                this.isotope_ = '15O';
                return
            end
            if lstrfind(name,  '18f') || lstrfind(name, 'fdg')
                this.isotope_ = '18F';
                return
            end
            if (lstrfind(name,  '22na'))
                this.isotope_ = '22Na';
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
            if (lstrfind(name,  '137cs'))
                this.isotope_ = '137Cs';
                return
            end
            error('mlpet:ValueError', 'Radionuclide.ctor.name->%s', name);
        end

        function f = decayCorrectionFactors(this, varargin)
            %% DECAYCORRECTIONFACTORS
            %  @param taus are the frame durations in sec.
            %  @param times are the frame times, starting with start of 1st frame, ending with end of last frame.
            %  @return f is vector with same shape at taus.
            %  See also:  https://niftypet.readthedocs.io/en/latest/tutorials/corrqnt.html
            
            ip = inputParser;
            addParameter(ip, 'taus', [], @isnumeric)
            addParameter(ip, 'times', [], @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            assert(~isempty(ipr.taus) || ~isempty(ipr.times), ...
                'mlpet.Radionuclides.decayCorrectionFactors requires either times or taus')
            if ~isempty(ipr.taus)
                ipr.times = cumsum([0 ipr.taus]);
            end
            if isempty(ipr.taus) && ~isempty(ipr.times)
                ipr.taus = ipr.times(2:end) - ipr.times(1:end-1);
            end
            taus_ = ipr.taus;
            times_ = ipr.times(1:length(taus_));
            
            lambda = this.decayRate;
            f = lambda*taus_./(exp(-lambda*times_).*(1 - exp(-lambda*taus_)));
        end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        isotope_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

