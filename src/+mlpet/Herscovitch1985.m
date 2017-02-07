classdef Herscovitch1985 < mlpet.AbstractHerscovitch1985
	%% HERSCOVITCH1985  
    %  See also:
    %  1. Herscovitch P, Mintun MA, Raichle ME (1985) Brain oxygen utilization measured with oxygen-15 radiotracers and 
    %  positron emission tomography: generation of metabolic images. J Nucl Med 26(4):416?417.
    %  2. Videen TO, Perlmutter JS, Herscovitch P, Raichle ME (1987) Brain blood volume, flow, and oxygen utilization 
    %  measured with 15O radiotracers and positron emission tomography: revised metabolic computations. 
    %  J Cereb Blood Flow Metab 7(4):513?516.

	%  $Revision$
 	%  was created 28-Jan-2017 12:53:40
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

    properties (Constant)
        LAMBDA = 0.95           % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        LAMBDA_DECAY = 0.005677 % KLUDGE:  hard-coded [15O] half-life for propagating to static methods
        BRAIN_DENSITY = 1.05    % assumed mean brain density, g/mL
        RBC_FACTOR = 0.766      % per Tom Videen, metproc.inc, line 193  
        SMALL_LARGE_HCT_RATIO = 0.85 % Grubb, et al., 1978
        
        MAGIC = 0.5711 % KLUDGE
    end
    
    properties
        a1 % CBF per Videen 1987
        a2
        b1 % OEF per Videen 1987
        b2
        b3
        b4
        canonFlows = 10:10:100 % mL/100 g/min
        cbf
        cbv
        ooPeakTime   % time of peak of O[15O] AIF
        ooFracTime   % time of measuring H2[15O] of metabolism in plasma 
        fracHOMetab % fraction of H2[15O] in whole blood
    end
    
	properties (Dependent)
        aif
        aifHOMetab
        aifOO
        aifOOIntegral
        scanner
        aifTimeShift
        mask
        scannerTimeShift        
        tracer
        videenBlur
        voxelVolume
    end
    
    methods %% GET, SET
        function g = get.aif(this)
            g = this.aif_;
        end
        function g = get.aifHOMetab(this)
            g = this.aifHOMetab_;
        end
        function g = get.aifOO(this)
            g = this.aifOO_;
        end
        function g = get.aifOOIntegral(this)
            g = this.aifOOIntegral_;
        end
        function g = get.scanner(this)
            g = this.scanner_;
        end
        function g = get.aifTimeShift(this)
            g = this.aif_.aifTimeShift;
        end
        function g = get.mask(this)
            g = this.mask_;
        end
        function g = get.scannerTimeShift(this)
            g = this.scanner_.scannerTimeShift;
        end        
        function g = get.tracer(this)
            g = this.sessionData.tracer;
        end
        function this = set.tracer(this, s)
            assert(ischar(s));
            this.sessionData_.tracer = s;
        end        
        function g = get.videenBlur(this) %#ok<MANU>
            fhalf = 0.3; % half-wave number in cm^{-1}; cf. gauss_4dfp
            fwhh  = 10*2*log(2)/(pi*fhalf);
            g     = fwhh*[1 1 1];
        end
        function g = get.voxelVolume(this)
            g = prod(this.scanner_.mmppix(1:3)/10); % cm^3
        end
    end

    methods (Static)
        function petobs = estimatePetdyn(aif, cbf)
            assert(isa(aif, 'mlpet.IAifData'));
            assert(isnumeric(cbf));  
            
            import mlpet.*;
            f = Herscovitch1985.cbfToInvs(cbf);
            lam  = Herscovitch1985.LAMBDA;
            lamd = Herscovitch1985.LAMBDA_DECAY;  
            aifti = ensureRowVector(aif.timeInterpolants);
            aifwi = ensureRowVector(aif.wellCountInterpolants);
            petobs = zeros(length(f), length(aifti));
            for r = 1:size(petobs,1)
                petobs_ = (1/aif.W)*f(r)*conv(aifwi, exp(-(f(r)/lam + lamd)*aifti));
                petobs(r,:) = petobs_(1:length(aifti));
            end
        end
        function petobs = estimatePetobs(aif, cbf)
            assert(isa(aif, 'mlpet.IAifData'));
            assert(isnumeric(cbf));
            
            import mlpet.*;
            rho = Herscovitch1985.estimatePetdyn(aif, cbf);
            petobs = aif.dt*trapz(rho, 2);
        end
        function cbf    = estimateModelCbf(As, petobs)
            cbf = petobs.^2*As(1) + petobs*As(2);
        end        
        
        function cbf = invsToCbf(f)
            cbf = 6000*f/mlpet.Herscovitch1985.BRAIN_DENSITY;
        end
        function f   = cbfToInvs(cbf)
            f = cbf*mlpet.Herscovitch1985.BRAIN_DENSITY/6000;
        end
    end
    
	methods
 		function this = Herscovitch1985(varargin)
 			%% HERSCOVITCH1985
 			%  @param named sessionData
 			            
            this = this@mlpet.AbstractHerscovitch1985(varargin{:});
            
            ip = inputParser;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'));
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.IScannerData'));
            addParameter(ip, 'aif', [], @(x) isa(x, 'mlpet.IAifData'));
            addParameter(ip, 'timeDuration', 40, @isnumeric);
            parse(ip, varargin{:});
            
            import mlpet.*;            
            this.scanner_ = ip.Results.scanner;            
            this.scanner_.timeDuration = ip.Results.timeDuration;
            this.aif_ = ip.Results.aif;
            if (ip.Results.timeDuration > 0)
                this.aif_.timeDuration = ip.Results.timeDuration;
            end
        end
        
        function this = buildA1A2(this)
            petobs = mlpet.Herscovitch1985.estimatePetobs(this.aif, this.canonFlows);
            this = this.buildModelCbf(petobs, this.canonFlows);
            model = this.product;
            this.product_ = [ ...
                model.Coefficients{1, 'Estimate'} ...
                model.Coefficients{2, 'Estimate'}];
        end
        function this = buildB1B2(this)
            this = this.ensureAifHOMetab;
            flowHOMetab = this.aif.W* ...
                mlpet.Herscovitch1985.estimatePetobs(this.aifHOMetab, this.canonFlows);
            this = this.buildModelOOFlow(flowHOMetab, this.canonFlows);
            model = this.product;
            this.product_ = [ ...
                model.Coefficients{1, 'Estimate'} ...
                model.Coefficients{2, 'Estimate'}];
        end
        function this = buildB3B4(this)
            this = this.ensureAifOO;
            flowOO = this.aif.W* ...
                mlpet.Herscovitch1985.estimatePetobs(this.aifOO, this.canonFlows);
            this = this.buildModelOOFlow(flowOO, this.canonFlows);
            model = this.product;
            this.product_ = [ ...
                model.Coefficients{1, 'Estimate'} ...
                model.Coefficients{2, 'Estimate'}];
        end
        function this = buildModelCbf(this, petobs, cbf)
            %% BUILDMODELCBF 
            %  @param petobs are numeric PETobs := \int_{t \in \text{obs}} dt' \varrho(t').
            %  @param cbf are numeric CBF.
            %  @returns this with this.product := mdl.  A1, A2 are in mdl.Coefficients{:,'Estimate'}.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            fprintf('Herscovitch1985.buildA1A2 ..........\n');
            mdl    = fitnlm( ...
                ensureColVector(petobs), ensureColVector(cbf), @mlpet.Herscovitch1985.estimateModelCbf, [1 1]);            
            disp(mdl)
            fprintf('mdl.RMSE -> %g, min(rho) -> %g, max(rho) -> %g\n', mdl.RMSE, min(petobs), max(petobs));
            if (isempty(getenv(upper('Test_Herscovitch1985'))))
                plotResiduals(mdl);
                plotDiagnostics(mdl, 'cookd');
                plotSlice(mdl);
            end
            this.product_ = mdl;
        end
        function this = buildModelOOFlow(this, flows, cbf)
            %% BUILDMODELOOFLOW 
            %  @param petobs are numeric PETobs := \int_{t \in \text{obs}} dt' \varrho(t').
            %  @param cbf are numeric CBF.
            %  @returns this with this.product := mdl.  A1, A2 are in mdl.Coefficients{:,'Estimate'}.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            fprintf('Herscovitch1985.buildA1A2 ..........\n');
            mdl    = fitnlm( ...
                ensureColVector(cbf), ensureColVector(flows), @mlpet.Herscovitch1985.estimateModelCbf, [1 1]);            
            disp(mdl)
            fprintf('mdl.RMSE -> %g, min(rho) -> %g, max(rho) -> %g\n', mdl.RMSE, min(flows), max(flows));
            if (isempty(getenv(upper('Test_Herscovitch1985'))))
                plotResiduals(mdl);
                plotDiagnostics(mdl, 'cookd');
                plotSlice(mdl);
            end
            this.product_ = mdl;
        end
        function this = buildCbfMap(this)
            assert(~isempty(this.a1));
            assert(~isempty(this.a2));
            
            sc = this.scanner;
            sc = sc.petobs;
            sc.img = sc.img*this.MAGIC;            
            sc = sc.blurred(this.videenBlur);
            sc.img = this.a1*sc.img.*sc.img + this.a2*sc.img;
            sc.fileprefix = this.sessionData.cbf('typ', 'fp');
            %sc = sc.blurred(this.videenBlur);
            this.product_ = mlpet.PETImagingContext(sc.component);
        end
        function this = buildCbfWholebrain(this, varargin)
            this  = this.ensureMask;
            mskvs = this.mask.volumeSummed;
            
            this  = this.buildCbfMap;
            cbf   = this.product;
            cbf   = cbf.masked(msk.niftid);
            cbfvs = cbf.volumeSummed;
            this.product_ = cbfvs.double/mskvs.double;
        end
        function this = buildCbvMap(this)
            sc = this.scanner;
            sc = sc.petobs;
            sc.img = sc.img*this.MAGIC;            
            sc = sc.blurred(this.videenBlur);
            sc.img = 100*sc.img*this.aif.W/(this.RBC_FACTOR*this.BRAIN_DENSITY*this.aif.wellCountsIntegral);
            sc.fileprefix = this.sessionData.cbv('typ', 'fp');
            %sc = sc.blurred(this.videenBlur);
            this.product_ = mlpet.PETImagingContext(sc.component);
        end
        function this = buildCbvWholebrain(this, varargin)
            this  = this.ensureMask;
            mskvs = this.mask.volumeSummed;
            
            this  = this.buildCbvMap;
            cbv   = this.product;
            cbv   = cbv.masked(msk.niftid);
            cbfvs = cbv.volumeSummed;
            this.product_ = cbfvs.double/mskvs.double;
        end
            
        function this = buildOefMap(this)
            assert(~isempty(this.b1));
            assert(~isempty(this.b2));
            assert(~isempty(this.b3));
            assert(~isempty(this.b4));
            assert(~isempty(this.cbf));
            assert(~isempty(this.cbv));            
            this = this.ensureAifHOMetab;
            this = this.ensureAifOO;
            this = this.ensureAifOOIntegral;
            
            sc = this.scanner;
            sc = sc.petobs;
            sc.img = sc.img*this.MAGIC;
            sc = sc.blurred(this.videenBlur);
            nimg = this.oefNumer(sc.img);
            dimg = this.oefDenom;
            sc.img = nimg ./ dimg;
            sc.fileprefix = this.sessionData.oef('typ', 'fp');
            %sc = sc.blurred(this.videenBlur);
            this.product_ = mlpet.PETImagingContext(sc.component);
        end
        function this = buildOefWholebrain(this, varargin)
            this  = this.ensureMask;
            mskvs = this.mask.volumeSummed;
            
            this  = this.buildOefMap;
            oef   = this.product;
            oef   = oef.masked(msk.niftid);
            oefvs = oef.volumeSummed;
            this.product_ = oefvs.double/mskvs.double;
        end
        
        % support for buildOefWholebrain
        
        function nimg = oefNumer(this, petobs)
            vimg = this.cbv.niftid.img;
            nimg = petobs*this.aif.W - this.flowHOMetab - this.aifOOIntegral*vimg;
            
            this = this.ensureMask;
            nimg = nimg.*this.mask.niftid.img;
        end
        function dimg = oefDenom(this)
            vimg = this.cbv.niftid.img;
            dimg = this.flowOO - 0.835*this.aifOOIntegral*vimg;
            
            this = this.ensureMask;
            dimg = dimg.*this.mask.niftid.img;
            dimg(abs(dimg) < eps) = 1;
        end
        function f    = flowHOMetab(this)
            img = this.cbf.niftid.img;
            f = this.b1*img.^2 + this.b2*img;
        end
        function f    = flowOO(this)
            img = this.cbf.niftid.img;
            f = this.b3*img.^2 + this.b4*img;
        end
        function aifi = estimateAifOOIntegral(this)
            aifi = 0.01*this.SMALL_LARGE_HCT_RATIO*this.BRAIN_DENSITY*this.aifOO.countsIntegral;
        end
        function aif  = estimateAifOO(this)
            this = this.ensureAifHOMetab;
            aif = this.aif;
            aif.counts = this.aif.counts - this.aifHOMetab.counts;
        end
        function aif  = estimateAifHOMetab(this)
            aif       = this.aif;
            [~,idxP]  = max(aif.times > this.ooPeakTime);
            dfrac_dt  = this.fracHOMetab/(this.ooFracTime - aif.times(idxP));
            fracVec   = zeros(size(aif.times));
            fracVec(idxP:end) = dfrac_dt*(aif.times(idxP:end) - aif.times(idxP));            
            aif.counts = this.aif.counts.*fracVec;
        end
        
        function plotAif(this)
            figure;
            plot(this.aif.times, this.aif.wellCounts);
            sd = this.sessionData;
            title(sprintf('Herscovitch1985.plotAif:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotAifHOMetab(this)
            this = this.ensureAifHOMetab;
            figure;
            plot(this.aifHOMetab.times, this.aifHOMetab.wellCounts);
            sd = this.sessionData;
            title(sprintf('Herscovitch1985.plotAifHOMetab:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotAifOO(this)
            this = this.ensureAifOO;
            figure;
            plot(this.aifOO.times, this.aifOO.wellCounts);
            sd = this.sessionData;
            title(sprintf('Herscovitch1985.plotAifOO:\n%s %s', sd.sessionPath, sd.tracer));
        end
        function plotScannerWholebrain(this)
            this  = this.ensureMask;
            mskvs = this.mask.volumeSummed;
            
            wc = this.scanner.wellCountInterpolants.*msk.niftid.img/this.MAGIC/mskvs.double/this.voxelVolume;
            wc = squeeze(sum(sum(sum(wc))));
            plot(this.scanner.timeInterpolants, wc);
            hold on            
            plot(this.aif.timeInterpolants, this.aif.wellCountInterpolants);
            sd = this.sessionData;
            title(sprintf('Herscovitch1985.plotScannerWholebrain:\n%s %s', sd.sessionPath, sd.tracer));
        end        
        
    end 

    %% PRIVATE
    
	properties (Access = private)
 		aif_
        aifHOMetab_
        aifOO_
        aifOOIntegral_
        mask_
        scanner_
    end
    
    methods (Access = private)        
        function this = ensureAifHOMetab(this)
            if (isempty(this.aifHOMetab_))
                this.aifHOMetab_ = this.estimateAifHOMetab;
            end
        end
        function this = ensureAifOO(this)
            if (isempty(this.aifOO_))
                this.aifOO_ = this.estimateAifOO;
            end
        end
        function this = ensureAifOOIntegral(this)
            if (isempty(this.aifOOIntegral_))
                this.aifOOIntegral_ = this.estimateAifOOIntegral;
            end
        end
        function this = ensureMask(this)
            if (isempty(this.mask_))
                this.mask_ = this.sessionData.mask('typ', 'ImagingContext');
            end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

