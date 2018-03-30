classdef Laif2Ecat < mlbayesian.AbstractMcmcProblem 
	%% LAIF2ECAT   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties  		 
        baseTitle = 'Laif2Ecat'
        xLabel    = 'times/s'
        yLabel    = 'arbitrary'
 	end 

    properties (Dependent)
        countsDcv
        map
    end
    
    methods %% GET
        function f = get.countsDcv(this)
            assert(~isempty(this.countsDcv_));
            f = this.countsDcv_;
        end
        function m = get.map(this)            
            m = containers.Map;
            tf = this.timeFinal;
            m('a')   = struct('fixed', 0, 'min',   2,    'mean', this.a,  'max', 16);
            m('d')   = struct('fixed', 0, 'min',   eps,  'mean', this.d,  'max',  3);
            m('p')   = struct('fixed', 0, 'min',   1,    'mean', this.p,  'max',  2); 
            m('q0')  = struct('fixed', 1, 'min',   1,    'mean', this.q0, 'max',  2e7);
            m('t0')  = struct('fixed', 1, 'min',   0,    'mean', this.t0, 'max', tf/2); 
        end
    end    
    
    methods (Static)  
        function this = runAutoradiograph(countsDcv, times, counts)
            this = mlpet.Laif2Ecat(countsDcv, times, counts);
            this = this.estimateParameters(this.map);
        end
        function k    = autoradiograph(a, d, p, q0, t0, times)            
            idx_t0 = mlpet.Laif2Ecat.indexOf(times, t0);  
            
            
            
            cnorm  = q0 * ((p/a^d)/gamma(d/p));
            exp1   = exp(-(times/a).^p);
            k0     = abs(cnorm * times.^(d-1) .* exp1);
            
            k             = zeros(1, length(times));
            k(idx_t0:end) = k0(1:end-idx_t0+1);
            k             = k / sum(k);
            assert(all(isreal(k)), 'BestGammaFluid.simulateDcv.residue was complex');
            assert(~any(isnan(k)), 'BestGammaFluid.simulateDcv.residue was NaN: %s', num2str(k));
        end
        function countsDcv  = dcEcat(inputFunction, a, d, p, q0, t0, times)
            autoradiograph = mlpet.Laif2Ecat.autoradiograph(a, d, p, q0, t0, times);
            countsDcv = abs(conv(inputFunction, autoradiograph));
            countsDcv = countsDcv(1:length(times));
        end
        function this = simulateMcmc(inputFunction, a, d, p, q0, t0, times, map)
            
            import mlpet.*;            
            countsDcv  = Laif2Ecat.dcEcat(inputFunction, a, d, p, q0, t0, times);
            this = Laif2Ecat(inputFunction, times, countsDcv);
            this = this.estimateParameters(map) %#ok<NOPRT>
            
            figure;
            plot(times, this.estimateData, times, countsDcv, 'o');
            legend('Bayesian estimate', 'simulated');
            title(sprintf('simulateMcmc expected:  a->%g, d->%g, p->%g, q0->%g, t0->%g, max(t)->%g', ...
                  a, d, p, q0, t0, max(times)));
            xlabel('time/s');
            ylabel('arbitrary');
        end
    end
    
	methods 		  
 		function this = Laif2Ecat(varargin) 
 			%% LAIF2ECAT 
 			%  Usage:  this = Laif2Ecat() 

 			this = this@mlbayesian.AbstractMcmcProblem(varargin{:}); 
            
 		end 
        function k    = itsAutoradiograph(this)
            k = mlpet.Laif2Ecat.autoradiograph(this.a, this.d, this.p, this.q0, this.t0, this.times);
        end
        function d    = itsDcEcat(this)
            d = mlpet.Laif2Ecat.dcEcat(this.inputFunction, this.a, this.d, this.p, this.q0, this.t0, this.times);
        end
        function this = estimateParameters(this, varargin) 
            ip = inputParser;
            addOptional(ip, 'map', this.map, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            import mlbayesian.*;
            this.paramsManager = BayesianParameters(ip.Results.map);
            this.ensureKeyOrdering({'a' 'd' 'p' 'q0' 't0'});
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.a  = this.finalParams('a');
            this.d  = this.finalParams('d');
            this.p  = this.finalParams('p');
            this.q0 = this.finalParams('q0');
            this.t0 = this.finalParams('t0');
        end
        function ed   = estimateData(this)
            keys = this.paramsManager.paramsMap.keys;
            ed = this.estimateDataFast( ...
                this.finalParams(keys{1}), ...
                this.finalParams(keys{2}), ...
                this.finalParams(keys{3}), ...
                this.finalParams(keys{4}), ...
                this.finalParams(keys{5}));
        end
        function ed   = estimateDataFast(this, a, d, p, q0, t0)  
            ed = this.dcEcat(this.inputFunction_, a, d, p, q0, t0, this.times);
        end 
 	end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        countsDcv_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

