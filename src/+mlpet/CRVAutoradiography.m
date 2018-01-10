classdef CRVAutoradiography < mlpet.AutoradiographyBuilder2
	%% CRVAUTORADIOGRAPHY estimates parameters for the Kety autoradiographic method for PET.
    %  It fits ECAT, CRV and, optionally, DCV data.  A data-derived catheter impulse response is needed.
    %  Dcv is estimated by two generalized gamma-variates + steady-state.
    %
    %  Cf:  Raichle, Martin, Herscovitch, Mintun, Markham, 
    %       Brain Blood Flow Measured with Intravenous H_2[^15O].  II.  Implementation and Valication, 
    %       J Nucl Med 24:790-798, 1983.
    %       Hescovitch, Raichle, Kilbourn, Welch,
    %       Positron Emission Tomographic Measurement of Cerebral Blood Flow and Permeability-Surface Area Product of
    %       Water Using [15O]Water and [11C]Butanol, JCBFM 7:527-541, 1987.
    %  Internal units:   mL, cm, g, s

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b).  Copyright 2014 John Joowon Lee. 
 	%  $Id$ 
    
    properties (Constant)
        MODEL_HERSCOVITCH = true
    end
    
    properties
        noPlotting = false
        kernelBestFilename = 'kernelBest.mat'
        
        A0 = 0.01
        Ew = 0.8964
        PS = 0.03169 
        T0 = 0.5730        
        a  =  1.8
        c1 =  0.20
        c2 = 10
        c3 =  0.53
        c4 =  3.4
        d  =  3.8
        f  =  0.00730699976432019
        p  =  0.89
        q0 =  8.4e4
        t0 =  0
    end

    properties (Dependent)
        A1
        baseTitle
        detailedTitle
        map        
        kernel        
        kernelBestFqfilename %'/Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez/kernelBest.mat'        
                             %'/Volumes/SeagateBP3/cvl/np755/Training/bsrf116_id1.mat'
                             %'/Volumes/InnominateHD2/Arbelaez/GluT/__p8425_JJL__/PET/bsrf120.mat'
                             %'/Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez/kernel57.mat'
                             %'/Volumes/SeagateBP4/Arbelaez.kernelBest.mat'
    end
    
    methods %% GET/SET 
        function fn   = get.kernelBestFqfilename(this)
            fn = fullfile(getenv('ARBELAEZ'), this.kernelBestFilename);
        end
        function a1   = get.A1(this)
            if (this.MODEL_HERSCOVITCH)
                a1 = this.PS;
            else
                a1 = this.Ew;
            end
        end
        function this = set.A1(this, a1)
            if (this.MODEL_HERSCOVITCH)
                this.PS = a1;
            else
                this.Ew = a1;
            end
        end
        function bt   = get.baseTitle(this)
            bt = sprintf('%s %s', class(this),this.pnum);
        end
        function dt   = get.detailedTitle(this)
            dt = sprintf('%s:\nA0 %g, A1 %g, T0 %g, \na %g, c1 %g, c2 %g, c3 %g, c4 %g, \nd %g, f %g, p %g, q0 %g, t0 %g', ...
                         this.baseTitle,  this.A0, this.A1, this.T0, ...
                         this.a, this.c1, this.c2, this.c3, this.c4, ...
                         this.d, this.f,  this.p,  this.q0, this.t0);
        end
        function m    = get.map(this)
            %% GET.MAP from AutoradiographyTrainer.trainPET_20150520T193221.log
            
            fL = 1; fH = 1;
            T  = this.times(end);
            m = containers.Map;
            m('A0') = struct('fixed', 0, 'min', fL* 0.0098,   'mean', this.A0, 'max', fH* 0.04);
            if (this.MODEL_HERSCOVITCH) % physiologic ranges, Herscovitch, JCBFM 7:527-541, 1987, table 2.
            m('A1') = struct('fixed', 0, 'min',     0.009275, 'mean', this.PS, 'max',     0.03675);
            else
            m('A1') = struct('fixed', 0, 'min',     0.79,     'mean', this.Ew, 'max',     0.93);
            end
            m('T0') = struct('fixed', 0, 'min',     0.06,     'mean', this.T0, 'max', fH* T/2);  
            m('a')  = struct('fixed', 0, 'min', fL* 1.6,      'mean', this.a,  'max', fH* 2.1); 
            m('c1') = struct('fixed', 0, 'min',     0,        'mean', this.c1, 'max', fH* 0.7);
            m('c2') = struct('fixed', 0, 'min',     5,        'mean', this.c2, 'max', fH* T/4);
            m('c3') = struct('fixed', 0, 'min', fL* 0.4,      'mean', this.c3, 'max', fH* 0.8);
            m('c4') = struct('fixed', 0, 'min',     0.1,      'mean', this.c4, 'max', fH* T/4);
            m('d')  = struct('fixed', 0, 'min', fL* 3,        'mean', this.d,  'max', fH* 6);
            m('f')  = struct('fixed', 0, 'min',     0.004305, 'mean', this.f,  'max', 1.5*0.01229); % physiologic range, Herscovitch, JCBFM 7:527-541, 1987, table 2.
            m('p')  = struct('fixed', 0, 'min', fL* 0.7,      'mean', this.p,  'max', fH* 1);
            m('q0') = struct('fixed', 0, 'min', fL* 1e3,      'mean', this.q0, 'max', fH*12e4);
            m('t0') = struct('fixed', 0, 'min',     0,        'mean', this.t0, 'max', fH* T/4 );
        end
        function k    = get.kernel(this)
            assert(~isempty(this.kernel_));
            k = this.kernel_;
        end
    end
    
    methods (Static)
        function this = load(ecatFn, crvFn, dcvFn, maskFn, varargin)
            ip = inputParser;
            addRequired( ip, 'ecatFn', @(x) lexist(x, 'file'));
            addRequired( ip, 'crvFn',  @(x) lexist(x, 'file'));
            addRequired( ip, 'dcvFn',  @(x) ischar(x));
            addRequired( ip, 'maskFn', @(x) lexist(x, 'file'));
            addParameter(ip, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            addParameter(ip, 'crvShift',  0, @(x) isnumeric(x) && isscalar(x));
            addParameter(ip, 'dcvShift',  0, @(x) isnumeric(x) && isscalar(x));
            addParameter(ip, 'pie',      [], @isnumeric);
            parse(ip, ecatFn, crvFn, dcvFn, maskFn, varargin{:});
            
            import mlfourd.* mlpet.*;
            CRVAutoradiography.reportLoading( ...
                ip.Results.ecatFn, ip.Results.crvFn, ip.Results.dcvFn, ip.Results.maskFn, ...
                sprintf('ecatShift %g', ip.Results.ecatShift), ...
                sprintf('crvShift %g', ip.Results.crvShift), ...
                sprintf('dcvShift %g', ip.Results.dcvShift));
            ecatObj = CRVAutoradiography.loadEcat(ip.Results.ecatFn, 'pie', ip.Results.pie); 
            crvObj  = CRVAutoradiography.loadCrv( ip.Results.crvFn); 
            dcvObj  = [];
            if (lexist(ip.Results.dcvFn, 'file'))
                dcvObj = CRVAutoradiography.loadDcv( ip.Results.dcvFn); 
            end
            maskObj = CRVAutoradiography.loadMask(ip.Results.maskFn);
            args = CRVAutoradiography.interpolateData( ...
                ecatObj, crvObj, dcvObj, maskObj, ...
                ip.Results.ecatShift, ip.Results.crvShift, ip.Results.dcvShift);
            this = CRVAutoradiography(args{:});
        end
        function dcv  = loadDcv(varargin)
            ip = inputParser;
            addOptional(ip, 'fqfn',      [], @(x) lexist(x, 'file'));
            addOptional(ip, 'iwelldata', [], @(x) isa(x, 'mlpet.IWellData'));
            parse(ip, varargin{:});
            
            if (~isempty(ip.Results.fqfn))
                dcv = mlpet.DCV.load(ip.Results.fqfn);
                return
            end
            if (~isempty(ip.Results.iwelldata))
                dcv = ip.Results.iwelldata;
                return
            end
            error('mlpet:requiredObjectNotFound', 'CRVAutoradiography.loadDcv');
        end
        function aif  = loadCrv(varargin)
            ip = inputParser;
            addOptional(ip, 'fqfn',      [], @(x) lexist(x, 'file'));
            addOptional(ip, 'iwelldata', [], @(x) isa(x, 'mlpet.IWellData'));
            parse(ip, varargin{:});
            
            if (~isempty(ip.Results.fqfn))
                aif = mlpet.CRV.load(ip.Results.fqfn);
                return
            end
            if (~isempty(ip.Results.iwelldata))
                aif = ip.Results.iwelldata;
                return
            end
            error('mlpet:requiredObjectNotFound', 'CRVAutoradiography.loadCrv');
        end
        
        function cdcv = concentration_dcv(a, c1, c2, c3, c4, d, p, q0, t0, t)
            import mlpet.*;
            cdcv = (1-c3) * (1-c1) * q0 * CRVAutoradiography.gammaVariate(a, d, p, t0, t) + ...
                   (1-c3) *    c1  * q0 * CRVAutoradiography.gammaVariate(a, d, p, t0+c2, t) + ...
                      c3  *          q0 * CRVAutoradiography.steadyState(c4, t0, t);
        end
        function cdcv = concentration_ucdcv(a, c1, c2, c3, c4, d, p, q0, t0, t)
            import mlpet.*;
            cdcv = (1-c3) * (1-c1) * q0 * CRVAutoradiography.gammaVariate(a, d, p, t0, t) + ...
                   (1-c3) *    c1  * q0 * CRVAutoradiography.gammaVariate(a, d, p, t0+c2, t) + ...
                      c3  *          q0 * CRVAutoradiography.steadyState(c4, t0, t);
            cdcv = cdcv .* exp(-LAMBDA_DECAY * t); 
        end
        function ccrv = concentration_crv(conc_ucdcv, kernel)
            ccrv = conv(conc_ucdcv, kernel);
            ccrv = ccrv(1:length(conc_ucdcv));
        end
        function ci   = concentration_ecat(A0, A1, T0, f, t, conc_a)
            import mlpet.*;
            lambda       = CRVAutoradiography.LAMBDA;
            lambda_decay = LAMBDA_DECAY;
            if (           CRVAutoradiography.MODEL_HERSCOVITCH); A1 = 1 - exp(-A1 / f); end
            ci0 = A0 * A1 * f * conv(conc_a, exp(-(A1 * f / lambda + lambda_decay) * t));
            ci0 = ci0(1:length(t));
            
            idx_t0 = CRVAutoradiography.indexOf(t, T0);
            ci     = zeros(1, length(t));
            ci(idx_t0:end) = ci0(1:end-idx_t0+1);
            ci     = abs(ci);
        end
        function args = interpolateData(ecatObj, crvObj, dcvObj, maskObj, ecatShift, crvShift, dcvShift)
            ecatObj        = ecatObj.masked(maskObj);
            ecatSkinny     = ecatObj.volumeSummed;  
            ecatSkinny.img = ecatSkinny.img/maskObj.count;
            
            import mlpet.*;
            [t_e,c_e] = CRVAutoradiography.shiftData(ecatSkinny.times, ecatSkinny.activity, ecatShift);
            [t_c,c_c] = CRVAutoradiography.shiftData(    crvObj.times,     crvObj.wellCounts, crvShift);   
            
            if (isempty(dcvObj))
                dt  = min([min(crvObj.taus) min(ecatSkinny.taus)]);
                t   = min([t_c(1) t_e(1)]):dt:min([t_c(end) t_e(end) CRVAutoradiography.TIME_SUP]);
                c_e = CRVAutoradiography.myPchip(t_e, c_e, t); 
                c_c = CRVAutoradiography.myPchip(t_c, c_c, t); 
                c_d = [];
            else
                dt  = min([min(dcvObj.taus) min(crvObj.taus) min(ecatSkinny.taus)]);
                t   = min([t_c(1) t_e(1)]):dt:min([t_c(end) t_e(end) CRVAutoradiography.TIME_SUP]);
                c_e = CRVAutoradiography.myPchip(t_e, c_e, t); 
                c_c = CRVAutoradiography.myPchip(t_c, c_c, t); 
                [t_d,c_d] = CRVAutoradiography.shiftData(    dcvObj.times,     dcvObj.wellCounts, dcvShift);
                c_d = CRVAutoradiography.myPchip(t_d, c_d, t);
            end
            args = {t c_e c_c c_d maskObj};
        end
    end
    
	methods
 		function this = CRVAutoradiography(varargin)
 			%% CRVAUTORADIOGRAPHY 

 			this = this@mlpet.AutoradiographyBuilder2(varargin{:});            
            this = this.loadKernel;
            this.expectedBestFitParams_ = ...
                [this.A0 this.A1 this.T0 ...
                 this.a  this.c1 this.c2 this.c3 this.c4 this.d this.f this.p this.q0 this.t0]'; % initial expected values from properties
            this.reportInitial;
        end
        
        function ci   = itsConcentration_ecat(this)
            ci = this.concentration_ecat( ...
                 this.A0, this.A1, this.T0, this.f, this.times, this.itsConcentration_ucdcv);
        end
        function c    = itsConcentration_crv(this)
            c = this.concentration_crv(this.itsConcentration_ucdcv, this.kernel);
        end
        function c    = itsConcentration_dcv(this)
            c = this.concentration_dcv(this.a, this.c1, this.c2, this.c3, this.c4, this.d, this.p, this.q0, this.t0, this.times);
        end
        function c    = itsConcentration_ucdcv(this)
            c = this.concentration_ucdcv(this.a, this.c1, this.c2, this.c3, this.c4, this.d, this.p, this.q0, this.t0, this.times);
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'map', this.map, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            import mlbayesian.*;
            this.paramsManager = BayesianParameters(varargin{:});
            this.ensureKeyOrdering({'A0' 'A1' 'T0' 'a' 'c1' 'c2' 'c3' 'c4' 'd' 'f' 'p' 'q0' 't0'});
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);            
            fprintf('CRVAutoradiography.estimateParameters.this:  '); disp(this);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.A0 = this.finalParams('A0');
            this.A1 = this.finalParams('A1');
            this.T0 = this.finalParams('T0');
            this.a  = this.finalParams('a');
            this.c1 = this.finalParams('c1');
            this.c2 = this.finalParams('c2');
            this.c3 = this.finalParams('c3');
            this.c4 = this.finalParams('c4');
            this.d  = this.finalParams('d');
            this.f  = this.finalParams('f');
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
                this.finalParams(keys{8}), ...
                this.finalParams(keys{9}), ...
                this.finalParams(keys{10}), ...
                this.finalParams(keys{11}), ...
                this.finalParams(keys{12}), ...
                this.finalParams(keys{13}));
        end
        function ed   = estimateDataFast(this, A0, A1, T0, a, c1, c2, c3, c4, d, f, p, q0, t0)
            ed = this.concentration_ecat( ...
                     A0, A1, T0, f, this.times, ...
                         this.concentration_ucdcv(a, c1, c2, c3, c4, d, p, q0, t0, this.times));
        end
        function ec   = estimateCrvFast( this, ~,  ~,  ~,  a, c1, c2, c3, c4, d, ~, p, q0, t0)
            ec = this.concentration_crv( ...
                 this.concentration_ucdcv(a, c1, c2, c3, c4, d, p, q0, t0, this.times), this.kernel);
        end
        function ed   = estimateDcvFast( this, ~,  ~,  ~,  a, c1, c2, c3, c4, d, ~, p, q0, t0)
            ed = this.concentration_dcv(a, c1, c2, c3, c4, d, p, q0, t0, this.times);
        end        
        function ps   = adjustParams(this, ps)
            if (~this.MODEL_HERSCOVITCH); return; end
            manager = this.paramsManager;
            if (ps(manager.paramsIndices('f'))  > ps(manager.paramsIndices('A1')))
                tmp                             = ps(manager.paramsIndices('A1'));
                ps(manager.paramsIndices('A1')) = ps(manager.paramsIndices('f'));
                ps(manager.paramsIndices('f')) = tmp;
            end
        end 
        function S    = sumSquaredErrors(this, pars)
            pars = num2cell(pars);        
            logP1 = sum(abs(this.dependentData - this.estimateDataFast(pars{:})).^2) / ...
                    sum(abs(this.dependentData).^2); % ECAT_t[ROI]
            logP2 = sum(abs(this.conc_crv_      - this.estimateCrvFast( pars{:})).^2) / ...
                    sum(abs(this.conc_crv_).^2); % CRV_t[arterial]
            %logP3 = sum(abs(this.conc_dcv_      - this.estimateDcvFast( pars{:})).^2) / ...
            %        sum(abs(this.conc_dcv_).^2); % DCV_t[arterial]
            S     = logP1 + logP2; % + logP3;
            if (S < eps)
                S = eps * (1 + rand(1)); 
            end
        end
             
        function        plotProduct(this)
            if (this.noPlotting); return; end
            figure;
            max_ecat = max( max(this.itsConcentration_ecat), max(this.dependentData));
            max_aif  = max([max(this.itsConcentration_crv) max(this.conc_crv_)]);
            
            plot(this.times, this.itsConcentration_ecat   / max_ecat, ...
                 this.times, this.dependentData           / max_ecat, 'o', ...
                 this.times, this.itsConcentration_crv    / max_aif, ...
                 this.times, this.conc_crv_               / max_aif, 's', ...
                 this.times, this.itsConcentration_ucdcv  / max_aif);
            legend('concentration_{ecat}', 'data_{ecat}', ...
                   'concentration_{crv}',  'data_{crv}', ...
                   'concentration_{ucdcv}'); 
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary:  ECAT norm %g, AIF norm %g', max_ecat, max_aif));
        end  
        function        plotParVars(this, par, vars)
            if (this.noPlotting); return; end
            assert(lstrfind(par, properties('mlpet.CRVAutoradiography')));
            assert(isnumeric(vars));
            switch (par)
                case 'A0'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.A1 this.T0 this.f  this.times this.conc_crv }; end
                case 'A1'
                    for v = 1:length(vars)
                        args{v} = { this.A0 vars(v) this.T0 this.f  this.times this.conc_crv }; end
                case 'T0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.A1 vars(v) this.f  this.times this.conc_crv }; end
                case 'f'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.A1 this.T0 vars(v) this.times this.conc_crv }; end
            end
            this.plotParArgs(par, args, vars);
        end         
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        kernel_
        kernelRange_ = 12:40
    end
    
    methods (Static, Access = 'private')        
        function     reportLoading(varargin)
            fprintf('CRVAutoradiography.reportLoading:\n'); 
            for v = 1:nargin
                disp(varargin{v});
            end
        end
        function c = gammaVariate(a, d, p, t0, t)
            norm   = gamma(d/p) * (p/a^d);
            c0     = abs(t.^(d-1) .* exp(-(t/a).^p)) / norm;  
            idx_t0 = mlpet.CRVAutoradiography.indexOf(t, t0);
            c      = zeros(1, length(t));
            c(idx_t0:end) = c0(1:end-idx_t0+1);
        end
        function c = steadyState(g, t0, t)
            c0     = (1 - exp(-t/g));
            idx_t0 = mlpet.CRVAutoradiography.indexOf(t, t0);
            c      = zeros(1, length(t));
            c(idx_t0:end) = c0(1:end-idx_t0+1);
        end
    end
    
    methods (Access = 'private')
        function        reportInitial(this)
            fprintf('CRVAutoradiography.kernelRange_:  '); disp(this.kernelRange_);
            fprintf('CRVAutoradiography.kernelBestFqfilename:  '); disp(this.kernelBestFqfilename);
            fprintf('CRVAutoradiography.this:  '); disp(this);
        end
        function this = loadKernel(this)
            load(this.kernelBestFqfilename);
            this.kernel_ = kernelBest(this.kernelRange_);
            this.kernel_(this.kernel_ < 0) = 0;
            this.kernel_ = this.kernel_ / sum(this.kernel_);  
        end
        function        plotParArgs(this, par, args, vars)
            if (this.noPlotting); return; end
            assert(lstrfind(par, properties('mlpet.CRVAutoradiography')));
            assert(iscell(args));
            assert(isnumeric(vars));
            import mlpet.*;
            figure
            hold on
            for v = 1:size(args,2)
                argsv = args{v};
                plot(this.times, CRVAutoradiography.concentration_ecat(argsv{:}));
            end
            title(sprintf('A0 %g, A1 %g, T0 %g, f %g', argsv{1}, argsv{2}, argsv{3}, argsv{4}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

