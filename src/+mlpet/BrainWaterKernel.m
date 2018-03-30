classdef BrainWaterKernel < mlpet.AbstractPerfusionProblem
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
        DCV_SHIFT2 = 0
        TIME_SUP = 120 % sec
        USE_RECIRCULATION = false
        INJECTION_RATE = 0.25
    end
    
	properties
        xLabel = 'times/s'
        yLabel = 'concentration/(well-counts/mL)'
        
        %% from mm01-007_p7267
         
%         a  = 0.280722 
%         d  = 1.020942
%         n  = 0
%         p  = 0.272528
%         q0 = 2199633.025287
%         t0 = 0.139836

        %% from LaifTrainer.trainBrainWaterKernel_20150520T024601.log    
        
        a  = 3.59 
        d  = 0.944
        n  = 0
        p  = 0.290
        q0 = 2.26e6
        t0 = 0.110
    end 
    
    properties (Dependent)
        baseTitle
        detailedTitle
        laif2
        aifShift
        dcvShift
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
        function a  = get.aifShift(this)
            assert(~isempty(this.aifShift_));
            a = this.aifShift_;
        end
        function a  = get.dcvShift(this)
            assert(~isempty(this.dcvShift_));
            a = this.dcvShift_;
        end
        function m  = get.map(this) 
            %% GET.MAP from LaifTrainer.trainBrainWaterKernel_20150520T024601.log
            
            m = containers.Map;
            fL = 0.9; fH = 1.1;
            m('a')  = struct('fixed',0,'min',fL*0.280,  'mean',this.a, 'max',fH*7.96);
            m('d')  = struct('fixed',0,'min',fL*0.877,  'mean',this.d, 'max',fH*1.02);
            m('p')  = struct('fixed',0,'min',fL*0.225,  'mean',this.p, 'max',fH*0.535); 
            m('q0') = struct('fixed',0,'min',fL*1.49e6, 'mean',this.q0,'max',fH*4.14e6);
            m('t0') = struct('fixed',0,'min',   0.00932,'mean',this.t0,'max',fH*0.156); 
            
            if (mlpet.BrainWaterKernel.USE_RECIRCULATION)
                m('n') = struct('fixed',1,'min', 0,  'mean',0.5*this.n,'max',this.n);
            else
                m('n') = struct('fixed',1,'min',-eps,'mean',0,         'max',     eps);
            end
        end
    end
    
    methods (Static)  
        function this = load(laifObj, dcvFn, varargin)
            
            ip = inputParser;
            addRequired(ip, 'laifObj',     @(x) isa(x, 'mlperfusion.Laif2'));
            addRequired(ip, 'dcvFn',       @(x) lexist(x, 'file'));
            addOptional(ip, 'aifShift', 0, @(x) isnumeric(x) && isscalar(x));
            addOptional(ip, 'dcvShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(ip, laifObj, dcvFn, varargin{:});
            
            import mlpet.*;
            laif2    = ip.Results.laifObj;
            dcv      = UncorrectedDCV(ip.Results.dcvFn);
            aifShift = ip.Results.aifShift - laif2.t0;
            dcvShift = ip.Results.dcvShift + BrainWaterKernel.DCV_SHIFT2; % NB, concentration_i(...) can only right shift in time
            
            args = BrainWaterKernel.interpolateData(laif2, dcv, aifShift, dcvShift);
            this = BrainWaterKernel(args{:});
            this.aifShift_ = aifShift;
            this.dcvShift_ = dcvShift;
        end
        
        function ci   = concentration_i(a, d, n, p, q0, t0, t, laif2, aifShift)
            import mlpet.*;
            dt  = t(2) - t(1);
            ci = q0 * dt * ...
                  abs(conv(BrainWaterKernel.handInjection( ...
                               t, ...
                               BrainWaterKernel.concentrationBar_a(laif2, n, t, aifShift), ...
                               BrainWaterKernel.INJECTION_RATE), ...
                           BrainWaterKernel.kernel(a, d, p, t0, t)));
            ci = ci(1:length(t));
        end
        function cba  = concentrationBar_a(laif2, n, t, aifShift)
            if (mlpet.BrainWaterKernel.USE_RECIRCULATION)
                cba = laif2.kAif_2(laif2.a, laif2.b, n, t, laif2.t0 + aifShift, laif2.t1 + aifShift);
            else
                cba = laif2.kAif_1(laif2.a, laif2.b,    t, laif2.t0 + aifShift);
            end
        end
        function k    = kernel(a, d, p, t0, t)
            dt = t(2) - t(1);
            k0  = t.^(d-1) .* exp(-(t/a).^p);
            k0  = k0 / (sum(k0) * dt);             
            
            idx_t0 = mlpet.BrainWaterKernel.indexOf(t, t0); 
            k             = zeros(1, length(t));
            k(idx_t0:end) = k0(1:end-idx_t0+1);
        end
        function args = interpolateData(laif2, dcv, aifShift, dcvShift)
            import mlpet.*;
            dt   = min(min(laif2.taus), min(dcv.taus))/2;            
            if (BrainWaterKernel.USE_RECIRCULATION)
                kAif = laif2.itsKAif_2;
            else
                kAif = laif2.itsKAif_1;
            end            
            [t_a,c_a] = BrainWaterKernel.shiftData(laif2.times, kAif,       aifShift);            
            [t_i,c_i] = BrainWaterKernel.shiftData( dcv.times,  dcv.counts, dcvShift);            
            t    = t_i(1):dt:min([t_i(end) BrainWaterKernel.TIME_SUP]);
            c_a  = pchip(t_a, c_a, t);
            c_i  = pchip(t_i, c_i, t);          
            args = {c_a t c_i laif2};
        end
        function this = simulateMcmc(a, d, n, p, q0, t0, t, map, laif2, aifShift)
            import mlpet.*;            
            dcv  = BrainWaterKernel.concentration_i(a, d, n, p, q0, t0, t, laif2, aifShift);
            this = BrainWaterKernel(laif2, t, dcv);
            this = this.estimateParameters(map) %#ok<NOPRT>
        end
    end

	methods
        function cb_a = itsConcentrationBar_a(this)
            cb_a = this.concentrationBar_a(this.laif2, this.n, this.times, this.aifShift);
        end
        function ci   = itsConcentration_i(this)
            ci = this.concentration_i( ...
                 this.a, this.d, this.n, this.p, this.q0, this.t0, ...
                 this.times, this.laif2, this.aifShift);
        end
        function k    = itsKernel(this)
            k = mlpet.BrainWaterKernel.kernel(this.a, this.d, this.p, this.t0, this.times);
        end
        function this = estimateAll(this)
            this = this.estimateParameters(this.map);
            fprintf('FINAL STATS mtt_obs        %g\n',   this.mtt_obs);
            fprintf('FINAL STATS mtt_a          %g\n',   this.mtt_a);
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
            ed = this.concentration_i( ...
                 a, d, n, p, q0, t0, ...
                 this.times, this.laif2, this.aifShift);
        end 
        function this = simulateItsMcmc(this)
            this = this.simulateMcmc( ...
                   this.a, this.d, this.n, this.p, this.q0, this.t0, ...
                   this.times, this.map, this.laif2, this.aifShift);
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
            legend('concentrationBar_a', 'concentration_{obs}');
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary; rescaled %g, %g', max_a, max_obs));
        end
        function        plotProduct(this)
            figure;
            max_k   = max(this.itsKernel);
            max_a   = max(this.itsConcentrationBar_a);
            max_dcv = max(max(this.concentration_obs), max(this.itsConcentration_i));
            plot(this.times, this.itsKernel/max_k, ':', ...
                 this.times, this.itsConcentrationBar_a/max_a, '--',  ...
                 this.times, this.itsConcentration_i/max_dcv, ...
                 this.times, this.concentration_obs/max_dcv, 'o');
            legend('kernel', 'concentrationBar_a', 'concentration_i', 'concentration_obs');
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary; rescaled %g, %g, %g', max_k, max_a, max_dcv));
        end        
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlperfusion.BrainWaterKernel')));
            assert(isnumeric(vars));
            switch (par)
                case 'a'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.d  this.n  this.p  this.q0 this.t0 this.times this.laif2 this.aifShift }; end
                case 'd'
                    for v = 1:length(vars)
                        args{v} = { this.a  vars(v) this.n  this.p  this.q0 this.t0 this.times this.laif2 this.aifShift }; end
                case 'n'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.d  vars(v) this.p  this.q0 this.t0 this.times this.laif2 this.aifShift }; end
                case 'p'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.d  this.n  vars(v) this.q0 this.t0 this.times this.laif2 this.aifShift }; end
                case 'q0'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.d  this.n  this.p  vars(v) this.t0 this.times this.laif2 this.aifShift }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.d  this.n  this.p  this.q0 vars(v) this.times this.laif2 this.aifShift }; end
            end
            this.plotParArgs(par, args, vars);
        end
    end 
    
    %% PROTECTED
    
    methods (Access = 'protected')
 		function this = BrainWaterKernel(conc_a, times_i, conc_i, laif2)
 			%% BRAINWATERKERNEL 
 			%  Usage:  this = BrainWaterKernel(Laif2_object, times_dcv, conc_dcv) 
            
 			this = this@mlpet.AbstractPerfusionProblem(conc_a, times_i, conc_i);
            ip = inputParser;
            addRequired(ip, 'conc_a',  @isnumeric);
            addRequired(ip, 'times_i', @isnumeric);
            addRequired(ip, 'conc_i',  @isnumeric);
            addRequired(ip, 'laif2',   @(x) isa(x, 'mlperfusion.Laif2'));
            parse(ip, conc_a, times_i, conc_i, laif2);   
            
            this.laif2_ = ip.Results.laif2;
            this.n      = laif2.n;
            this.expectedBestFitParams_ = ...
                [this.a this.d this.n this.p this.q0 this.t0]';
        end
    end
    
    %% PRIVATE
    
    properties (Access = 'private')
        laif2_
        aifShift_
        dcvShift_
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

