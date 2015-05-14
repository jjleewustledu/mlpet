classdef PETHerscAutoradiography < mlpet.AutoradiographyBuilder
	%% PETHERSCAUTORADIOGRAPHY
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
        A0 = 0.05
        PS = 0.0182 %  mL/s/mL, [15O]H_2O
        f  = 0.00928 % mL/s/mL, [15O]H_2O
        t0 = 0.045847
    end

    properties (Dependent)
        baseTitle
        detailedTitle
        map 
    end
    
    methods %% GET/SET 
        function bt = get.baseTitle(this)
            bt = sprintf('PET Hersc. %s', this.pnum);
        end
        function dt = get.detailedTitle(this)
            dt = sprintf('%s:\nA0 %g, PS %g, f %g, t0 %g', ...
                         this.baseTitle, this.A0, this.PS, this.f, this.t0);
        end
        function m  = get.map(this)
            fL = 1; fH = 1;
            m = containers.Map;
            m('A0') = struct('fixed', 0, 'min', fL*0.01,   'mean', this.A0, 'max', fH* 1);
            m('PS') = struct('fixed', 0, 'min', fL*0.0093, 'mean', this.PS, 'max', fH* 0.0367); % physiologic range +/- sigma, Herscovitch, JCBFM 7:527-541, 1987, table 2
            m('f')  = struct('fixed', 1, 'min', fL*0.0050, 'mean', this.f,  'max', fH* 0.0155); % 
            m('t0') = struct('fixed', 0, 'min',    0,      'mean', this.t0, 'max', fH*20);
        end
    end
    
    methods (Static)
        function this = load(maskFn, aifFn, ecatFn, varargin)
            
            p = inputParser;
            addRequired(p, 'maskFn', @(x) lexist(x, 'file'));
            addRequired(p, 'aifFn',  @(x) lexist(x, 'file'));
            addRequired(p, 'ecatFn', @(x) lexist(x, 'file'));
            addOptional(p, 'aifShift',   0, @(x) isnumeric(x) && isscalar(x));
            addOptional(p, 'ecatShift', 10, @(x) isnumeric(x) && isscalar(x));
            parse(p, maskFn, aifFn, ecatFn, varargin{:});
            
            import mlfourd.* mlpet.*;
            mask = PETHerscAutoradiography.loadMask(p.Results.maskFn); 
            aif  = PETHerscAutoradiography.loadAif(p.Results.aifFn); 
            ecat = PETHerscAutoradiography.loadEcat(p.Results.ecatFn);            
            args = PETHerscAutoradiography.interpolateData(mask, aif, ecat, p.Results.aifShift, p.Results.ecatShift); 
            this = PETHerscAutoradiography(args{:});
        end
        function aif  = loadAif(varargin)
            p = inputParser;
            addOptional(p, 'fqfn',      [], @(x) lexist(x, 'file'));
            addOptional(p, 'iwelldata', [], @(x) isa(x, 'mlpet.IWellData'));
            parse(p, varargin{:});
            
            import mlpet.*;
            if (~isempty(p.Results.fqfn))
                aif = UncorrectedDCV.load(p.Results.fqfn);
                return
            end
            if (~isempty(p.Results.iwelldata))
                aif = p.Results.iwelldata;
                return
            end
            error('mlpet:requiredObjectNotFound', 'PETHerscAutoradiography.loadMask');
        end
        function this = simulateMcmc(A0, PS, f, t0, t, conc_a, map)
            import mlpet.*;       
            conc_i = PETHerscAutoradiography.concentration_i(A0, PS, f, t0, t, conc_a); % simulated
            this   = PETHerscAutoradiography(conc_a, t, conc_i);
            this   = this.estimateParameters(map) %#ok<NOPRT>
        end   
        function this = runAutoradiography(conc_a, t, conc_obs)
            %% RUNAUTORADIOGRAPHY is deprecated; used by legacy Test_PETAutoradiography
            %  Usage:   PETHerscAutoradiography.runAutoradiography(arterial_counts, times, scanner_counts) 
            %                                                     ^ well-counts/s/mL       ^
            %                                                                       ^ s
            
            import mlpet.*;
            this = PETHerscAutoradiography(conc_a, t, conc_obs);
            this = this.estimateParameters(this.map);            
        end
        function ci   = concentration_i(A0, PS, f, t0, t, conc_a)
            import mlpet.*;
            lambda = PETHerscAutoradiography.LAMBDA;
            lambda_decay = PETHerscAutoradiography.LAMBDA_DECAY;
            m      = 1 - exp(-PS / f);
            ci0    = A0 * m * f * conv(conc_a, exp(-(m * f / lambda + lambda_decay) * t));
            ci0    = ci0(1:length(t));
            %assert(all(isfinite(ci0)), 'ci -> %s', num2str(ci0));
            
            idx_t0 = PETHerscAutoradiography.indexOf(t, t0);
            ci     = zeros(1, length(t));
            ci(idx_t0:end) = ci0(1:end-idx_t0+1);
            ci     = abs(ci);
        end
        function args = interpolateData(mask, aif, ecat, aifShift, ecatShift)
            ecat = ecat.masked(mask);
            ecatSkinny = ecat.volumeSummed;  
            ecatSkinny.img = ecatSkinny.img/mask.count;
            
            import mlpet.*;
            [t_a,c_a] = PETHerscAutoradiography.shiftDataLeft(        aif.times,        aif.wellCounts, aifShift);
            [t_i,c_i] = PETHerscAutoradiography.shiftDataRight(ecatSkinny.times, ecatSkinny.becquerels, ecatShift);        
            dt  = min(min(aif.taus), min(ecatSkinny.taus));
            t   = min(t_a(1), t_i(1)):dt:min([t_a(end) t_i(end) PETAutoradiography.TIME_SUP]);
            c_a = pchip(t_a, c_a, t);
            c_i = pchip(t_i, c_i, t);            
            args = {c_a t c_i mask aif ecat};
        end
    end
    
	methods	  
 		function this = PETHerscAutoradiography(varargin)
 			%% PETHERSCAUTORADIOGRAPHY 
 			%  Usage:  this = PETHerscAutoradiography( ...
            %                 concentration_a, times_i, concentration_i[, mask, aif, ecat]) 
            %                 ^ counts/s/mL    ^ s      ^ counts/s/g
            %                                                             ^ INIfTId
            %                                                                   ^ ILaif, IWellData 
            %                                                                        ^ IScannerData

 			this = this@mlpet.AutoradiographyBuilder(varargin{:}); 
            this.expectedBestFitParams_ = [this.A0 this.PS this.f this.t0]'; % initial expected values from properties
        end 
        
        function this = simulateItsMcmc(this, conc_a)
            this = this.simulateMcmc( ...
                   this.A0, this.PS, this.f, this.t0, this.times, conc_a, this.map);
        end
        function ci   = itsConcentration_i(this)
            ci = this.concentration_i( ...
                 this.A0, this.PS, this.f, this.t0, this.times, this.concentration_a);
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
            this.ensureKeyOrdering({'A0' 'PS' 'f' 't0'});
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.A0 = this.finalParams('A0');
            this.PS = this.finalParams('PS');
            this.f  = this.finalParams('f');
            this.t0 = this.finalParams('t0');
        end
        function ed   = estimateData(this)
            keys = this.paramsManager.paramsMap.keys;
            ed = this.estimateDataFast( ...
                this.finalParams(keys{1}), ...
                this.finalParams(keys{2}), ...
                this.finalParams(keys{3}), ...
                this.finalParams(keys{4}));
        end
        function ed   = estimateDataFast(this, A0, PS, f, t0)
            ed = this.concentration_i( ...
                       A0, PS, f, t0, this.times, this.concentration_a);
        end
        function ps   = adjustParams(this, ps)
            manager = this.paramsManager;
            if (ps(manager.paramsIndices('f'))  > ps(manager.paramsIndices('PS')))
                tmp                             = ps(manager.paramsIndices('PS'));
                ps(manager.paramsIndices('PS')) = ps(manager.paramsIndices('f'));
                ps(manager.paramsIndices('f')) = tmp;
            end
        end            
        
        function        plotProduct(this)
            figure;
            max_i = max(max( this.itsConcentration_i), max(this.concentration_obs));
            max_a = max(     this.concentration_a);
            plot(this.times, this.itsConcentration_i / max_i, ...
                 this.times, this.concentration_a    / max_a, 's', ...
                 this.times, this.concentration_obs  / max_i, 'o');
            legend('Bayesian concentration_i', 'DCV from data',  'concentration_{obs} from data');
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary:  C_i norm %g, C_a norm %g', max_i, max_a));
        end 
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlpet.PETHerscAutoradiography')));
            assert(isnumeric(vars));
            switch (par)
                case 'A0'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.PS this.f  this.t0 this.times this.concentration_a }; end
                case 'PS'
                    for v = 1:length(vars)
                        args{v} = { this.A0 vars(v) this.f  this.t0 this.times this.concentration_a }; end
                case 'f'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS vars(v) this.t0 this.times this.concentration_a }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.f  vars(v) this.times this.concentration_a }; end
            end
            this.plotParArgs(par, args, vars);
        end
        function this = save(this)   
            this = this.saveas('PETHerscAutoradiography.save.mat');
        end
        function this = saveas(this, fn)  
            petHerscAutoradiography = this; %#ok<NASGU>
            save(fn, 'petHerscAutoradiography');         
        end  
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function plotParArgs(this, par, args, vars)
            assert(lstrfind(par, properties('mlpet.PETHerscAutoradiography')));
            assert(iscell(args));
            assert(isnumeric(vars));
            import mlpet.*;
            figure
            hold on
            for v = 1:size(args,2)
                argsv = args{v};
                plot(this.times, PETHerscAutoradiography.concentration_i(argsv{:}));
            end
            title(sprintf('A0 %g, PS %g, f %g, t0 %g', argsv{1}, argsv{2}, argsv{3}, argsv{4}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

