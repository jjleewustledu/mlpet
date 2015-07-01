classdef CRVDeconvolution < mlbayesian.AbstractMcmcProblem 
	%% CRVDECONVOLUTION   
    %  http://en.wikipedia.org/wiki/Generalized_gamma_distribution
    %  N.B.  f(tau; a,d,p) = \Gamma^{-1}(d/p) (p/a^d) tau^(d-1) exp(-(tau/a)^p) with a > 0, d > 0, p > 0, t - t0 > 0. 

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
 	 
	properties
        a  =  1.8
        c1 =  0.20
        c2 =  10
        c3 =  0.53
        c4 =  3.4
        d  =  3.8
        p  =  0.89
        q0 =  8.4e4
        t0 = 17
        
        xLabel = 'times/s'
        yLabel = 'concentration/(well-counts/mL)'
    end 

    properties (Dependent)
        baseTitle
        detailedTitle
        map 
        pnum
        
        dccrv
        kernel
    end
    
    methods %% GET/SET
        function p   = get.pnum(~)
            p = str2pnum(pwd);
        end
        function bt  = get.baseTitle(this)
            bt = sprintf('CRV Deconvolution %s', this.pnum);
        end
        function dt  = get.detailedTitle(this)
            dt = sprintf('%s:\na %g, c1 %g, c2 %g, c3 %g, c4 %g, d %g, p %g, q0 %g, t0 %g', ...
                         this.baseTitle, this.a, this.c1, this.c2, this.c3, this.c4, this.d, this.p, this.q0, this.t0);
        end
        function m   = get.map(this)
            fL = 1; 
            fH = 1;
            T  = this.times(end);
            m = containers.Map;
            m('a')  = struct('fixed', 0, 'min',  fL* 1.3, 'mean', this.a,  'max', fH* 2.1); 
            m('c1') = struct('fixed', 0, 'min',      0,   'mean', this.c1, 'max', fH* 0.6);
            m('c2') = struct('fixed', 0, 'min',      5,   'mean', this.c2, 'max', fH* T/2);
            m('c3') = struct('fixed', 0, 'min',  fL* 0.3, 'mean', this.c3, 'max', fH* 0.8);
            m('c4') = struct('fixed', 0, 'min',      0,   'mean', this.c4, 'max', fH* T/2);
            m('d')  = struct('fixed', 0, 'min',  fL* 2.5, 'mean', this.d,  'max', fH* 6.5);
            m('p')  = struct('fixed', 0, 'min',  fL* 0.65,'mean', this.p,  'max', fH* 0.95);
            m('q0') = struct('fixed', 0, 'min',  fL* 1e4, 'mean', this.q0, 'max', fH*12e4);
            m('t0') = struct('fixed', 0, 'min',  fL*13,   'mean', this.t0, 'max', fH* T/2 );
        end
        function d   = get.dccrv(this)
            assert(isa(this.dccrv_, 'mlpet.DecayCorrectedCRV'));
            d = this.dccrv_;
        end
        function k   = get.kernel(this)
            assert(~isempty(this.kernel_));
            k = this.kernel_;
        end
    end
    
    methods (Static)
        function [bsrf1,bsrf2] = solveBsrf(crvFn, hct)
            %% SOLVEBSRF
            %  Usage:  [bsrf_id1, bsrf_id2] = CRVDeconvolution.solveBsrf(crv_filename, Hct)
            
            if (~exist('hct', 'var'))
                hct = 42; end
            if (hct < 1)
                hct = 100*hct; end
            import mlpet.* mlarbelaez.*;
            crv = CRV.load(crvFn);
            [f1, f2] = fileparts(crvFn);
            betadcv = Betadcv3(fullfile(f1, f2));
            betadcv.Hct = hct;
            
            bsrf1 = betadcv.silentBETADCV;
            bsrf1 = bsrf1(1:1920);
            bsrf1 = pchip(CRVDeconvolution.times1920, bsrf1, 1:crv.length);
            
            betadcv.catheterId = 2;
            bsrf2 = betadcv.silentBETADCV;
            bsrf2 = bsrf2(1:1920);
            bsrf2 = pchip(CRVDeconvolution.times1920, bsrf2, 1:crv.length);
        end
        function this = loadCRV(crvFn)
            assert(lexist(crvFn, 'file'));
            import mlpet.*;
            this = CRVDeconvolution( ...
                   DecayCorrectedCRV.load(crvFn));
        end
        function c    = concentrationDCV(a, c1, c2, c3, c4, d, p, q0, t0, t)
            import mlpet.*;
            c = (1-c3) * (1-c1) * q0 * CRVDeconvolution.gammaVariate(a, d, p, t0, t) + ...
                (1-c3) *    c1  * q0 * CRVDeconvolution.gammaVariate(a, d, p, t0+c2, t) + ...
                   c3  *          q0 * CRVDeconvolution.steadyState(c4, t0, t);
        end
        function c    = gammaVariate(a, d, p, t0, t)
            norm   = gamma(d/p) * (p/a^d);
            c0     = abs(t.^(d-1) .* exp(-(t/a).^p)) / norm;  
            idx_t0 = mlpet.CRVDeconvolution.indexOf(t, t0);
            c      = zeros(1, length(t));
            c(idx_t0:end) = c0(1:end-idx_t0+1);
        end
        function c    = steadyState(g, t0, t)
            c0     = (1 - exp(-t/g));
            idx_t0 = mlpet.CRVDeconvolution.indexOf(t, t0);
            c      = zeros(1, length(t));
            c(idx_t0:end) = c0(1:end-idx_t0+1);
        end
        function this = simulateMcmc(a, c1, c2, c3, c4, d, p, q0, t0, t, map, kernel)
            import mlpet.*;       
            pseudoDccrv.times = t;
            pseudoDccrv.wellCounts = ...
                conv(kernel, CRVDeconvolution.concentrationDCV(a, c1, c2, c3, c4, d, p, q0, t0, t)); % simulated
            pseudoDccrv.wellCounts = pseudoDccrv.wellCounts(1:length(t));
            this = CRVDeconvolution(pseudoDccrv);
            this = this.estimateParameters(map) %#ok<NOPRT>
        end
    end
    
	methods
 		function this = CRVDeconvolution(dccrv)
 			%% CRVDECONVOLUTION 
 			%  Usage:  this = CRVDeconvolution(DecayCorrectedCRV_obj)
            
 			this = this@mlbayesian.AbstractMcmcProblem(dccrv.times, dccrv.wellCounts); 			 
            assert(isa(dccrv, 'mlpet.DecayCorrectedCRV'));
            this.dccrv_ = dccrv;
            load(this.kernelBestFilename_);
            kernelBest = bsrf120_id1;
            this.kernel_ = zeros(size(kernelBest));
            this.kernel_(this.kernelRange_) = kernelBest(this.kernelRange_);
            this.kernel_ = this.kernel_ / sum(this.kernel_); 
        end    
        
        function c    = itsConcentrationDCV(this)
            c = this.concentrationDCV(this.a, this.c1, this.c2, this.c3, this.c4, this.d, this.p, this.q0, this.t0, this.dccrv_.times);
        end
        function c    = itsConcentrationDCCRV(this)
            c = this.estimateDataFast(this.a, this.c1, this.c2, this.c3, this.c4, this.d, this.p, this.q0, this.t0);
        end    
        function this = estimateAll(this)
            this = this.estimateParameters(this.map);
        end 
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'map', this.map, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            import mlbayesian.*;
            this.paramsManager = BayesianParameters(varargin{:});
            this.ensureKeyOrdering({'a' 'c1' 'c2' 'c3' 'c4' 'd' 'p' 'q0' 't0'});
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.a  = this.finalParams('a');
            this.c1 = this.finalParams('c1');
            this.c2 = this.finalParams('c2');
            this.c3 = this.finalParams('c3');
            this.c4 = this.finalParams('c4');
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
                this.finalParams(keys{5}), ...
                this.finalParams(keys{6}), ...
                this.finalParams(keys{7}), ...
                this.finalParams(keys{8}));
        end
        function ed   = estimateDataFast(this, a, c1, c2, c3, c4, d, p, q0, t0)
            ed = conv(this.kernel_, this.concentrationDCV(a, c1, c2, c3, c4, d, p, q0, t0, this.times));
            ed = ed(1:length(this.times));
        end
        function this = simulateItsMcmc(this)
            this = this.simulateMcmc( ...
                   this.a, this.c1, this.c2, this.c3, this.c4, this.d, this.p, this.q0, this.t0, this.times, this.map, this.kernel);
        end
        
        function        plotProduct(this)
            figure;
            max_conc = max([max(this.itsConcentrationDCV) max(this.dccrv.wellCounts) max(this.itsConcentrationDCCRV)]);
            plot(this.times,   this.itsConcentrationDCV   / max_conc, ...
                 this.times,   this.itsConcentrationDCCRV / max_conc, ...
                 this.times(1:length(this.kernel)), ...
                               this.kernel                / max(this.kernel), 's', ...
                 this.times,   this.dccrv.wellCounts      / max_conc, 'o');
            legend('estimated DCV',  'estimated DCCRV', 'kernel', 'DCCRV');
            title(this.detailedTitle);
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary:  max(concentration) %g, max(kernel) %g', max_conc, max(this.kernel)));
        end  
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlpet.CRVDeconvolution')));
            assert(isnumeric(vars));
            switch (par)
                case 'a'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.c1 this.c2 this.c3 this.c4 this.d  this.p  this.q0 this.t0 this.times }; end
                case 'c1'
                    for v = 1:length(vars)
                        args{v} = { this.a  vars(v) this.c2 this.c3 this.c4  this.d  this.p  this.q0 this.t0 this.times }; end
                case 'c2'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.c1 vars(v) this.c3 this.c4  this.d  this.p  this.q0 this.t0 this.times }; end
                case 'c3'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.c1 this.c2 vars(v) this.c4  this.d  this.p  this.q0 this.t0 this.times }; end
                case 'c4'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.c1 this.c2 this.c3 vars(v)  this.d  this.p  this.q0 this.t0 this.times }; end
                case 'd'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.c1 this.c2 this.c3 this.c4  vars(v) this.p  this.q0 this.t0 this.times }; end
                case 'p'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.c1 this.c2 this.c3 this.c4  this.d  vars(v) this.q0 this.t0 this.times }; end
                case 'q0'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.c1 this.c2 this.c3 this.c4  this.d  this.p  vars(v) this.t0 this.times }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.a  this.c1 this.c2 this.c3 this.c4  this.d  this.p  this.q0 vars(v) this.times }; end
            end
            this.plotParArgs(par, args, vars);
        end
        function this = save(this)
            this = this.saveas(sprintf('%s.save.mat', class(this)));
        end
        function this = saveas(this, fn)
            crvDeconvolution = this; %#ok<NASGU>
            save(fn, 'crvDeconvolution');   
        end
    end
    
    %% PRIVATE
    
    properties (Access = 'private')
        dccrv_
        kernel_
        kernelRange_ = 1:120 %12:40
        kernelBestFilename_ = '/Volumes/SeagateBP3/cvl/np755/Training/bsrf120_id1.mat'
                             %'/Volumes/InnominateHD2/Arbelaez/GluT/p8425/scan1/bsrf120.mat'
                             %'/Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez/kernelBest.mat'
                             %'/Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez/kernel57.mat'
    end
    
    methods (Static, Access = 'private')
        function t = times1920            
            t = zeros(1920,1);
            for idxt = 1:1920
                t(idxt) = 1 + (idxt-1)*(119/1919); 
            end
        end
    end
    
    methods (Access = 'private')  
        function plotParArgs(this, par, args, vars)
            assert(lstrfind(par, properties('mlpet.CRVDeconvolution')));
            assert(iscell(args));
            assert(isnumeric(vars));
            import mlpet.*;
            figure
            hold on
            for v = 1:size(args,2)
                argsv = args{v};
                ordinate = CRVDeconvolution.concentrationDCV(argsv{:});
                if (strcmp('q0', par))
                    plot(this.times, ordinate);
                else
                    plot(this.times, ordinate/max(ordinate));
                end
            end
            title(sprintf('a %g, c1 %g, c2 %g, c3 %g, c4 %g, d %g, p %g, q0 %g, t0 %g', ...
                          argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}, argsv{7}, argsv{8}, argsv{9}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(['normalized ' this.yLabel]);
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

