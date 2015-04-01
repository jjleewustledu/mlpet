classdef PETAutoradiography < mlbayesian.AbstractMcmcProblem 
	%% PETAUTORADIOGRAPHY
    %  Cf:  Raichle, Martin, Herscovitch, Mintun, Markham, 
    %       Brain Blood Flow Measured with Intravenous H_2[^15O].  II.  Implementation and Valication, 
    %       J Nucl Med 24:  790-798, 1983.
    %  Internal units:   mL, cm, g, s

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 
    properties (Constant)
        LAMBDA = 0.95        % brain-blood equilibrium partition coefficient, mL/g
        BRAIN_DENSITY = 1.05 % assumed mean brain density, g/mL
    end
    
	properties 
        showPlots = true	 
        baseTitle = 'PET Autoradiography'
        xLabel    = 'times/s'
        yLabel    = 'concentration/(counts/s/g)'
        
        PS = 1    % cm^3/s/g
        f  = 0.01 % mL/s/g
    end 

    properties (Dependent)
        concentration_a
        map 
    end
    
    methods %% GET/SET
        function ca = get.concentration_a(this)
            assert(~isempty(this.concentration_a_));
            ca = this.concentration_a_;
        end
        function m = get.map(this)            
            m = containers.Map;
            m('PS') = struct('fixed', 0, 'min', this.priorLow(this.PS), 'mean', this.PS, 'max', this.priorHigh(this.PS));
            m('f')  = struct('fixed', 0, 'min', this.priorLow(this.f),  'mean', this.f,  'max', this.priorHigh(this.f));
        end
    end
    
    methods (Static)
        function this = runPETAutoradiography(conc_a, t, conc_i)
            %% RUNPETAUTORADIOGRAPHY
            %  Usage:   PETAutoradiography.runPETAutoradiography(arterial_counts, times, scanner_counts) 
            %                                                     ^counts/s/mL     ^ s    ^ counts/s/g
            
            import mlpet.*;
            this = PETAutoradiography(conc_a, t, conc_i/PETAutoradiography.BRAIN_DENSITY);
            this = this.estimateParameters(this.map);            
            
            figure;
            plot(this.times, o.estimateData, t, conc_i, 'o');
            legend('Bayesian conc_i', 'conc_i from data');
            title(sprintf('PETAutoradiography:  PS %g, f %g', this.PS, this.f));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
        function ci  = concentration_i(PS, f, t, conc_a)
            lambda = mlpet.PETAutoradiography.LAMBDA;
            K  = (1 - exp(-PS/f)) * f / lambda;
            ci = lambda * K * conv(conc_a, exp(-K * t));
            ci = ci(1:length(t));
            assert(all(isfinite(ci)), 'ci -> ', num2str(ci));
        end
        function this = simulateMcmc(PS, f, t, conc_a, map)
            import mlpet.*;       
            conc_i = PETAutoradiography.concentration_i(PS, f, t, conc_a); % simulated
            this   = PETAutoradiography(conc_a, t, conc_i);
            this   = this.estimateParameters(map) %#ok<NOPRT>
            
            figure;
            plot(t, this.estimateData, t, conc_i, 'o');
            legend('Bayesian conc_i', 'simulated conc_i');
            title(sprintf('simulateMcmc expected:  PS %g, f %g', PS, f));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end   
        function f   = mLsg_to_mLmin100g(f)
            f = 100 * 60 * f;
        end
    end
    
	methods 		  
 		function this = PETAutoradiography(conc_a, varargin) 
 			%% PETAUTORADIOGRAPHY 
 			%  Usage:  this = PETAutoradiography(concentration_a, times, concentration_i) 
            %                                    ^counts/s/mL     ^ s    ^ counts/s/g

 			this = this@mlbayesian.AbstractMcmcProblem(varargin{:}); 
            assert(isnumeric(conc_a));
            this.concentration_a_ = conc_a;
            this.expectedBestFitParams_ = [this.PS this.f]';
        end 
        function ci   = itsConcentration_i(this)
            ci = mlpet.PETAutoradiography.concentration_i(this.PS, this.f, this.times, this.concentration_a);
        end
        
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'map', this.map, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            import mlbayesian.*;
            this.paramsManager = BayesianParameters(varargin{:});
            this.ensureKeyOrdering({'PS' 'f'});
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.PS = this.finalParams('PS');
            this.f  = this.finalParams('f');
        end
        function ed = estimateData(this)            
            keys = this.paramsManager.paramsMap.keys;
            ed = this.estimateDataFast( ...
                this.finalParams(keys{1}), ...
                this.finalParams(keys{2}));
        end
        function ed = estimateDataFast(this, PS, f)
            ed = mlpet.PETAutoradiography.concentration_i( ...
                       PS, f, this.times, this.concentration_a);
        end
        function x = priorLow(~, x)
            x = 0.5*x;
        end
        function x = priorHigh(~, x)
            x = 2*x;
        end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        concentration_a_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

