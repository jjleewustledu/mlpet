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
        xLabel    = 'times/s'
        yLabel    = 'arbitrary'
        
        a  = 1.2
        d  = 1.3
        p  = 0.40
        q0 = 7.9e6
        t0 = 8.5
        
        aS  = 0.16
        dS  = 0.034
        pS  = 0.010
        q0S = 1.8e5
        t0S = 0.23
        
        priorN = 45
    end 
    
    properties (Dependent)
        baseTitle
        detailedTitle
        map
    end
    
    methods %% GET
        function bt = get.baseTitle(this)
            bt = sprintf('BrainWaterKernel %s', this.pnum);
        end
        function dt = get.detailedTitle(this)
            dt = sprintf('%s:\na %g, d %g, p %g, q0 %g, t0 %g', ...
                         this.baseTitle, this.a, this.d, this.p, this.q0, this.t0);
        end
        function m = get.map(this)
            m = containers.Map;
            m('a')  = struct('fixed',0,'min',this.prLow(this.a, this.aS,  0.8),  'mean',this.a, 'max',this.prHigh(this.a, this.aS,  1.4));
            m('d')  = struct('fixed',0,'min',this.prLow(this.d, this.dS,  1.0),  'mean',this.d, 'max',this.prHigh(this.d, this.dS,  1.5));
            m('p')  = struct('fixed',0,'min',this.prLow(this.p, this.pS,  0.35), 'mean',this.p, 'max',this.prHigh(this.p, this.pS,  0.45)); 
            m('q0') = struct('fixed',0,'min',this.prLow(this.q0,this.q0S, 1e6),  'mean',this.q0,'max',this.prHigh(this.q0,this.q0S, 9e7));
            m('t0') = struct('fixed',0,'min',this.prLow(this.t0,this.t0S, 0),    'mean',this.t0,'max',this.prHigh(this.t0,this.t0S, 20)); 
        end
    end
    
    methods (Static)  
        function this = load(laifObj, dcvFn, dcvShift)
            import mlpet.*;
            assert(isa(laifObj, 'mlperfusion.Laif2'));
            dcv  = UncorrectedDCV(dcvFn);
            args = BrainWaterKernel.interpolateData(laifObj, dcv, dcvShift);
            this = BrainWaterKernel(args{:});
        end
        
        function this = simulateMcmc(kAif, a, d, p, q0, t0, times, map)
            import mlpet.*;            
            dcv  = BrainWaterKernel.concentration_i(kAif, a, d, p, q0, t0, times);
            this = BrainWaterKernel(kAif, times, dcv);
            this = this.estimateParameters(map) %#ok<NOPRT>
        end
        function this = runKernel(kAif, times, counts)
            this = mlpet.BrainWaterKernel(kAif, times, counts);
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
        function dcv  = concentration_i(kAif, a, d, p, q0, t0, times)
            kernel = mlpet.BrainWaterKernel.kernel(a, d, p, t0, times);
            dcv = q0 * abs(conv(kAif, kernel));
            dcv = dcv(1:length(times));
        end
        function args = interpolateData(aif, dcv, dcvShift)
            
            import mlpet.*;
            [t_a,c_a] = AutoradiographyBuilder.shiftData(aif.times, aif.itsKAif_2, -BrainWaterKernel.kAif2Takeoff(aif));
            [t_i,c_i] = AutoradiographyBuilder.shiftData(dcv.times, dcv.counts,     dcvShift); 
            dt  = min(min(aif.taus), min(dcv.taus))/2;
            t   = min(t_a(1), t_i(1)):dt:min([t_a(end) t_i(end) AutoradiographyBuilder.TIME_SUP]);
            c_a = pchip(t_a, c_a, t);
            c_i = pchip(t_i, c_i, t);            
            args = {c_a t c_i};
        end
        function t = kAif2Takeoff(aif)
            assert(isa(aif, 'mlperfusion.ILaif'));
            kA    = aif.itsKAif_2;
            maxKA = max(kA);
            for ti = 2:length(aif.times)
                t = aif.times(ti-1);
                if (kA(ti) > 0.01*maxKA)
                    break;
                end
            end
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
            ed = this.concentration_i(this.kAif_, a, d, p, q0, t0, this.times);
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
            max_cd = max(this.concentration_i);
            max_dd = max(this.dependentData);
            plot(this.times, this.concentration_i/max_cd, ...
                 this.times, this.dependentData/max_dd);
            title(sprintf('BrainWaterKernel.plotInitialData:  %s', str2pnum(pwd)), 'Interpreter', 'none');
            legend('Bayesian dcv', 'dcv from data');
            xlabel('time/s');
            ylabel(sprintf('arbitrary; rescaled by %g, %g', max_cd, max_dd));
        end
        function        plotProduct(this)
            figure;
            itsDcv = this.concentration_i(this.itsKAif, this.a, this.d, this.p, this.q0, this.t0, this.times);
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
                     BrainWaterKernel.concentration_i( ...
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

