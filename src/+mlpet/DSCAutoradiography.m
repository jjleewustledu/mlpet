classdef DSCAutoradiography < mlpet.AutoradiographyBuilder
	%% DSCAUTORADIOGRAPHY
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
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$     
    
	properties 
        A0 = 0.0456
        Ew = 0.84
        a  = 1.09
        d  = 1.08
        n  = 2.04e-4
        f  = 0.00928 % mL/s/mL, [15O]H_2O
        p  = 0.375
        q0 = 274
        t0 = 0
    end 

    properties (Dependent)
        baseTitle
        detailedTitle
        laif2
        dose
        map 
    end
    
    methods %% GET/SET
        function bt  = get.baseTitle(this)
            bt = sprintf('DSC Autoradiography %s', this.pnum);
        end
        function dt  = get.detailedTitle(this)
            dt = sprintf('%s:\nA0 %g, Ew %g, a %g, d %g, f %g, p %g, q0 %g, t0 %g', ...
                         this.baseTitle, this.A0, this.Ew, this.a, this.d, this.f, this.p, this.q0, this.t0);
        end
        function l   = get.laif2(this)
            assert(~isempty(this.aif_));
            l = this.aif_;
        end
        function d   = get.dose(this)
            d = this.dose_;
        end
        function m   = get.map(this)
            fL = 1; fH = 1;
            m = containers.Map;
            m('A0') = struct('fixed', 1, 'min', fL*0.01,   'mean', this.A0,  'max', fH* 0.03);
            m('Ew') = struct('fixed', 1, 'min', fL*0.79,   'mean', this.Ew,  'max', fH* 0.93);   % physiologic range, Herscovitch, JCBFM 7:527-541, 1987, table 2., +quartile          
            m('f')  = struct('fixed', 1, 'min', fL*0.0050, 'mean', this.f,   'max', fH* 0.0155); % physiologic range
            m('t0') = struct('fixed', 0, 'min',    0,      'mean', this.t0,  'max', fH*20);
            m('a')  = struct('fixed', 0, 'min', fL*0.12,   'mean', this.a,   'max', fH* 8.5);
            m('d')  = struct('fixed', 0, 'min', fL*0.91,   'mean', this.d,   'max', fH* 1.8);
            m('n')  = struct('fixed', 1,'min',  fL*1e-5,   'mean',0.5*this.n,'max', fH*this.n);
            m('p')  = struct('fixed', 0, 'min', fL*0.28,   'mean', this.p,   'max', fH* 0.67); 
            m('q0') = struct('fixed', 0, 'min', fL*1e2,    'mean', this.q0,  'max', fH* 1e3); 
        end
    end
    
    methods (Static)
        function this  = load(maskFn, maskAifFn, aifFn, ecatFn, varargin)
            
            %maskAifFn = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/perfusion_4dfp/perfMask.nii.gz';
            %aifFn     = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/perfusion_4dfp/ep2d_default_mcf.nii.gz';
            
            ip = inputParser;
            addRequired(ip, 'maskFn',    @(x) lexist(x, 'file'));
            addRequired(ip, 'maskAifFn', @(x) lexist(x, 'file'));
            addRequired(ip, 'aifFn',     @(x) lexist(x, 'file'));
            addRequired(ip, 'ecatFn',    @(x) lexist(x, 'file'));
            addOptional(ip, 'aifShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(ip, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(ip, maskFn, maskAifFn, aifFn, ecatFn, varargin{:});
            
            import mlfourd.* mlpet.*;
            mask      = DSCAutoradiography.loadMask(ip.Results.maskFn); 
            aif       = DSCAutoradiography.loadAif(ip.Results.aifFn, ip.Results.maskAifFn); 
            ecat      = DSCAutoradiography.loadEcat(ip.Results.ecatFn);            
            aifShift  = ip.Results.aifShift - DSCAutoradiography.kAif2Takeoff(aif);
            ecatShift = ip.Results.ecatShift;
            
            args = DSCAutoradiography.interpolateData(mask, aif, ecat, aifShift, ecatShift); 
            this = DSCAutoradiography(args{:});            
            this.aifShift_  = aifShift;
            this.ecatShift_ = ecatShift;
        end
        function laif2 = loadAif(varargin)
            ip = inputParser;
            addOptional(ip, 'dscFn', [], @(x) lexist(x, 'file'));
            addOptional(ip, 'mskFn', [], @(x) lexist(x, 'file'));
            addOptional(ip, 'wbdsc', [], @(x) isa(x, 'mlperfusion.IMRCurve'));
            parse(ip, varargin{:});            
        
            if (~isempty(ip.Results.dscFn) && ~isempty(ip.Results.mskFn))
                wbDsc = mlperfusion.WholeBrainDSC(ip.Results.dscFn, ip.Results.mskFn);
            elseif (~isempty(ip.Results.wbdsc))
                wbDsc = ip.Results.wbdsc;
            else
                error('mlpet:requiredObjectNotFound', 'DSCAutoradiography.loadMask');
            end
            storageFn = fullfile(wbDsc.filepath, 'LaifTrainer.trainLaif2.laif2.mat');
            if (lexist(storageFn) && mlpet.DSCAutoradiography.REUSE_STORED)
                load(storageFn);
                return
            end
            laif2 = mlperfusion.Laif2.runLaif(wbDsc.times, wbDsc.itsMagnetization); 
            save(storageFn, 'laif2');
        end
        
        function this = simulateMcmc(A0, Ew, a, d, f, n, p, q0, t0, t, concbar_a, dose, map, mask, aif, aifShift, ecat)
            import mlpet.*;       
            conc_i = DSCAutoradiography.concentration_i(A0, Ew, a, d, f, n, p, q0, t0, t, aif, aifShift, dose); % simulated
            this   = DSCAutoradiography(concbar_a, t, conc_i, mask, aif, ecat);
            this   = this.estimateParameters(map) %#ok<NOPRT>
        end   
        function this = runAutoradiography(concbar_a, t, conc_obs, mask, aif, ecat)
            %% RUNAUTORADIOGRAPHY is deprecated; used by legacy Test_PETAutoradiography
            %  Usage:   DSCAutoradiography.runAutoradiography(arterial_counts, times, scanner_counts) 
            %                                                 ^ well-counts/s/mL      ^
            %                                                                  ^ s
            
            import mlpet.*;
            this = DSCAutoradiography(concbar_a, t, conc_obs, mask, aif, ecat);
            this = this.estimateParameters(this.map);            
        end
        function ci   = concentration_i(A0, Ew, a, d, f, n, p, q0, t0, t, aif, aifShift, dose)
            import mlpet.*;
            lambda = DSCAutoradiography.LAMBDA;
            lambda_decay = DSCAutoradiography.LAMBDA_DECAY;
            
            conc_a = q0 * dose * ...
                     conv(DSCAutoradiography.concentrationBar_a(aif, n, t, aifShift), ...
                          DSCAutoradiography.kernel(a,d,p,t));
            conc_a = conc_a(1:length(t));
            ci0    = A0 * Ew * f * abs(conv(conc_a, exp(-(Ew * f / lambda + lambda_decay) * t)));
            ci0    = ci0(1:length(t));
            %assert(all(isfinite(ci0)), 'ci -> %s', num2str(ci0));
            
            idx_t0 = DSCAutoradiography.indexOf(t, t0);
            ci     = zeros(1, length(t));
            ci(idx_t0:end) = ci0(1:end-idx_t0+1);
            ci     = abs(ci);
        end
        function cb_a = concentrationBar_a(aif, n, t, aifShift)
            cb_a = aif.kAif_2(aif.a, aif.b, n, t, aif.t0 + aifShift, aif.t1 + aifShift);
        end
        function k    = kernel(a, d, p, t)
            cnorm = ((p/a^d)/gamma(d/p));
            k     = cnorm * t.^(d-1) .* exp(-(t/a).^p);
        end
        function args = interpolateData(mask, aif, ecat, aifShift, ecatShift)
            ecat       = ecat.masked(mask);
            ecatSkinny = ecat.volumeSummed;  
            ecatSkinny.img = ecatSkinny.img/mask.count;
            
            import mlpet.*;
            aifShift  = aifShift - DSCAutoradiography.kAif2Takeoff(aif);
            [t_a,c_a] = DSCAutoradiography.shiftData(       aif.times,        aif.itsKAif_2,   aifShift);
            [t_i,c_i] = DSCAutoradiography.shiftData(ecatSkinny.times, ecatSkinny.becquerels, ecatShift); 
            dt  = min(min(aif.taus), min(ecatSkinny.taus))/2;
            t   = t_i(1):dt:min([t_i(end) DSCAutoradiography.TIME_SUP]);
            c_a = pchip(t_a, c_a, t);
            c_i = pchip(t_i, c_i, t);            
            args = {c_a t c_i mask aif ecat};
        end
        function t    = kAif2Takeoff(laif2)
            assert(isa(laif2, 'mlperfusion.ILaif'));
            t = laif2.t0;
            return
            
            kA    = laif2.itsKAif_2;
            maxKA = max(kA);
            for ti = 2:length(laif2.times)
                t = laif2.times(ti-1);
                if (kA(ti) > 0.01*maxKA)
                    break;
                end
            end
            
            if (abs(t - laif2.t0)/laif2.t0 < 0.05)
                t = laif2.t0;
            end
        end
    end
    
	methods	          
        function this = simulateItsMcmc(this, aif)
            this = this.simulateMcmc( ...
                   this.A0, this.Ewb, this.a, this.d, this.f, this.n, this.p, this.q0, this.t0, this.times, aif, this.dose_, this.map, ...
                   this.mask, this.aif, this.aifShift, this.ecat);
        end
        function ci   = itsConcentration_i(this)
            ci = this.concentration_i( ...
                 this.A0, this.Ew, this.a, this.d, this.f, this.n, this.p, this.q0, this.t0, ...
                 this.times, this.aif, this.aifShift, this.dose_);
        end
        function ca   = itsBayesianConcentration_a(this)
            import mlpet.*;
            ca = this.q0 * this.dose * ...
                 conv(this.concentrationBar_a(this.aif, this.n, this.times, this.aifShift), ...
                      this.kernel(this.a, this.d, this.p, this.times));
            ca = ca(1:this.length);
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
            this.ensureKeyOrdering({'A0' 'Ew' 'a' 'd' 'f' 'n' 'p' 'q0' 't0'});
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.A0 = this.finalParams('A0');
            this.Ew = this.finalParams('Ew');
            this.a  = this.finalParams('a');
            this.d  = this.finalParams('d');
            this.f  = this.finalParams('f');
            this.n  = this.finalParams('n');
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
                this.finalParams(keys{9}));
        end
        function ed   = estimateDataFast(this, A0, Ew, a, d, f, n, p, q0, t0)
            ed = this.concentration_i(A0, Ew, a, d, f, n, p, q0, t0, this.times, this.aif, this.aifShift, this.dose_);
        end       
            
        function        plotProduct(this)
            figure;
            dcv      = this.itsDcv;
            dcvTimes = dcv.times + this.aifShift;
            max_i = max(max( this.itsConcentration_i),         max(this.concentration_obs));
            max_a = max(max( this.itsBayesianConcentration_a), max(dcv.wellCounts));
            plot(this.times, this.itsConcentration_i         / max_i, ...
                 this.times, this.itsBayesianConcentration_a / max_a, ...
                   dcvTimes, dcv.wellCounts                  / max_a, 'o', ...
                 this.times, this.concentration_obs          / max_i, 'o');
            legend('Bayesian concentration_i', 'Bayesian concentration_a', 'DCV from data',  'concentration_{obs} from data');
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary:  C_i norm %g, C_a norm %g', max_i, max_a));
        end  
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlpet.DSCAutoradiography')));
            assert(isnumeric(vars));
            switch (par)
                case 'A0'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.Ew this.a  this.d  this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.aifShift this.dose }; end
                case 'Ew'
                    for v = 1:length(vars)
                        args{v} = { this.A0 vars(v) this.a  this.d  this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.aifShift this.dose }; end
                case 'a'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew vars(v) this.d  this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.aifShift this.dose }; end
                case 'd'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  vars(v) this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.aifShift this.dose }; end
                case 'f'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  this.d  vars(v) this.n  this.p  this.q0  this.t0 this.times this.aif this.aifShift this.dose }; end
                case 'n'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  this.d  this.f  vars(v) this.p  this.q0  this.t0 this.times this.aif this.aifShift this.dose }; end
                case 'p'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  this.d  this.f  this.n  vars(v) this.q0  this.t0 this.times this.aif this.aifShift this.dose }; end
                case 'q0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  this.d  this.f  this.n  this.p  vars(v)  this.t0 this.times this.aif this.aifShift }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  this.d  this.f  this.n  this.p  this.q0  vars(v) this.times this.aif this.aifShift }; end
            end
            this.plotParArgs(par, args, vars);
        end
        function this = save(this)   
            this = this.saveas('DSCAutoradiography.save.mat');
        end
        function this = saveas(this, fn)  
            dscAutoradiography = this;  %#ok<NASGU>
            save(fn, 'dscAutoradiography');         
        end
    end 
    
    %% PROTECTED
    
    methods (Access = 'protected')
 		function this = DSCAutoradiography(varargin)
 			%% DSCAUTORADIOGRAPHY 
 			%  Usage:  this = DSCAutoradiography( ...
            %                 concentrationBar_a, times_i, concentration_i[, mask, aif, ecat]) 
            %                 ^ counts/s/mL       ^ s      ^ counts/s/g
            %                                                                ^ INIfTId
            %                                                                      ^ ILaif, IWellData 
            %                                                                           ^ IScannerData

 			this = this@mlpet.AutoradiographyBuilder(varargin{:}); 
            this.n = this.aif.n;
            this = this.estimateDose_;
            this.expectedBestFitParams_ = [this.A0 this.Ew this.a this.d this.f this.n this.p this.q0 this.t0]'; % initial expected values from properties
        end 
    end
    
    %% PRIVATE
    
    properties (Access = 'private')
        dose_
    end
    
    methods (Access = 'private')
        function this = estimateDose_(this)
            import mlpet.* mlfourd.*;  
            taus              = this.times(2:end) - this.times(1:end-1);
            taus(this.length) = taus(this.length - 1);
            this.dose_ = this.concentration_obs * taus'; % trapezoidal time-integral  
            fprintf('DSCAutoradiography.estimateDose_ -> %g\n', this.dose_);
        end        
        function plotParArgs(this, par, args, vars)
            assert(lstrfind(par, properties('mlpet.DSCAutoradiography')));
            assert(iscell(args));
            assert(isnumeric(vars));
            import mlpet.*;
            figure
            hold on
            for v = 1:size(args,2)
                argsv = args{v};
                plot(this.times, DSCAutoradiography.concentration_i(argsv{:}));
            end
            title(sprintf('A0 %g, Ew %g, a %g, d %g, f %g, n %g, p %g, q0 %g, t0 %g', ...
                          argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}, argsv{7}, argsv{8}, argsv{9}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
        function dcv = itsDcv(this)
            dcv = mlpet.PETAutoradiography.loadAif( ...
                 fullfile(this.ecat.filepath, [this.pnum 'ho1.dcv'])); 
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

