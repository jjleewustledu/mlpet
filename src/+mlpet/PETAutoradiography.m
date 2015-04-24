classdef PETAutoradiography < mlpet.AutoradiographyBuilder
	%% PETAUTORADIOGRAPHY
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
        baseTitle = 'PET Autoradiography'
        xLabel    = 'times/s'
        yLabel    = 'concentration/(well-counts/mL/s)'
        
        A0 = 0.068093
        PS = 0.0173 % cm^3/s/g, [15O]H_2O
        f  = 0.0096525 % mL/s/g,   [15O]H_2O
        t0 = 0.007868
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
            m('A0') = struct('fixed', 1, 'min', this.priorLow(this.A0), 'mean', this.A0, 'max', this.priorHigh(this.A0));
            m('PS') = struct('fixed', 1, 'min', 0.013,                  'mean', this.PS, 'max', 0.025333); % physiologic range, Herscovitch, JCBFM 7:527-541, 1987, table 2.
            m('f')  = struct('fixed', 0, 'min', 0.0053,                 'mean', this.f,  'max', 0.012467); % 
            m('t0') = struct('fixed', 1, 'min', 0,                      'mean', this.t0, 'max', 15);
        end
    end
    
    methods (Static)
        function this = load(maskFn, aifFn, pie, ecatFn, varargin)
            
            p = inputParser;
            addRequired(p, 'maskFn', @(x) lexist(x, 'file'));
            addRequired(p, 'aifFn',  @(x) lexist(x, 'file'));
            addRequired(p, 'pie',    @(x) isnumeric(x) && isscalar(x));
            addRequired(p, 'ecatFn', @(x) lexist(x, 'file'));
            addOptional(p, 'aifShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(p, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(p, maskFn, aifFn, pie, ecatFn, varargin{:});
            
            import mlfourd.* mlpet.*;
            mask = PETAutoradiography.loadMask(p.Results.maskFn); 
            aif  = PETAutoradiography.loadAif(p.Results.aifFn); 
            ecat = PETAutoradiography.loadEcat(p.Results.pie, p.Results.ecatFn);            
            args = PETAutoradiography.interpolateData(mask, aif, ecat, p.Results.aifShift, p.Results.ecatShift); 
            this = PETAutoradiography(args{:});
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
            error('mlpet:requiredObjectNotFound', 'PETAutoradiography.loadMask');
        end
        function this = simulateMcmc(A0, PS, f, t0, t, conc_a, map)
            import mlpet.*;       
            conc_i = PETAutoradiography.concentration_i(A0, PS, f, t0, t, conc_a); % simulated
            this   = PETAutoradiography(conc_a, t, conc_i);
            this   = this.estimateParameters(map) %#ok<NOPRT>
        end   
        function this = runAutoradiography(conc_a, t, conc_i)
            %% RUNAUTORADIOGRAPHY
            %  Usage:   PETAutoradiography.runAutoradiography(arterial_counts, times, scanner_counts) 
            %                                                 ^counts/s/mL     ^ s    ^ counts/s/g
            
            import mlpet.*;
            this = PETAutoradiography(conc_a, t, conc_i*PETAutoradiography.BRAIN_DENSITY);
            this = this.estimateParameters(this.map);            
            %fprintf('PETAutoradiography.runAutoradiography:  A0 %g, PS %g, f %g, t0 %g\n', this.A0, this.PS, this.f, this.t0);
        end
        function ci   = concentration_i(A0, PS, f, t0, t, conc_a)
            import mlpet.*;
            lambda = PETAutoradiography.LAMBDA;
            lambda_decay = PETAutoradiography.LAMBDA_DECAY;
            if (PETAutoradiography.HERSCOVITCH_CORRECTION)
                m  = 1 - exp(-PS / f);
            else
                m  = 1;
            end
            ci0    = A0 * m * f * conv(conc_a, exp(-(m*f/lambda + lambda_decay) * t));
            ci0    = ci0(1:length(t));
            assert(all(isfinite(ci0)), 'ci -> %s', num2str(ci0));
            
            idx_t0 = PETAutoradiography.indexOf(t, t0);
            ci     = zeros(1, length(t));
            ci(idx_t0:end) = ci0(1:end-idx_t0+1);
            ci     = abs(ci);
        end
        function args = interpolateData(mask, aif, ecat, aifShift, ecatShift)
            ecat = ecat.masked(mask);
            ecat = ecat.volumeSummed;   
            import mlpet.*;
            [t_a,c_a] = PETAutoradiography.shiftDataLeft( aif.times,  aif.wellCounts,               aifShift);
            [t_i,c_i] = PETAutoradiography.shiftDataLeft(ecat.times, ecat.wellCounts/ecat.nPixels, ecatShift);        
            dt  = min(min(aif.taus), min(ecat.taus));
            t   = min(t_a(1), t_i(1)):dt:min(t_a(end), t_i(end));
            c_a = pchip(t_a, c_a, t);
            c_i = pchip(t_i, c_i, t);            
            args = {c_a t c_i mask aif ecat};
        end
    end
    
	methods	  
 		function this = PETAutoradiography(conc_a, times_i, conc_i, varargin)
 			%% PETAUTORADIOGRAPHY 
 			%  Usage:  this = PETAutoradiography(concentration_a, times_i, concentration_i) 
            %                                    ^ counts/s/mL    ^ s      ^ counts/s/g

 			this = this@mlpet.AutoradiographyBuilder(times_i, conc_i); 
            p = inputParser;
            addRequired(p, 'conc_a',  @isnumeric);
            addRequired(p, 'times_i', @isnumeric);
            addRequired(p, 'conc_i',  @isnumeric);
            addOptional(p, 'mask', [], @(x) isa(x, 'mlfourd.INIfTId'));
            addOptional(p, 'aif',  [], @(x) isa(x, 'mlpet.IWellData'));
            addOptional(p, 'ecat', [], @(x) isa(x, 'mlpet.IScannerData'));
            parse(p, conc_a, times_i, conc_i, varargin{:});
            
            this.concentration_a_ = p.Results.conc_a;
            this.mask_            = p.Results.mask;
            this.aif_             = p.Results.aif;
            this.ecat_            = p.Results.ecat;
            this.expectedBestFitParams_ = [this.A0 this.PS this.f this.t0]'; % initial expected values from properties
        end 
        
        function this = simulateItsMcmc(this, conc_a)
            this = mlpet.PETAutoradiography.simulateMcmc( ...
                   this.A0, this.PS, this.f, this.t0, this.times, conc_a, this.map);
        end
        function ci   = itsConcentration_i(this)
            ci = mlpet.PETAutoradiography.concentration_i(this.A0, this.PS, this.f, this.t0, this.times, this.concentration_a);
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
            ed = mlpet.PETAutoradiography.concentration_i( ...
                       A0, PS, f, t0, this.times, this.concentration_a);
        end
        function x    = priorLow(~, x)
            x = 0.5*x;
        end
        function x    = priorHigh(~, x)
            x = 2*x;
        end
        function        plotInitialData(this)
            figure;
            semilogy(this.times, this.concentration_a, ...
                     this.times, this.concentration_obs);
            title(sprintf('AutoradiographyDirector.plotInitialData:  %s', this.ecat.fileprefix), 'Interpreter', 'none');
            legend('aif', 'ecat');
            xlabel('time/s');
            ylabel('well-counts/mL/s');
        end
        function        plotProduct(this)
            figure;
            plot(this.times, this.estimateData, this.times, this.dependentData, 'o');
            legend('Bayesian concentration_i', 'concentration_obj from data');
            title(sprintf('PETAutoradiography.plotProduct:  A0 %g, PS %g, f %g, t0 %g', this.A0, this.PS, this.f, this.t0), 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end        
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlpet.PETAutoradiography')));
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
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function plotParArgs(this, par, args, vars)
            assert(lstrfind(par, properties('mlpet.PETAutoradiography')));
            assert(iscell(args));
            assert(isnumeric(vars));
            import mlpet.*;
            figure
            hold on
            for v = 1:size(args,2)
                argsv = args{v};
                plot(this.times, PETAutoradiography.concentration_i(argsv{:}));
            end
            title(sprintf('A0 %g, PS %g, f %g, t0 %g', argsv{1}, argsv{2}, argsv{3}, argsv{4}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

