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
    
    properties (Constant)
        N_PARAMS = 5;
    end
    
	properties
        showPlots = true	 
        baseTitle = 'BrainWaterKernel'
        xLabel    = 'times/s'
        yLabel    = 'arbitrary'
        
        a  = 1.274033
        d  = 1.494003
        p  = 0.420199
        q0 = 7568929.630377
        t0 = 8.078686
        
        aS  = 0.4
        dS  = 0.07
        pS  = 0.02
        q0S = 2e5
        t0S = 1
        
        priorN = 1e5
    end 
    
    properties (Dependent)
        map
    end
    
    methods %% GET
        function m = get.map(this)
            m = containers.Map;
            m('a')  = struct('fixed',0,'min',this.prLow(this.a, this.aS, 1),  'mean',this.a, 'max',this.prHigh(this.a, this.aS, this.timeFinal));
            m('d')  = struct('fixed',0,'min',this.prLow(this.d, this.dS, 1),  'mean',this.d, 'max',this.prHigh(this.d, this.dS, 20));
            m('p')  = struct('fixed',0,'min',this.prLow(this.p, this.pS, 0),  'mean',this.p, 'max',this.prHigh(this.p, this.pS,  3)); 
            m('q0') = struct('fixed',0,'min',this.prLow(this.q0,this.q0S,1e5),'mean',this.q0,'max',this.prHigh(this.q0,this.q0S, 1e9));
            m('t0') = struct('fixed',0,'min',this.prLow(this.t0,this.t0S,0),  'mean',this.t0,'max',this.prHigh(this.t0,this.t0S, this.timeFinal)); 
        end
    end
    
    methods (Static)  
        function this = load(laifObj, dcvFn)
            import mlpet.*;
            assert(isa(laifObj, 'mlperfusion.Laif2'));
            dcv  = UncorrectedDCV(dcvFn);
            this = BrainWaterKernel(laifObj.itsKAif0, dcv.timeInterpolants, dcv.countInterpolants);
        end
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
        function dcv  = countsDcv(kAif, a, d, p, q0, t0, times)
            kernel = mlpet.BrainWaterKernel.kernel(a, d, p, t0, times);
            dcv = q0 * abs(conv(kAif, kernel));
            dcv = dcv(1:length(times));
        end
        function this = simulateMcmc(kAif, a, d, p, q0, t0, times, map)
            import mlpet.*;            
            dcv  = BrainWaterKernel.countsDcv(kAif, a, d, p, q0, t0, times);
            this = BrainWaterKernel(kAif, times, dcv);
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
 		function this = BrainWaterKernel(kAif, varargin)
 			%% BRAINWATERKERNEL 
 			%  Usage:  this = BrainWaterKernel(input_function[, dcv_times, dcv_counts]) 
            
 			this = this@mlbayesian.AbstractMcmcProblem(varargin{:});             
            assert(isnumeric(kAif));
 			 
            this.kAif_ = kAif;
            this.expectedBestFitParams_ = ...
                [this.a this.d this.p this.q0 this.t0]';
        end 
        
        function this = simulateItsMcmc(this)
            import mlpet.*;
            this = BrainWaterKernel.simulateMcmc( ...
                   this.itsKAif, this.a, this.d, this.p, this.q0, this.t0, this.times, this.map);
        end
        function aif  = itsKAif(this)
            assert(~isempty(this.kAif_));
            aif = this.kAif_;
        end
        function k    = itsKernel(this)
            k = mlpet.BrainWaterKernel.kernel(this.a, this.d, this.p, this.t0, this.times);
        end
        function this = estimateAll(this)
            this = this.estimateParameters(this.map);
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
            
            if (~this.finalStds('a') < eps)
                this.aS  = this.finalStds('a'); end
            if (~this.finalStds('d') < eps)
                this.dS  = this.finalStds('d'); end
            if (~this.finalStds('p') < eps)
                this.pS  = this.finalStds('p'); end
            if (~this.finalStds('q0') < eps)
                this.q0S = this.finalStds('q0'); end
            if (~this.finalStds('t0') < eps)
                this.t0S = this.finalStds('t0'); end
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
            ed = this.countsDcv(this.kAif_, a, d, p, q0, t0, this.times);
        end 
        function x    = prLow(this, x, xS, inf)
            x = x - this.priorN*xS;
            if (exist('inf','var') && x < inf); x = inf; end
        end
        function x    = prHigh(this, x, xS, sup)
            x = x + this.priorN*xS;
            if (exist('sup','var') && x > sup); x = sup; end
        end
        function        plotInitialData(this)
            figure;
            max_cd = max(this.countsDcv);
            max_dd = max(this.dependentData);
            plot(this.times, this.countsDcv/max_cd, ...
                 this.times, this.dependentData/max_dd);
            title(sprintf('BrainWaterKernel.plotInitialData:  %s', str2pnum(pwd)), 'Interpreter', 'none');
            legend('Bayesian dcv', 'dcv from data');
            xlabel('time/s');
            ylabel(sprintf('arbitrary; rescaled by %g, %g', max_cd, max_dd));
        end
        function        plotProduct(this)
            figure;
            itsDcv = this.countsDcv(this.itsKAif, this.a, this.d, this.p, this.q0, this.t0, this.times);
            plot(this.times, itsDcv, this.times, this.dependentData, 'o');
            legend('Bayesian dcv', 'dcv from data');
            title(sprintf('BrainWaterKernel.plotProduct:  a %g, d %g, p %g, q0 %g, t0 %g', ...
                this.a, this.d, this.p, this.q0, this.t0), 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end        
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlperfusion.BrainWaterKernel')));
            assert(isnumeric(vars));
            switch (par)
                case 'a'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.d  this.p  this.q0 this.t0 }; end
                case 'd'
                    for v = 1:length(vars)
                        args{v} = { this.a  vars(v) this.p  this.q0 this.t0 }; end
                case 'p'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.d  vars(v) this.q0 this.t0 }; end
                case 'q0'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.d  this.p  vars(v) this.t0 }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.d  this.p  this.q0 vars(v) }; end
            end
            this.plotParArgs(par, args, vars);
        end
        function this = save(this)   
            this = this.saveas('BrainWaterKernel.save.mat');
        end
        function this = saveas(this, fn)  
            brainWaterKernel = this; %#ok<NASGU>
            save(fn, 'brainWaterKernel');         
        end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        kAif_
    end
    
    methods (Access = 'private')
        function plotParArgs(this, par, args, vars)
            assert(lstrfind(par, properties('mlpet.BrainWaterKernel')));
            assert(iscell(args));
            assert(isnumeric(vars));
            import mlpet.*;
            figure
            hold on
            for v = 1:size(args,2)
                argsv = args{v};
                plot(this.times, ...
                     BrainWaterKernel.countsDcv( ...
                         this.itsKAif, argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, this.times));
            end
            title(sprintf('a %g, d %g, p %g, q0 %g, t0 %g', ...
                          argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

