classdef BrainWaterKernel < mlbayesian.AbstractMcmcProblem 
	%% BRAINWATERKERNEL
    %  http://en.wikipedia.org/wiki/Generalized_gamma_distribution
    %  N.B.  f(tau; a,d,p) = \Gamma^{-1}(d/p) (p/a^d) tau^(d-1) exp(-(tau/a)^p) with a > 0, d > 0, p > 0, t - t0 > 0.   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$   
    
	properties
        showPlots = true	 
        baseTitle = 'BrainWaterKernel'
        xLabel    = 'times/s'
        yLabel    = 'arbitrary'
        
        a  = 10.833054
        d  = 1.039375
        p  = 0.602907
        q0 = 4746923.420845
        t0 = 0.304061
    end 
    
    properties (Dependent)
        inputFunction
        map
    end
    
    methods %% GET
        function f = get.inputFunction(this)
            assert(~isempty(this.inputFunction_));
            f = this.inputFunction_;
        end
        function m = get.map(this)            
            m = containers.Map;
            tf = this.timeFinal;
            m('a')  = struct('fixed', 0, 'min', 5,   'mean', this.a,  'max', 20);
            m('d')  = struct('fixed', 0, 'min', 0.5, 'mean', this.d,  'max',  2);
            m('p')  = struct('fixed', 0, 'min', 0.3, 'mean', this.p,  'max',  1.5); 
            m('q0') = struct('fixed', 0, 'min', 1e5, 'mean', this.q0, 'max',  1e8);
            m('t0') = struct('fixed', 0, 'min', 0,   'mean', this.t0, 'max', tf/2); 
        end
    end
    
    methods (Static)  
        function this = runKernel(inputFn, times, counts)
            this = mlpet.BrainWaterKernel(inputFn, times, counts);
            this = this.estimateParameters(this.map);
        end
        function k    = kernel(a, d, p, t0, times)            
            idx_t0 = mlpet.BrainWaterKernel.indexOf(times, t0);  
            cnorm  = ((p/a^d)/gamma(d/p));
            exp1   = exp(-(times/a).^p);
            k0     = abs(cnorm * times.^(d-1) .* exp1);
            
            k             = zeros(1, length(times));
            k(idx_t0:end) = k0(1:end-idx_t0+1);
            assert(all(isreal(k)), 'BestGammaFluid.simulateDcv.residue was complex');
            assert(~any(isnan(k)), 'BestGammaFluid.simulateDcv.residue was NaN: %s', num2str(k));
        end
        function dcv  = countsDcv(inputFunction, a, d, p, q0, t0, times)
            kernel = mlpet.BrainWaterKernel.kernel(a, d, p, t0, times);
            dcv = q0 * abs(conv(inputFunction, kernel));
            dcv = dcv(1:length(times));
        end
        function this = simulateMcmc(inputFunction, a, d, p, q0, t0, times, map)
            
            import mlpet.*;            
            dcv  = BrainWaterKernel.countsDcv(inputFunction, a, d, p, q0, t0, times);
            this = BrainWaterKernel(inputFunction, times, dcv);
            this = this.estimateParameters(map) %#ok<NOPRT>
            
            figure;
            plot(times, this.estimateData, times, dcv, 'o');
            legend('Bayesian estimate', 'simulated');
            title(sprintf('simulateMcmc expected:  a->%g, d->%g, p->%g, q0->%g, t0->%g, max(t)->%g', ...
                  a, d, p, q0, t0, max(times)));
            xlabel('time/s');
            ylabel('arbitrary');
        end
    end

	methods 		  
 		function this = BrainWaterKernel(inputFunc, varargin) 
 			%% BRAINWATERKERNEL 
 			%  Usage:  this = BrainWaterKernel(input_function[, dcv_times, dcv_counts]) 
            
 			this = this@mlbayesian.AbstractMcmcProblem(varargin{:});             
            assert(isnumeric(inputFunc));
 			 
            this.inputFunction_ = inputFunc;
            this.expectedBestFitParams_ = ...
                [this.a this.d this.p this.q0 this.t0]';
        end 
        function k    = itsKernel(this)
            k = mlpet.BrainWaterKernel.kernel(this.a, this.d, this.p, this.t0, this.times);
        end
        function d    = itsSimulatedDcv(this)
            d = mlpet.BrainWaterKernel.countsDcv(this.inputFunction, this.a, this.d, this.p, this.q0, this.t0, this.times);
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
            ed = this.countsDcv(this.inputFunction_, a, d, p, q0, t0, this.times);
        end 
    end 
    
    %% PROTECTED

    methods (Static, Access = 'protected')
        function [times,counts] = shiftDataLeft(times0, counts0, Dt)
            idx_0  = floor(sum(double(times0 < Dt + times0(1))));
            times  = times0(idx_0:end);
            times  = times - times(1);
            counts = counts0(idx_0:end);
            counts = counts - min(counts);
        end
        function [times,counts] = shiftDataRight(times0, counts0, Dt)
            lenDt  = ceil(Dt/(times0(2) - times0(1)));
            newLen = length(counts0) + lenDt;
            
            times0 = times0 - times0(1) + Dt;
            times  = [0:1:lenDt-1 times0];
            counts = counts0(1) * ones(1,newLen);            
            counts(end-length(counts0)+1:end) = counts0;
            counts = counts - min(counts);
        end
    end
    
    %% PRIVATE
    
    properties (Access = 'private')
        inputFunction_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

