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
        A0 = 0.1
        PS = 0.0182 % mL/s/mL, [15O]H_2O, mean human value from Herscovitch 1987
        a  = 1.009767
        d  = 1.092760
        f  = 0.00928 % mL/s/mL, [15O]H_2O, mean human value from Herscovitch 1987
        p  = 0.411130
        q0 = 0.4
        t0 = 0.045847
    end 

    properties (Dependent)
        baseTitle
        detailedTitle
        Z_bright
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
        function Z_b = get.Z_bright(this)
            Z_b = this.Z_bright_;
        end
        function m  = get.map(this)
            fL = 1; fH = 1;
            m = containers.Map;
            m('A0') = struct('fixed', 1, 'min', fL*0.05,   'mean', this.A0, 'max', fH* 0.25);
            m('PS') = struct('fixed', 1, 'min', fL*0.0093, 'mean', this.PS, 'max', fH* 0.0367); % physiologic range +/- sigma, Herscovitch, JCBFM 7:527-541, 1987, table 2
            m('f')  = struct('fixed', 1, 'min', fL*0.0053, 'mean', this.f,  'max', fH* 0.0155); % 
            m('t0') = struct('fixed', 0, 'min',    0,      'mean', this.t0, 'max', fH*20);
            m('a')  = struct('fixed', 0, 'min', fL*1.0,    'mean', this.a,  'max', fH* 1.3);
            m('d')  = struct('fixed', 0, 'min', fL*1.0,    'mean', this.d,  'max', fH* 1.5);
            m('p')  = struct('fixed', 0, 'min', fL*0.38,   'mean', this.p,  'max', fH* 0.42); 
            m('q0') = struct('fixed', 0, 'min', fL*0.15,   'mean', this.q0, 'max', fH* 0.44);
        end
    end
    
    methods (Static)
        function this = load(maskFn, maskAifFn, aifFn, ecatFn, varargin)
            
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
            args = DSCHerscAutoradiography.interpolateData(mask, aif, ecat, ip.Results.aifShift, ip.Results.ecatShift); 
            this = DSCHerscAutoradiography(args{:});
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
                error('mlpet:requiredObjectNotFound', 'DSCHerscAutoradiography.loadMask');
            end
            storageFn = fullfile(wbDsc.filepath, 'DSCAutoradiography_loadAif_aif.mat');
            if (lexist(storageFn) && mlpet.DSCHerscAutoradiography.REUSE_STORED)
                load(storageFn);
                return
            end
            aif = mlperfusion.Laif2.runLaif(wbDsc.times, wbDsc.itsMagnetization); 
            save(storageFn, 'aif');
        end
        function this = simulateMcmc(A0, PS, a, d, f, p, q0, t0, t, concbar_a, Z_b, map)
            import mlpet.*;       
            conc_i = DSCHerscAutoradiography.concentration_i(A0, PS, a, d, f, p, q0, t0, t, concbar_a, Z_b); % simulated
            this   = DSCHerscAutoradiography(concbar_a, t, conc_i);
            this   = this.estimateParameters(map) %#ok<NOPRT>
        end   
        function this = runAutoradiography(concbar_a, t, conc_obs)
            %% RUNAUTORADIOGRAPHY is deprecated; used by legacy Test_PETAutoradiography
            %  Usage:   DSCHerscAutoradiography.runAutoradiography(arterial_counts, times, scanner_counts) 
            %                                                 ^ well-counts/s/mL      ^
            %                                                                  ^ s
            
            import mlpet.*;
            this = DSCHerscAutoradiography(concbar_a, t, conc_obs);
            this = this.estimateParameters(this.map);            
        end
        function ci   = concentration_i(A0, PS, a, d, f, p, q0, t0, t, concbar_a, Z_b)
            import mlpet.*;
            lambda = DSCHerscAutoradiography.LAMBDA;
            lambda_decay = DSCHerscAutoradiography.LAMBDA_DECAY;
            
            m      = 1 - exp(-PS/f);
            conc_a = DSCHerscAutoradiography.q_est(A0, a, d, f, p, q0, t, concbar_a, Z_b) * ...
                     conv(concbar_a, DSCHerscAutoradiography.kernel(a,d,p,t));
            conc_a = conc_a(1:length(t));
            ci0    = A0 * m * f * abs(conv(conc_a, exp(-(m * f / lambda + lambda_decay) * t)));
            ci0    = ci0(1:length(t));
            %assert(all(isfinite(ci0)), 'ci -> %s', num2str(ci0));
            
            idx_t0 = DSCHerscAutoradiography.indexOf(t, t0);
            ci     = zeros(1, length(t));
            ci(idx_t0:end) = ci0(1:end-idx_t0+1);
            ci     = abs(ci);
        end
        function q    = q_est(A0, a, d, ~, p, q0, t, concbar_a, Z_b)
            import mlpet.*;
            q = Z_b / ...
                (q0 * A0 * DSCHerscAutoradiography.Zbar_a(a, d, p, t, concbar_a));
        end      
        function Zb_a = Zbar_a(a, d, p, t, concbar_a)
            Zb_a = conv(concbar_a, mlpet.DSCHerscAutoradiography.kernel(a,d,p,t));
            Zb_a = Zb_a(1:length(t));
            dt   = t(2) - t(1);
            Zb_a = dt * sum(Zb_a);
        end
        function k    = kernel(a, d, p, t)
            cnorm = ((p/a^d)/gamma(d/p));
            k     = cnorm * t.^(d-1) .* exp(-(t/a).^p);
        end
        function args = interpolateData(mask, aif, ecat, ~, ecatShift)
            ecat       = ecat.masked(mask);
            ecatSkinny = ecat.volumeSummed;   
            ecatSkinny.img = ecatSkinny.img/mask.count;
            
            import mlpet.*;
            [t_a,c_a] = DSCHerscAutoradiography.shiftDataLeft(       aif.times,        aif.itsKAif_2,  aif.t0);
            [t_i,c_i] = DSCHerscAutoradiography.shiftDataLeft(ecatSkinny.times, ecatSkinny.wellCounts, ecatShift); 
            dt  = min(min(aif.taus), min(ecatSkinny.taus));
            t   = min(t_a(1), t_i(1)):dt:min([t_a(end) t_i(end) DSCHerscAutoradiography.TIME_SUP]);
            c_a = pchip(t_a, c_a, t);
            c_i = pchip(t_i, c_i, t);            
            args = {c_a t c_i mask aif ecat};
        end
    end
    
	methods	  
 		function this = DSCHerscAutoradiography(varargin)
 			%% DSCHERSCAUTORADIOGRAPHY 
 			%  Usage:  this = DSCHerscAutoradiography( ...
            %                 concentrationBar_a, times_i, concentration_i[, mask, aif, ecat]) 
            %                 ^ counts/s/mL    ^ s         ^ counts/s/g
            %                                                                ^ INIfTId
            %                                                                      ^ ILaif, IWellData 
            %                                                                           ^ IScannerData

 			this = this@mlpet.AutoradiographyBuilder(varargin{:}); 
            this = this.estimateZ_bright_;
            this.expectedBestFitParams_ = [this.A0 this.PS this.a this.d this.f this.p this.q0 this.t0]'; % initial expected values from properties
        end 
        
        function this = simulateItsMcmc(this, concbar_a)
            this = mlpet.DSCHerscAutoradiography.simulateMcmc( ...
                   this.A0, this.PS, this.a, this.d, this.f, this.p, this.q0, this.t0, this.times, concbar_a, this.Z_bright_, this.map);
        end
        function ci   = itsConcentration_i(this)
            ci = this.concentration_i( ...
                 this.A0, this.PS, this.a, this.d, this.f, this.p, this.q0, this.t0, this.times, this.concentrationBar_a, this.Z_bright_);
        end 
        function ca   = itsBayesianConcentration_a(this)
            import mlpet.*;
            ca = this.itsQ_est * ...
                 conv(this.concentrationBar_a, this.kernel( ...
                                               this.a, this.d, this.p, this.times));
            ca = ca(1:this.length);
        end
        function q    = itsQ_est(this)
            q = this.q_est(this.A0, this.a, this.d, this.f, this.p, this.q0, this.times, this.concentrationBar_a, this.Z_bright_);
        end
        function this = estimateAll(this)
            this = this.estimateParameters(this.map);
            fprintf('FINAL STATS q_est from Z_bright %g\n', this.itsQ_est);
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
            ed = mlpet.DSCHerscAutoradiography.concentration_i( ...
                       A0, PS, a, d, f, p, q0, t0, this.times, this.concentrationBar_a, this.Z_bright_);
        end
        function ps   = adjustParams(this, ps)
            if (this.map('PS').fixed)
                return; end
            manager = this.paramsManager;
            if (ps(manager.paramsIndices('f'))  > ps(manager.paramsIndices('PS')))
                tmp                             = ps(manager.paramsIndices('PS'));
                ps(manager.paramsIndices('PS')) = ps(manager.paramsIndices('f'));
                ps(manager.paramsIndices('f')) = tmp;
            end
        end
        
        function        plotProduct(this)
            figure;
            dcv      = this.itsDcv;
            dcvTimes = dcv.times - this.aif.t0;
            max_i = max(max(this.itsConcentration_i),         max(this.concentration_obs));
            max_a = max(max(this.itsBayesianConcentration_a), max(dcv.wellCounts));
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
            assert(lstrfind(par, properties('mlpet.DSCHerscAutoradiography')));
            assert(isnumeric(vars));
            switch (par)
                case 'A0'
                    for v = 1:length(vars)
                        args{v} = { vars(v) this.PS this.a  this.d  this.f  this.p  this.q0 this.t0 this.times this.concentrationBar_a }; end
                case 'PS'
                    for v = 1:length(vars)
                        args{v} = { this.A0 vars(v) this.a  this.d  this.f  this.p  this.q0 this.t0 this.times this.concentrationBar_a }; end
                case 'a'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS vars(v) this.d  this.f  this.p  this.q0 this.t0 this.times this.concentrationBar_a }; end
                case 'd'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  vars(v) this.f  this.p  this.q0 this.t0 this.times this.concentrationBar_a }; end
                case 'f'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  vars(v) this.p  this.q0 this.t0 this.times this.concentrationBar_a }; end
                case 'p'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  this.f  vars(v) this.q0 this.t0 this.times this.concentrationBar_a }; end
                case 'q0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  this.f  this.p  vars(v) this.t0 this.times this.concentrationBar_a }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.A0 this.PS this.a  this.d  this.f  this.p  this.q0 vars(v) this.times this.concentrationBar_a }; end
            end
            this.plotParArgs(par, args, vars);
        end
        function this = save(this)   
            this = this.saveas('DSCHerscAutoradiography.save.mat');
        end
        function this = saveas(this, fn)  
            dscHerscAutoradiography = this; %#ok<NASGU>
            save(fn, 'dscHerscAutoradiography');         
        end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        Z_bright_
    end
    
    methods (Access = 'private')
        function this = estimateZ_bright_(this)
            intDtCi = this.integralDtConcentration_i;
            voxels  = intDtCi(this.mask.img ~= 0); % Nx1 double
            voxels  = sort(voxels);
            
            idx98 = floor(0.98 * length(voxels));
            this.Z_bright_ = voxels(idx98);
            fprintf('DSCAutoradiography.estimateZ_bright_ -> %g\n', this.Z_bright_);
        end        
        function int  = integralDtConcentration_i(this)  
            %assert(this.uniformSampling(this.ecat.times));
            numScanFrames = ceil((this.timeFinal - this.timeInitial) / this.ecat.dt);          
            int = this.ecat.wellCounts(:,:,:,1);
            for sf = 2:numScanFrames
                int = int + this.ecat.wellCounts(:,:,:,sf); end
            int = int * this.ecat.dt; 
        end
        
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
            title(sprintf('A0 %g, PS %g, a %g, d %g, f %g, p %g, q0 %g, t0 %g', ...
                          argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}, argsv{7}, argsv{8}));
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

