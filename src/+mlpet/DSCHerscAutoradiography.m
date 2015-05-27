classdef DSCHerscAutoradiography < mlpet.AutoradiographyBuilder
	%% DSCHERSCAUTORADIOGRAPHY
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
        PS = 0.0314812307692308
        a  = 0.280722
        d  = 0.951272038461539
        n  = 0
        f  = 0.009716
        p  = 0.272528
        q0 = 1.843e7
        t0 = 0.5232
    end 

    properties (Dependent)
        baseTitle
        detailedTitle
        map 
    end
    
    methods %% GET/SET
        function bt = get.baseTitle(this)
            bt = sprintf('DSC Hersc. %s', this.pnum);
        end
        function dt = get.detailedTitle(this)
            dt = sprintf('%s:\nA0 %g, PS %g, a %g, d %g, f %g, p %g, q0 %g t0 %g', ...
                         this.baseTitle, this.A0, this.PS, this.a, this.d, this.f, this.p, this.q0, this.t0);
        end
        function m  = get.map(this)
            fL = 0.9; fH = 1.1;
            m = containers.Map;
            m('A0') = struct('fixed', 0, 'min', fL*0.007200, 'mean', this.A0, 'max', fH* 0.01400);
            m('PS') = struct('fixed', 0, 'min',    0.009275, 'mean', this.PS, 'max',     0.03675); % physiologic range +/- sigma, Herscovitch, JCBFM 7:527-541, 1987, table 2
            m('a')  = struct('fixed', 0, 'min', fL*0.280,    'mean', this.a,  'max', fH* 7.97);
            m('d')  = struct('fixed', 0, 'min', fL*0.877,    'mean', this.d,  'max', fH* 1.03);
            m('f')  = struct('fixed', 0, 'min',    0.004305, 'mean', this.f,  'max',     0.01229); % 
            m('p')  = struct('fixed', 0, 'min', fL*0.225,    'mean', this.p,  'max', fH* 0.535); 
            m('q0') = struct('fixed', 0, 'min', fL*1.129e7,  'mean', this.q0, 'max', fH* 2.962e7);
            m('t0') = struct('fixed', 0, 'min', fL*0.05175,  'mean', this.t0, 'max', fH*15.38);
            
            if (mlpet.DSCHerscAutoradiography.USE_RECIRCULATION)
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
            mask = DSCHerscAutoradiography.loadMask(ip.Results.maskFn); 
            aif  = DSCHerscAutoradiography.loadAif(ip.Results.aifFn, ip.Results.maskAifFn); 
            ecat = DSCHerscAutoradiography.loadEcat(ip.Results.ecatFn);         
            aifShift  = ip.Results.aifShift;
            ecatShift = ip.Results.ecatShift;
            
            args = DSCHerscAutoradiography.interpolateData(mask, aif, ecat, aifShift, ecatShift); 
            this = DSCHerscAutoradiography(args{:});
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
                error('mlpet:requiredObjectNotFound', 'DSCHerscAutoradiography.loadMask');
            end
            storageFn = fullfile(wbDsc.filepath, 'LaifTrainer.trainLaif2.laif2.mat');
            if (lexist(storageFn) && mlpet.DSCHerscAutoradiography.REUSE_STORED)
                load(storageFn);
                return
            end
            laif2 = mlperfusion.Laif2.runLaif(wbDsc.times, wbDsc.itsMagnetization); 
            save(storageFn, 'laif2');
        end
           
        function ci   = concentration_i(A0, PS, a, d, f, n, p, q0, t0, t, aif, aDose)
            import mlpet.*;
            lambda = DSCHerscAutoradiography.LAMBDA;
            lambda_decay = DSCHerscAutoradiography.LAMBDA_DECAY;
            
            dt     = t(2) - t(1);
            m      = 1 - exp(-PS/f);
            conc_a = q0 * aDose * dt * ...
                     conv(DSCHerscAutoradiography.handInjection(t, ...
                               DSCHerscAutoradiography.concentrationBar_a(aif, n, t), ...
                               DSCHerscAutoradiography.INJECTION_RATE), ...
                          DSCHerscAutoradiography.kernel(a,d,p,t));
            conc_a = conc_a(1:length(t));
            ci0    = A0 * m * f * dt * abs(conv(conc_a, exp(-(m * f / lambda + lambda_decay) * t)));
            ci0    = ci0(1:length(t));
            
            idx_t0 = DSCHerscAutoradiography.indexOf(t, t0);
            ci     = zeros(1, length(t));
            ci(idx_t0:end) = ci0(1:end-idx_t0+1);
            ci     = abs(ci);
        end
        function cba = concentrationBar_a(aif, n, t)
            if (mlpet.DSCHerscAutoradiography.USE_RECIRCULATION)
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
            [t_a,c_a] = DSCHerscAutoradiography.shiftData(       aif.times,            kAif,      -aif.t0);
            [t_i,c_i] = DSCHerscAutoradiography.shiftData(ecatSkinny.times, ecatSkinny.becquerels, ecatShift); 
            t   = t_i(1):dt:min([t_i(end) DSCHerscAutoradiography.TIME_SUP]);
            c_a = DSCHerscAutoradiography.myPchip(t_a, c_a, t);
            c_i = DSCHerscAutoradiography.myPchip(t_i, c_i, t);            
            args = {c_a t c_i mask aif ecat};
        end
        function this = simulateMcmc(A0, PS, a, d, f, n, p, q0, t0, t, concbar_a, aDose, map, mask, aif, ecat)
            import mlpet.*;       
            conc_i = DSCHerscAutoradiography.concentration_i(A0, PS, a, d, f, n, p, q0, t0, t, aif, aDose); % simulated
            this   = DSCHerscAutoradiography(concbar_a, t, conc_i, mask, aif, ecat);
            this   = this.estimateParameters(map) %#ok<NOPRT>
        end
    end
    
	methods
        function ci   = itsConcentration_i(this)
            ci = this.concentration_i( ...
                 this.A0, this.PS, this.a, this.d, this.f, this.n, this.p, this.q0, this.t0, ...
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
        function sse  = sumSquaredErrors(this, p)
            p    = num2cell(p);       
            sse1 = sum(abs(this.dependentData - this.estimateDataFast(p{:})).^2);
            sse2 =     abs(this.mttObsOverA - this.mttObsOverA0).^2;
            lagrange = sse1/sse2;
            sse  = sse1 + lagrange*sse2;
            if (sse < eps)
                sse = sse + (1 + rand(1))*eps; 
            end
            %assert(isfinite(sse) && ~isnan(sse), 'AbstractBayesianProblem.p -> %s', cell2str(p));
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'map', this.map, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            import mlbayesian.*;
            this.paramsManager = BayesianParameters(varargin{:});
            this.ensureKeyOrdering({'A0' 'PS' 'a' 'd' 'f' 'n' 'p' 'q0' 't0'});
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.A0 = this.finalParams('A0');
            this.PS = this.finalParams('PS');
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
        function ed   = estimateDataFast(this, A0, PS, a, d, f, n, p, q0, t0)
            ed = this.concentration_i( ...
                      A0, PS, a, d, f, n, p, q0, t0, this.times, this.aif, this.dose_);
        end
        function ps   = adjustParams(this, ps)
            manager = this.paramsManager;
            if (ps(manager.paramsIndices('f'))  > ps(manager.paramsIndices('PS')))
                tmp                             = ps(manager.paramsIndices('PS'));
                ps(manager.paramsIndices('PS')) = ps(manager.paramsIndices('f'));
                ps(manager.paramsIndices('f')) = tmp;
            end
            % limit brain-water-kernel's a by DSC's 1/b or 1/(PET tracer injection rate) ?
            % force a ~ 1/this.aif.b?
            % force a ~ this.moment1(this.times, this.itsEstimatedConcentration_a) ?
            %if (ps(manager.paramsIndices('a')) < this.moment1(this.times, this.itsEstimatedConcentration_a))
            %    ps(manager.paramsIndices('a')) = this.moment1(this.times, this.itsEstimatedConcentration_a);
            %end
        end
        function this = simulateItsMcmc(this, aif)
            this = this.simulateMcmc( ...
                   this.A0, this.PS, this.a, this.d, this.f, this.n, this.p, this.q0, this.t0, ...
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
                             dcv.wellCounts                   / max_a, 'o', ...
                 this.times, this.concentration_obs           / max_i, 'o');
            legend('concentration_i', 'concentration_a', 'DCV',  'concentration_{obs}');
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary:  c_i norm %g, c_a norm %g', max_i, max_a));
        end 
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlpet.DSCHerscAutoradiography')));
            assert(isnumeric(vars));
            switch (par)
                case 'A0'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.PS this.a  this.d  this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'PS'
                    for v = 1:length(vars)
                        args{v} = { this.A0 vars(v) this.a  this.d  this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'a'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS vars(v) this.d  this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'd'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  vars(v) this.f  this.n  this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'f'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  vars(v) this.n  this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'n'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  this.f  vars(v) this.p  this.q0  this.t0 this.times this.aif this.dose }; end
                case 'p'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  this.f  this.n  vars(v) this.q0  this.t0 this.times this.aif this.dose }; end
                case 'q0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  this.f  this.n  this.p  vars(v)  this.t0 this.times this.aif this.dose }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  this.f  this.n  this.p  this.q0  vars(v) this.times this.aif this.dose }; end
            end
            this.plotParArgs(par, args, vars);
        end
    end 
    
    %% PROTECTED
    
    methods (Access = 'protected')
 		function this = DSCHerscAutoradiography(varargin)
 			%% DSCHERSCAUTORADIOGRAPHY 
 			%  Usage:  this = DSCHerscAutoradiography( ...
            %                 concentrationBar_a, times_i, concentration_i[, mask, aif, ecat]) 
            %                 ^ counts/s/mL       ^ s      ^ counts/s/g
            %                                                                ^ INIfTId
            %                                                                      ^ ILaif, IWellData 
            %                                                                           ^ IScannerData

 			this = this@mlpet.AutoradiographyBuilder(varargin{:}); 
            this.n = this.aif.n;
            this.mtt_a_ = this.moment1(this.times, this.itsEstimatedConcentration_a);
            this.expectedBestFitParams_ = ...
                [this.A0 this.PS this.a this.d this.f this.n this.p this.q0 this.t0]'; 
                % initial expected values from properties
        end 
    end
    
    %% PRIVATE
    
    methods (Access = 'private')        
        function plotParArgs(this, par, args, vars)
            assert(lstrfind(par, properties('mlpet.DSCHerscAutoradiography')));
            assert(iscell(args));
            assert(isnumeric(vars));
            import mlpet.*;
            figure
            hold on
            for v = 1:size(args,2)
                argsv = args{v};
                plot(this.times, DSCHerscAutoradiography.concentration_i(argsv{:}));
            end
            title(sprintf('A0 %g, PS %g, a %g, d %g, f %g, n %g, p %g, q0 %g, t0 %g', ...
                          argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}, argsv{7}, argsv{8}, argsv{9}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

