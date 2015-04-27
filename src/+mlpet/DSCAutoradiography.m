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
        showPlots = true	 
        baseTitle = 'DSC Autoradiography'
        xLabel    = 'times/s'
        yLabel    = 'concentration/(well-counts/mL/s)'
        
        A0 = 0.071930
        PS = 0.025085 % cm^3/s/g, [15O]H_2O
        a  = 10.060445
        d  = 1.132742
        f  = 0.00958 % mL/s/g, [15O]H_2O
        p  = 0.623448
        q0 = 5271688.678790
        t0 = 0
    end 

    properties (Dependent)
        aif
        mask
        ecat
        concentration_a
        concentration_obs
        map 
    end
    
    methods %% GET/SET
        function a  = get.aif(this)
            assert(~isempty(this.aif_));
            a = this.aif_;
        end
        function m  = get.mask(this)
            assert(~isempty(this.mask_));
            m = this.mask_;
        end
        function e  = get.ecat(this)
            assert(~isempty(this.ecat_));
            e = this.ecat_;
        end
        function ca = get.concentration_a(this)
            assert(~isempty(this.concentration_a_));
            ca = this.concentration_a_;
        end
        function co = get.concentration_obs(this)
            co = this.dependentData;
        end
        function m  = get.map(this)
            m = containers.Map;
            m('A0') = struct('fixed', 1, 'min', this.priorLow(this.A0), 'mean', this.A0, 'max',  this.priorHigh(this.A0));
            m('PS') = struct('fixed', 1, 'min', 0.013,                  'mean', this.PS, 'max',  0.025333); % physiologic range, Herscovitch, JCBFM 7:527-541, 1987, table 2.
            m('f')  = struct('fixed', 0, 'min', 0.0053,                 'mean', this.f,  'max',  0.012467); % 
            m('t0') = struct('fixed', 1, 'min', 0,                      'mean', this.t0, 'max', 30);
            m('a')  = struct('fixed', 1, 'min', 5,                      'mean', this.a,  'max', 29);
            m('d')  = struct('fixed', 1, 'min', 0.5,                    'mean', this.d,  'max',  2);
            m('p')  = struct('fixed', 1, 'min', 0.5,                    'mean', this.p,  'max',  1.5); 
            m('q0') = struct('fixed', 1, 'min', this.q0/10,             'mean', this.q0, 'max',  this.q0*10);
        end
    end
    
    methods (Static)
        function this = loadDebug(maskFn, maskAifFn, aifFn, pie, ecatFn, varargin)
            
            %maskAifFn = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/perfusion_4dfp/perfMask.nii.gz';
            %aifFn     = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/perfusion_4dfp/ep2d_default_mcf.nii.gz';
            
            ip = inputParser;
            addRequired(ip, 'maskFn',    @(x) lexist(x, 'file'));
            addRequired(ip, 'maskAifFn', @(x) lexist(x, 'file'));
            addRequired(ip, 'aifFn',     @(x) lexist(x, 'file'));
            addRequired(ip, 'pie',       @(x) isnumeric(x) && isscalar(x));
            addRequired(ip, 'ecatFn',    @(x) lexist(x, 'file'));
            addOptional(ip, 'aifShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(ip, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(ip, maskFn, maskAifFn, aifFn, pie, ecatFn, varargin{:});
            
            import mlfourd.* mlpet.*;
            mask = DSCAutoradiography.loadMask(ip.Results.maskFn);             
            aif  = DSCAutoradiography.loadAifDebug;        
            %aif  = DSCAutoradiography.loadAif(ip.Results.aifFn, ip.Results.maskAifFn); 
            ecat = DSCAutoradiography.loadEcat(ip.Results.pie, ip.Results.ecatFn);            
            args = DSCAutoradiography.interpolateDataDebug(mask, aif, ecat, ip.Results.aifShift, ip.Results.ecatShift); 
            %args = DSCAutoradiography.interpolateData(mask, aif, ecat, ip.Results.aifShift, ip.Results.ecatShift); 
            this = DSCAutoradiography(args{:});
        end
        function this = load(maskFn, maskAifFn, aifFn, pie, ecatFn, varargin)
            
            %maskAifFn = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/perfusion_4dfp/perfMask.nii.gz';
            %aifFn     = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/perfusion_4dfp/ep2d_default_mcf.nii.gz';
            
            ip = inputParser;
            addRequired(ip, 'maskFn',    @(x) lexist(x, 'file'));
            addRequired(ip, 'maskAifFn', @(x) lexist(x, 'file'));
            addRequired(ip, 'aifFn',     @(x) lexist(x, 'file'));
            addRequired(ip, 'pie',       @(x) isnumeric(x) && isscalar(x));
            addRequired(ip, 'ecatFn',    @(x) lexist(x, 'file'));
            addOptional(ip, 'aifShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(ip, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(ip, maskFn, maskAifFn, aifFn, pie, ecatFn, varargin{:});
            
            import mlfourd.* mlpet.*;
            mask = DSCAutoradiography.loadMask(ip.Results.maskFn); 
            aif  = DSCAutoradiography.loadAif(ip.Results.aifFn, ip.Results.maskAifFn); 
            ecat = DSCAutoradiography.loadEcat(ip.Results.pie, ip.Results.ecatFn);            
            args = DSCAutoradiography.interpolateData(mask, aif, ecat, ip.Results.aifShift, ip.Results.ecatShift); 
            this = DSCAutoradiography(args{:});
        end
        function aif  = loadAifDebug
            aif = mlpet.UncorrectedDCV.load( ...
                '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/ECAT_EXACT/pet/p7267ho1.dcv');
        end
        function aif  = loadAif(varargin)
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
            storageFn = fullfile(wbDsc.filepath, 'DSCAutoradiography_loadAif_aif.mat');
            if (lexist(storageFn))
                load(storageFn);
                return
            end
            aif = mlperfusion.Laif0.runLaif(wbDsc.times, wbDsc.itsMagnetization); 
            save(storageFn);
        end
        function this = simulateMcmc(A0, PS, a, d, f, p, q0, t0, t, conc_a, map)
            import mlpet.*;       
            conc_i = DSCAutoradiography.concentration_i(A0, PS, a, d, f, p, q0, t0, t, conc_a); % simulated
            this   = DSCAutoradiography(conc_a, t, conc_i);
            this   = this.estimateParameters(map) %#ok<NOPRT>
        end   
        function this = runAutoradiography(conc_a, t, conc_obs)
            %% RUNAUTORADIOGRAPHY
            %  Usage:   DSCAutoradiography.runAutoradiography(arterial_counts, times, scanner_counts) 
            %                                                 ^counts/s/mL     ^ s    ^ counts/s/g
            
            import mlpet.*;
            this = DSCAutoradiography(conc_a, t, conc_obs*DSCAutoradiography.BRAIN_DENSITY);
            this = this.estimateParameters(this.map);            
        end
        function ci   = concentration_i(A0, PS, a, d, f, p, q0, t0, t, conc_a)
            import mlpet.*;
            lambda = DSCAutoradiography.LAMBDA;
            lambda_decay = DSCAutoradiography.LAMBDA_DECAY;
            m      = 1 - exp(-PS/f);
            conc_b = q0*conv(conc_a, DSCAutoradiography.kernel(a,d,p,t));
            conc_b = conc_b(1:length(t));
            ci0    = A0*m*f*abs(conv(conc_b, exp(-(m*f/lambda + lambda_decay)*t)));
            ci0    = ci0(1:length(t));
            assert(all(isfinite(ci0)), 'ci -> %s', num2str(ci0));
            
            idx_t0 = DSCAutoradiography.indexOf(t, t0);
            ci     = zeros(1, length(t));
            ci(idx_t0:end) = ci0(1:end-idx_t0+1);
            ci     = abs(ci);
        end
        function k    = kernel(a, d, p, t)
            cnorm = ((p/a^d)/gamma(d/p));
            k     = cnorm * t.^(d-1) .* exp(-(t/a).^p);
        end
        function args = interpolateDataDebug(mask, aif, ecat, aifShift, ecatShift)
            ecat = ecat.masked(mask);
            ecat = ecat.volumeSummed;   
            import mlpet.*;
            [t_a,c_a] = DSCAutoradiography.shiftDataLeft( aif.times,  aif.wellCounts,               aifShift);
            [t_i,c_i] = DSCAutoradiography.shiftDataLeft(ecat.times, ecat.wellCounts/ecat.nPixels, ecatShift); 
            dt  = min(min(aif.taus), min(ecat.taus));
            t   = min(t_a(1), t_i(1)):dt:min(t_a(end), t_i(end));
            c_a = pchip(t_a, c_a, t);
            c_i = pchip(t_i, c_i, t);            
            args = {c_a t c_i mask aif ecat};
        end
        function args = interpolateData(mask, aif, ecat, aifShift, ecatShift)
            ecat = ecat.masked(mask);
            ecat = ecat.volumeSummed;   
            import mlpet.*;
            [t_a,c_a] = DSCAutoradiography.shiftDataLeft( aif.times,  aif.itsKAif,                  aifShift);
            [t_i,c_i] = DSCAutoradiography.shiftDataLeft(ecat.times, ecat.wellCounts/ecat.nPixels, ecatShift); 
            dt  = min(min(aif.taus), min(ecat.taus));
            t   = min(t_a(1), t_i(1)):dt:min(t_a(end), t_i(end));
            c_a = pchip(t_a, c_a, t);
            c_i = pchip(t_i, c_i, t);            
            args = {c_a t c_i mask aif ecat};
        end
    end
    
	methods	  
 		function this = DSCAutoradiography(conc_a, times_i, conc_i, varargin)
 			%% DSCAUTORADIOGRAPHY 
 			%  Usage:  this = DSCAutoradiography(concentration_a, times_i, concentration_i) 
            %                                    ^ counts/s/mL    ^ s      ^ counts/s/g

 			this = this@mlpet.AutoradiographyBuilder(times_i, conc_i); 
            ip = inputParser;
            addRequired(ip, 'conc_a',  @isnumeric);
            addRequired(ip, 'times_i', @isnumeric);
            addRequired(ip, 'conc_i',  @isnumeric);
            addOptional(ip, 'mask', [], @(x) isa(x, 'mlfourd.INIfTId'));
            addOptional(ip, 'aif',  [], @(x) isa(x, 'mlperfusion.ILaif') || isa(x, 'mlpet.IWellData'));
            addOptional(ip, 'ecat', [], @(x) isa(x, 'mlpet.IScannerData'));
            parse(ip, conc_a, times_i, conc_i, varargin{:});
            
            this.concentration_a_ = ip.Results.conc_a;
            this.mask_            = ip.Results.mask;
            this.aif_             = ip.Results.aif;
            this.ecat_            = ip.Results.ecat;
            this.expectedBestFitParams_ = [this.A0 this.PS this.a this.d this.f this.p this.q0 this.t0]'; % initial expected values from properties
        end 
        
        function this = simulateItsMcmc(this, conc_a)
            this = mlpet.DSCAutoradiography.simulateMcmc( ...
                   this.A0, this.PS, this.a, this.d, this.f, this.p, this.q0, this.t0, this.times, conc_a, this.map);
        end
        function ci   = itsConcentration_i(this)
            ci = mlpet.DSCAutoradiography.concentration_i( ...
                 this.A0, this.PS, this.a, this.d, this.f, this.p, this.q0, this.t0, this.times, this.concentration_a);
        end        
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'map', this.map, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            import mlbayesian.*;
            this.paramsManager = BayesianParameters(varargin{:});
            this.ensureKeyOrdering({'A0' 'PS' 'a' 'd' 'f' 'p' 'q0' 't0'});
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.A0 = this.finalParams('A0');
            this.PS = this.finalParams('PS');
            this.a  = this.finalParams('a');
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
                this.finalParams(keys{8}));
        end
        function ed   = estimateDataFast(this, A0, PS, a, d, f, p, q0, t0)
            ed = mlpet.DSCAutoradiography.concentration_i( ...
                       A0, PS, a, d, f, p, q0, t0, this.times, this.concentration_a);
        end
        function x    = priorLow(~, x)
            x = 0.5*x;
        end
        function x    = priorHigh(~, x)
            x = 2*x;
        end
        function        plotInitialData(this)
            figure;
            max_a   = max(this.concentration_a);
            max_obs = max(this.concentration_obs);
            plot(this.times, this.concentration_a/max_a, ...
                 this.times, this.concentration_obs/max_obs);
            title(sprintf('AutoradiographyDirector.plotInitialData:  %s', this.ecat.fileprefix), 'Interpreter', 'none');
            legend('aif', 'ecat');
            xlabel('time/s');
            ylabel(sprintf('well-counts/mL/s; rescaled %g, %g', max_a, max_obs));
        end
        function        plotProduct(this)
            figure;
            plot(this.times, this.estimateData, this.times, this.dependentData, 'o');
            legend('Bayesian concentration_i', 'concentration_obj from data');
            title(sprintf('DSCAutoradiography.plotProduct:  A0 %g, PS %g, a %g, d %g, f %g, p %g, q0 %g t0 %g', ...
                this.A0, this.PS, this.a, this.d, this.f, this.p, this.q0, this.t0), 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end        
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlpet.DSCAutoradiography')));
            assert(isnumeric(vars));
            switch (par)
                case 'A0'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.PS this.a  this.d  this.f  this.p  this.q0 this.t0 this.times this.concentration_a }; end
                case 'PS'
                    for v = 1:length(vars)
                        args{v} = { this.A0 vars(v) this.a  this.d  this.f  this.p  this.q0 this.t0 this.times this.concentration_a }; end
                case 'a'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS vars(v) this.d  this.f  this.p  this.q0 this.t0 this.times this.concentration_a }; end
                case 'd'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  vars(v) this.f  this.p  this.q0 this.t0 this.times this.concentration_a }; end
                case 'f'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  vars(v) this.p  this.q0 this.t0 this.times this.concentration_a }; end
                case 'p'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  this.f  vars(v) this.q0 this.t0 this.times this.concentration_a }; end
                case 'q0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  this.f  this.p  vars(v) this.t0 this.times this.concentration_a }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  this.f  this.p  this.q0 vars(v) this.times this.concentration_a }; end
            end
            this.plotParArgs(par, args, vars);
        end
        function ps   = adjustParams(this, ps)
            manager = this.paramsManager;
            if (ps(manager.paramsIndices('f'))  > ps(manager.paramsIndices('PS')))
                tmp                             = ps(manager.paramsIndices('PS'));
                ps(manager.paramsIndices('PS')) = ps(manager.paramsIndices('f'));
                ps(manager.paramsIndices('f')) = tmp;
            end
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
            title(sprintf('A0 %g, PS %g, a %g, d %g, f %g, p %g, q0 %g, t0 %g', ...
                          argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}, argsv{7}, argsv{8}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

