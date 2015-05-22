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
        A0 = 0.009234
        Ew = 0.905207230769231
        a  = 0.280722
        d  = 0.951272038461539
        n  = 0
        f  = 0.01045
        p  = 0.272528
        q0 = 1.916e7
        t0 = 2.634
    end 

    properties (Dependent)
        baseTitle
        detailedTitle
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
        function m   = get.map(this)
            fL = 0.5; fH = 2;
            m = containers.Map;
            m('A0') = struct('fixed', 1, 'min', fL*0.00726,  'mean', this.A0, 'max', fH* 0.0141);
            m('Ew') = struct('fixed', 1, 'min', fL*0.7901,   'mean', this.Ew, 'max', fH* 0.9300); % physiologic range +/- sigma, Herscovitch, JCBFM 7:527-541, 1987, table 2
            m('a')  = struct('fixed', 1, 'min', fL*0.280,    'mean', this.a,  'max', fH* 7.97);
            m('d')  = struct('fixed', 1, 'min', fL*0.877,    'mean', this.d,  'max', fH* 1.03);
            m('f')  = struct('fixed', 1, 'min', fL*0.004305, 'mean', this.f,  'max', fH* 0.01229); % 
            m('p')  = struct('fixed', 1, 'min', fL*0.225,    'mean', this.p,  'max', fH* 0.535); 
            m('q0') = struct('fixed', 0, 'min', fL*1.2353e7, 'mean', this.q0, 'max', fH* 2.6529e7);
            m('t0') = struct('fixed', 0, 'min', fL*0.3005,   'mean', this.t0, 'max', fH*14.66);
            
            if (mlpet.DSCAutoradiography.USE_RECIRCULATION)
                m('n') = struct('fixed', 1, 'min',    0, 'mean', 0.5*this.n, 'max', fH*this.n);
            else
                m('n') = struct('fixed', 1, 'min', -eps, 'mean', 0,          'max', eps);
            end
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
            aifShift  = ip.Results.aifShift;
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
        
        function ci   = concentration_i(A0, Ew, a, d, f, n, p, q0, t0, t, aif, aDose)
            import mlpet.*;
            lambda = DSCAutoradiography.LAMBDA;
            lambda_decay = DSCAutoradiography.LAMBDA_DECAY;
            
            dt     = t(2) - t(1);
            conc_a = q0 * aDose * dt * ...
                     conv(DSCAutoradiography.handInjection(t, ...
                               DSCAutoradiography.concentrationBar_a(aif, n, t), ...
                               DSCAutoradiography.INJECTION_RATE), ...
                          DSCAutoradiography.kernel(a,d,p,t));
            conc_a = conc_a(1:length(t));
            ci0    = A0 * Ew * f * dt * abs(conv(conc_a, exp(-(Ew * f / lambda + lambda_decay) * t)));
            ci0    = ci0(1:length(t));
            
            idx_t0 = DSCAutoradiography.indexOf(t, t0);
            ci     = zeros(1, length(t));
            ci(idx_t0:end) = ci0(1:end-idx_t0+1);
            ci     = abs(ci);
        end
        function cba  = concentrationBar_a(aif, n, t)
            if (mlpet.DSCAutoradiography.USE_RECIRCULATION)
                cba = aif.kAif_2(aif.a, aif.b, n, t, 0, aif.t1 - aif.t0);
            else
                cba = aif.kAif_1(aif.a, aif.b,    t, 0);
            end
        end
        function k    = kernel(a, d, p, t)
            dt = t(2) - t(1);
            k  = t.^(d-1) .* exp(-(t/a).^p);
            k  = k / (sum(k) * dt);
        end
        function args = interpolateData(mask, aif, ecat, ~, ecatShift)
            ecat       = ecat.masked(mask);
            ecatSkinny = ecat.volumeSummed;  
            ecatSkinny.img = ecatSkinny.img/mask.count;
            
            import mlpet.*;
            dt  = min(min(aif.taus), min(ecatSkinny.taus))/2;
            if (DSCHerscAutoradiography.USE_RECIRCULATION)
                kAif = aif.itsKAif_2;
            else
                kAif = aif.itsKAif_1;
            end
            [t_a,c_a] = DSCAutoradiography.shiftData(       aif.times,            kAif,      -aif.t0);
            [t_i,c_i] = DSCAutoradiography.shiftData(ecatSkinny.times, ecatSkinny.becquerels, ecatShift); 
            t   = t_i(1):dt:min([t_i(end) DSCAutoradiography.TIME_SUP]);
            c_a = DSCAutoradiography.myPchip(t_a, c_a, t);
            c_i = DSCAutoradiography.myPchip(t_i, c_i, t);            
            args = {c_a t c_i mask aif ecat};
        end
        function this = simulateMcmc(A0, Ew, a, d, f, n, p, q0, t0, t, concbar_a, aDose, map, mask, aif, ecat)
            import mlpet.*;       
            conc_i = DSCAutoradiography.concentration_i(A0, Ew, a, d, f, n, p, q0, t0, t, aif, aDose); % simulated
            this   = DSCAutoradiography(concbar_a, t, conc_i, mask, aif, ecat);
            this   = this.estimateParameters(map) %#ok<NOPRT>
        end
    end
    
	methods
        function ci   = itsConcentration_i(this)
            ci = this.concentration_i( ...
                 this.A0, this.Ew, this.a, this.d, this.f, this.n, this.p, this.q0, this.t0, ...
                 this.times, this.aif, this.dose_);
        end
        function ca   = itsEstimatedConcentration_a(this)
            import mlpet.*;
            dt = this.times(2) - this.times(1);
            ca = this.q0 * this.dose * dt * ...
                 conv(this.handInjection( ...
                           this.times, this.concentrationBar_a(this.aif, this.n, this.times), this.INJECTION_RATE), ...
                      this.kernel(this.a, this.d, this.p, this.times));
            ca = ca(1:this.length);
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
            ed = this.concentration_i( ...
                      A0, Ew, a, d, f, n, p, q0, t0, this.times, this.aif, this.dose_);
        end
        function this = simulateItsMcmc(this, aif)
            this = this.simulateMcmc( ...
                   this.A0, this.Ewb, this.a, this.d, this.f, this.n, this.p, this.q0, this.t0, ...
                   this.times, aif, this.dose_, this.map, ...
                   this.mask, this.aif, this.ecat);
        end
            
        function        plotProduct(this)
            figure;
            dcv      = this.itsDcv;
            max_i = max(max( this.itsConcentration_i),          max(this.concentration_obs));
            max_a = max(max( this.itsEstimatedConcentration_a), max(dcv.wellCounts));
            plot(this.times, this.itsConcentration_i          / max_i, ...
                 this.times + this.t0, ...
                             this.itsEstimatedConcentration_a / max_a, ...
                  dcv.times + this.t0 + this.aifShift, ...
                             dcv.wellCounts                   / max_a, 's', ...
                 this.times, this.concentration_obs           / max_i, 'o');
            legend('concentration_i', 'concentration_a', 'DCV',  'concentration_{obs}');
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary:  c_i norm %g, c_a norm %g', max_i, max_a));
        end  
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlpet.DSCAutoradiography')));
            assert(isnumeric(vars));
            switch (par)
                case 'A0'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.Ew this.a  this.d  this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'Ew'
                    for v = 1:length(vars)
                        args{v} = { this.A0 vars(v) this.a  this.d  this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'a'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew vars(v) this.d  this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'd'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  vars(v) this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'f'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  this.d  vars(v) this.n  this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'n'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  this.d  this.f  vars(v) this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'p'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  this.d  this.f  this.n  vars(v) this.q0  this.t0 this.times this.aif this.dose }; end
                case 'q0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  this.d  this.f  this.n  this.p  vars(v)  this.t0 this.times this.aif this.dose }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.Ew this.a  this.d  this.f  this.n  this.p  this.q0  vars(v) this.times this.aif this.dose }; end
            end
            this.plotParArgs(par, args, vars);
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
            this.mtt_a_ = this.moment1(this.times, this.itsEstimatedConcentration_a);
            this.expectedBestFitParams_ = ...
                [this.A0 this.Ew this.a this.d this.f this.n this.p this.q0 this.t0]';
                % initial expected values from properties
        end 
    end
    
    %% PRIVATE
    
    methods (Access = 'private')  
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
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

