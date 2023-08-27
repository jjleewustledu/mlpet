classdef Radionuclides 
	%% RADIONUCLIDES is a data object providing information specific for nuclear isotopes.

	%  $Revision$
 	%  was created 03-Mar-2017 17:21:28 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    properties (Constant)
        SUPPORTED_ISOTOPES = {'11C' '64Cu' '137Cs' '18F' '68Ga' '68Ge' '124I' '13N' '22Na' '15O' '82Rb' '89Zr'}
    end
    
	properties (Dependent)
        branchingRatio % true_activity := measured_activity / branching_ratio
        decayConstant % legacy synonym for decayRate
        decayRate % \alpha = log(2)/\tau_{1/2}
        halflife
        isotope
        lifetime
        nuclide % legacy synonym for isotope
        tracer_tags
    end
 		
    methods 
        
        %% GET
        
        function g = get.branchingRatio(this)
            % http://www.turkupetcentre.net/petanalysis/branching_ratio.html
            switch (this.isotope)
                case '11C'
                    g = 0.998;
                case '64Cu'
                    g = 0.1752;
                case '18F'
                    g = 0.967;
                case {'68Ga', '68Ge'}
                    g = 0.891;
                case '124I'
                    g = 0.26;
                case '13N'
                    g = 0.998;
                case '22Na'
                    g = 0.9;
                case '15O'
                    g = 0.999;
                case '82Rb'
                    g = 0.95;
                case '89Zr'
                    g = 0.22;
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
        function g = get.tracer_tags(this)
            g = this.tracer_tags_;
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
            %  @param name is text containing one of this.SUPPORTED_ISOTOPES or common tracers.
            %  @throws mlpet:ValueError.

            arguments
                name {mustBeText}
            end
            name = convertStringsToChars(name);
            this.tracer_tags_ = name;

            name = lower(name);
            if any(contains(name,  {'11c','raclopride','s1p1'}, IgnoreCase=true))
                this.isotope_ = '11C';
                return
            end
            if contains(name,  '13n', IgnoreCase=true)
                this.isotope_ = '13N';
                return
            end
            if any(contains(name, {'15o','co','oc','oo','ho'}, IgnoreCase=true))
                this.isotope_ = '15O';
                return
            end
            if any(contains(name,  {'18f','fdg','azan','asem','ro948','mk6240','av','florbeta','vat','tz'}, IgnoreCase=true))
                this.isotope_ = '18F';
                return
            end
            if contains(name,  '22na', IgnoreCase=true)
                this.isotope_ = '22Na';
                return
            end
            if contains(name,  '68ga', IgnoreCase=true)
                this.isotope_ = '68Ga';
                return
            end
            if contains(name,  '68ge', IgnoreCase=true)
                this.isotope_ = '68Ge';
                return
            end
            if contains(name,  '137cs', IgnoreCase=true)
                this.isotope_ = '137Cs';
                return
            end
            %this.isotope_ = '18F'; % ubiquitous default
            error('mlpet:ValueError', 'Radionuclide.ctor.name->%s', name);
        end

        function f = decayCorrectionFactors(this, opts)
            %% DECAYCORRECTIONFACTORS provides decay correction, managing cases for which decay rates are not
            %  small compared to sampling rates.  See also:  https://niftypet.readthedocs.io/en/latest/tutorials/corrqnt.html
            %
            %  this mlpet.Radionuclides
            %  opts.taus double = [] % sampling durations
            %  opts.times double = [] % sampling times, preferably times of mid-point of sampling interval            
            
            arguments
                this mlpet.Radionuclides
                opts.taus double = [] % sampling durations
                opts.times double = [] % sampling times, preferably times of mid-point of sampling interval
            end
            assert(~isempty(opts.taus) || ~isempty(opts.times), ...
                'mlpet.Radionuclides.decayCorrectionFactors requires either times or taus')
            if ~isempty(opts.taus)
                opts.times = cumsum([0 opts.taus]);
            end
            if isempty(opts.taus) && ~isempty(opts.times)
                opts.taus = opts.times(2:end) - opts.times(1:end-1);
            end
            taus_ = opts.taus;
            times_ = opts.times(1:length(taus_));

            if max(taus_)/this.halflife < 1e-6
                f = 2.^(times_/this.halflife);
                return
            end
            
            lambda = this.decayRate;
            f = lambda*taus_./(exp(-lambda*times_).*(1 - exp(-lambda*taus_)));
        end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        isotope_
        tracer_tags_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

