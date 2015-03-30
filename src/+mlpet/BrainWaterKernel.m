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
    end 
    
    methods (Static)  
        function Dcv  = simulateDcv(inputFunction, a, d, p, q0, t0, times)
            idx_t0 = floor(t0) + 1;            
            cnorm  = q0 * ((p/a^d)/gamma(d/p));
            exp1   = abs(exp(-(times/a).^p));
            Q0     = cnorm * times.^(d-1) .* exp1;
            
            residue             = zeros(1, length(times));
            residue(idx_t0:end) = Q0(1:end-idx_t0+1);
            assert(all(isreal(residue)), 'BestGammaFluid.simulateDcv.residue was complex');
            assert(~any(isnan(residue)), 'BestGammaFluid.simulateDcv.residue was NaN: %s', num2str(residue));
            
            Dcv = conv(inputFunction, residue);
            Dcv = Dcv(1:length(times));
        end
        function this = simulateMcmc(inputFunction, a, d, p, q0, t0, times)
            
            import mlpet.*;            
            dcv  = BrainWaterKernel.simulateDcv(inputFunction, a, d, p, q0, t0, times);
            this = BrainWaterKernel(inputFunction, dcv, times);
            this = this.estimateParameters %#ok<NOPRT>
            
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
 		function this = BrainWaterKernel(inputFunc, dcv, times) 
 			%% BRAINWATERKERNEL 
 			%  Usage:  this = BrainWaterKernel(input_function, dcv_counts, times) 
            
 			this = this@mlbayesian.AbstractMcmcProblem(times, dcv);             
            p = inputParser;
            addRequired(p, 'inputFunc', @isnumeric);
            addRequired(p, 'dcv',       @isnumeric);
            addRequired(p, 'times',     @isnumeric);
            parse(p, inputFunc, dcv, times);
 			 
            this.inputFunction_ = p.Results.inputFunc;
 		end 
        function this = estimateParameters(this)
            %% ESTIMATEDCVPARAMETERS a, d, p, q0, t0
            
            import mlbayesian.*;
            tf = this.timeFinal;
            map = containers.Map;
            map('a')   = struct('fixed', 0, 'min',   2,    'mean',  8.5, 'max', 16);
            map('d')   = struct('fixed', 0, 'min',   0,    'mean',  5.4, 'max',  8);
            map('p')   = struct('fixed', 0, 'min',   0.5,  'mean',  1.1, 'max',  1.5); 
            map('q0')  = struct('fixed', 1, 'min',   1/tf, 'mean',  1,   'max',  2e7);
            map('t0')  = struct('fixed', 1, 'min',   0,    'mean', 0,    'max', tf/2); 

            this.paramsManager = BayesianParameters(map);
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
        end
        function ed   = estimateData(this)
            ed = this.estimateDataFast( ...
                this.finalParams('a'),  this.finalParams('d'), this.finalParams('p'), ...
                this.finalParams('q0'), this.finalParams('t0'));
        end
        function ed   = estimateDataFast(this, a, d, p, q0, t0)  
            ed = this.simulateDcv(this.inputFunction_, a, d, p, q0, t0, this.independentData);
        end 
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        inputFunction_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

