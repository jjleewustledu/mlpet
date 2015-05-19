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
        DCV_SHIFT2 = 25
    end
    
	properties
        xLabel = 'times/s'
        yLabel = 'concentration/(well-counts/mL/s)'
        
        a  = 1.09
        d  = 1.08
        n  = 2.04e-4
        p  = 0.375
        q0 = 2.74e6
        t0 = 2.21
        
        aS  = 0.35
        dS  = 0.0013
        nS  = 0.0098
        pS  = 0.0065
        q0S = 7.5e4
        t0S = 0.16
        
        priorN = 1000
    end 
    
    properties (Dependent)
        baseTitle
        detailedTitle
        laif2
        concentration_obs
        map
    end
    
    methods %% GET
        function bt = get.baseTitle(~)
            bt = sprintf('BrainWaterKernel %s', str2pnum(pwd));
        end
        function dt = get.detailedTitle(this)
            dt = sprintf('%s:\na %g, d %g, n %g, p %g, q0 %g, t0 %g', ...
                         this.baseTitle, this.a, this.d, this.n, this.p, this.q0, this.t0);
        end
        function l  = get.laif2(this)
            assert(~isempty(this.laif2_));
            l = this.laif2_;
        end
        function co = get.concentration_obs(this)
            co = this.dependentData;
        end
        function m  = get.map(this)
            m = containers.Map;
            m('a')  = struct('fixed',0,'min',this.priorLow(this.a, this.aS, 0.12),'mean',this.a,    'max',this.priorHigh(this.a, this.aS, 8.5));
            m('d')  = struct('fixed',0,'min',this.priorLow(this.d, this.dS, 0.91),'mean',this.d,    'max',this.priorHigh(this.d, this.dS, 1.8));
            m('n')  = struct('fixed',0,'min',this.priorLow(this.d, this.dS, 1e-5),'mean',0.5*this.n,'max',this.priorHigh(this.n, this.nS, this.n));
            m('p')  = struct('fixed',0,'min',this.priorLow(this.p, this.pS, 0.28),'mean',this.p,    'max',this.priorHigh(this.p, this.pS, 0.67)); 
            m('q0') = struct('fixed',0,'min',this.priorLow(this.q0,this.q0S,1e6), 'mean',this.q0,   'max',this.priorHigh(this.q0,this.q0S, 8e6));
            m('t0') = struct('fixed',0,'min',this.priorLow(this.t0,this.t0S,0),   'mean',this.t0,   'max',this.priorHigh(this.t0,this.t0S,25)); 
        end
    end
    
    methods (Static)  
        function this = load(laifObj, dcvFn, varargin)
            
            ip = inputParser;
            addRequired(ip, 'laifObj',     @(x) isa(x, 'mlperfusion.Laif2'));
            addRequired(ip, 'dcvFn',       @(x) lexist(x, 'file'));
            addOptional(ip, 'dcvShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(ip, laifObj, dcvFn, varargin{:});
            
            import mlpet.*;
            dcv  = UncorrectedDCV(ip.Results.dcvFn);
            args = BrainWaterKernel.interpolateData(ip.Results.laifObj, dcv, ip.Results.dcvShift);
            this = BrainWaterKernel(args{:});
        end
        
        function this = simulateMcmc(laif2, a, d, n, p, q0, t0, t, map)
            import mlpet.*;            
            dcv  = BrainWaterKernel.concentration_i(laif2, a, d, n, p, q0, t0, t);
            this = BrainWaterKernel(laif2, t, dcv);
            this = this.estimateParameters(map) %#ok<NOPRT>
        end
        function this = runAutoradiography(laif2, t, conc_obs)
            this = mlpet.BrainWaterKernel(laif2, t, conc_obs);
            this = this.estimateParameters(this.map);
        end
        function k    = kernel(a, d, p, t0, t)
            idx_t0 = mlpet.BrainWaterKernel.indexOf(t, t0);  
            cnorm  = ((p/a^d)/gamma(d/p));
            exp1   = exp(-(t/a).^p);
            k0     = abs(cnorm * t.^(d-1) .* exp1);
            
            k             = zeros(1, length(t));
            k(idx_t0:end) = k0(1:end-idx_t0+1);
            %assert(all(isreal(k)), 'BestGammaFluid.simulateDcv.residue was complex');
            %assert(~any(isnan(k)), 'BestGammaFluid.simulateDcv.residue was NaN: %s', num2str(k));
        end
        function c_i  = concentration_i(laif2, a, d, n, p, q0, t0, t)
            import mlpet.*;
            c_i = q0 * abs(conv( ...
                           BrainWaterKernel.concentrationBar_a(laif2, n, t), ...
                           BrainWaterKernel.kernel(a, d, p, t0, t)));
            c_i = c_i(1:length(t));
        end
        function cb_a = concentrationBar_a(laif2, n, t)
            cb_a = laif2.kAif_2(laif2.a, laif2.b, n, t, 0, laif2.t1 - laif2.t0);
        end
        function args = interpolateData(laif2, dcv, dcvShift)
            
            import mlpet.*;
            [t_i,c_i] = AutoradiographyBuilder.shiftData(dcv.times, dcv.counts, dcvShift + BrainWaterKernel.DCV_SHIFT2); 
            dt   = min(min(laif2.taus), min(dcv.taus))/2;
            t    = t_i(1):dt:min([t_i(end) AutoradiographyBuilder.TIME_SUP]);
            c_i  = pchip(t_i, c_i, t);            
            args = {laif2 t c_i};
        end      
    end

	methods 		  
 		function this = BrainWaterKernel(laif2, varargin)
 			%% BRAINWATERKERNEL 
 			%  Usage:  this = BrainWaterKernel(Laif2_object[, dcv_times, dcv_counts]) 
            
 			this = this@mlbayesian.AbstractMcmcProblem(varargin{:});
            this.laif2_ = laif2;
            this.n = laif2.n;
            this.expectedBestFitParams_ = ...
                [this.a this.d this.n this.p this.q0 this.t0]';
        end 
        
        function this = simulateItsMcmc(this)
            this = this.simulateMcmc( ...
                   this.laif2, this.a, this.d, this.n, this.p, this.q0, this.t0, this.times, this.map);
        end
        function aif  = itsKAif(this)
            aif = this.itsConcentrationBar_a;
        end
        function cb_a = itsConcentrationBar_a(this)
            cb_a = this.concentrationBar_a(this.laif2, this.n, this.times);
        end
        function ci   = itsConcentration_i(this)
            ci = this.concentration_i( ...
                 this.laif2, this.a, this.d, this.n, this.p, this.q0, this.t0, this.times);
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
            this.ensureKeyOrdering({'a' 'd' 'n' 'p' 'q0' 't0'});
            this.mcmc          = MCMC(this, this.concentration_obs, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.a  = this.finalParams('a');
            this.d  = this.finalParams('d');
            this.n  = this.finalParams('n');
            this.p  = this.finalParams('p');
            this.q0 = this.finalParams('q0');
            this.t0 = this.finalParams('t0');
            
            if (~this.finalStds('a') < eps)
                this.aS  = this.finalStds('a'); end
            if (~this.finalStds('d') < eps)
                this.dS  = this.finalStds('d'); end
            if (~this.finalStds('n') < eps)
                this.dS  = this.finalStds('n'); end
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
                this.finalParams(keys{5}), ...
                this.finalParams(keys{6}));
        end
        function ed   = estimateDataFast(this, a, d, n, p, q0, t0)  
            ed = this.concentration_i(this.laif2, a, d, n, p, q0, t0, this.times);
        end 
        function x    = priorLow(this, x, xS, inf)
            x = x - this.priorN*xS;
            if (exist('inf','var') && x < inf); x = inf; end
        end
        function x    = priorHigh(this, x, xS, sup)
            x = x + this.priorN*xS;
            if (exist('sup','var') && x > sup); x = sup; end
        end
        
        function        plotInitialData(this)
            figure;
            max_a   = max(this.itsConcentrationBar_a);
            max_obs = max(this.concentration_obs);
            plot(this.times, this.itsConcentrationBar_a/max_a, ...
                 this.times, this.concentration_obs/max_obs);
            title(sprintf('%s plotInitialData', this.baseTitle), 'Interpreter', 'none');
            legend('Initial LAIF', 'DCV from data');
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary; rescaled %g, %g', max_a, max_obs));
        end
        function        plotProduct(this)
            figure;
            max_k   = max(this.itsKernel);
            max_dcv = max(max(this.concentration_obs), max(this.itsConcentration_i));
            plot(this.times, this.itsKernel/max_k, ...
                 this.times, this.itsConcentration_i/max_dcv, ...
                 this.times, this.concentration_obs/max_dcv, 'o');
            legend('Bayesian kernel', 'Bayesian DCV', 'DCV from data');
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary: kernel %g, DCV norm %g', max_k, max_dcv));
        end        
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlperfusion.BrainWaterKernel')));
            assert(isnumeric(vars));
            switch (par)
                case 'a'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.d  this.n  this.p  this.q0 this.t0 this.times }; end
                case 'd'
                    for v = 1:length(vars)
                        args{v} = { this.a  vars(v) this.n  this.p  this.q0 this.t0 this.times }; end
                case 'n'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.d  vars(v) this.p  this.q0 this.t0 this.times }; end
                case 'p'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.d  this.n  vars(v) this.q0 this.t0 this.times }; end
                case 'q0'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.d  this.n  this.p  vars(v) this.t0 this.times }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.d  this.n  this.p  this.q0 vars(v) this.times }; end
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
        laif2_
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
                     BrainWaterKernel.concentration_i(argsv{:}));
            end
            title(sprintf('a %g, d %g, n %g, p %g, q0 %g, t0 %g', ...
                          argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

