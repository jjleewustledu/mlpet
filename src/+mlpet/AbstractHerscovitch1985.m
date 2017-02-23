classdef AbstractHerscovitch1985 < mlpipeline.AbstractDataBuilder
	%% ABSTRACTHERSCOVITCH1985  
    %  See also:
    %  1. Herscovitch P, Mintun MA, Raichle ME (1985) Brain oxygen utilization measured with oxygen-15 radiotracers and 
    %  positron emission tomography: generation of metabolic images. J Nucl Med 26(4):416?417.
    %  2. Videen TO, Perlmutter JS, Herscovitch P, Raichle ME (1987) Brain blood volume, flow, and oxygen utilization 
    %  measured with 15O radiotracers and positron emission tomography: revised metabolic computations. 
    %  J Cereb Blood Flow Metab 7(4):513?516.

	%  $Revision$
 	%  was created 06-Feb-2017 21:31:05
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee.
 	

    properties (Abstract)
        MAGIC
        TIME_DURATION
        canonFlows
    end
    
    properties (Constant)
        LAMBDA = 0.95           % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        LAMBDA_DECAY = 0.005677 % KLUDGE:  hard-coded [15O] half-life for propagating to static methods
        BRAIN_DENSITY = 1.05    % assumed mean brain density, g/mL
        RBC_FACTOR = 0.766      % per Tom Videen, metproc.inc, line 193  
        SMALL_LARGE_HCT_RATIO = 0.85 % Grubb, et al., 1978        
    end
    
    properties
        a1 % CBF per Videen 1987
        a2
        b1 % OEF per Videen 1987
        b2
        b3
        b4
        cbf
        cbv
        oef
        ooPeakTime   % time of peak of O[15O] AIF
        ooFracTime   % time of measuring H2[15O] of metabolism in plasma 
        fracHOMetab % fraction of H2[15O] in whole blood
        resolveTag = 'op_fdg'
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
    
    methods (Abstract, Static)
        petobs = estimatePetdyn
        petobs = estimatePetobs
        fwhh   = petPointSpread
    end
    
    methods (Static)    
        function [sessd,ct4rb] = godoMasks(varargin)
            ip = inputParser;
            addRequired(ip, 'obj', @isstruct);
            addOptional(ip, 'tracer', 'FDG', @ischar);
            parse(ip, varargin{:});
            
            try
                sessf = ip.Results.obj.sessf;
                v = ip.Results.obj.v;
                
                import mlraichle.* mlpet.*;
                studyd = StudyData;
                vloc = fullfile(studyd.subjectsDir, sessf, sprintf('V%i', v), '');
                assert(isdir(vloc));
                sessd = SessionData('studyData', studyd, 'sessionPath', fileparts(vloc));
                sessd.vnumber = v;
                sessd.attenuationCorrected = true;
                sessd.tracer = ip.Results.tracer;

                pushd(vloc);
                diary(sprintf('AbstractHerscovitch1985.godoMasks_%s_V%i.log', sessf, v));
                [~,msktn] = AbstractHerscovitch1985.mskt(sessd);
                [~,ct4rb] = AbstractHerscovitch1985.brainmaskBinarized(sessd, msktn);                
                aa        = AbstractHerscovitch1985.aparcAseg(sessd, ct4rb);
                sessd.selectedMask = [aa.fqfp '.4dfp.ifh'];
                popd(vloc);
            catch ME
                handwarning(ME);
            end
        end    
        function [m,n] = mskt(sessd)
            import mlfourdfp.*;
            f = [sessd.tracerRevision('typ','fqfp') '_sumt'];
            f1 = mybasename(FourdfpVisitor.ensureSafeOn(f));
            if (lexist([f1 '_mskt.4dfp.ifh'], 'file') && lexist([f1 '_msktNorm.4dfp.ifh'], 'file'))
                m = mlfourd.ImagingContext([f1 '_mskt.4dfp.ifh']);
                n = mlfourd.ImagingContext([f1 '_msktNorm.4dfp.ifh']);
                return
            end
            
            lns_4dfp(f, f1);
            
            ct4rb = CompositeT4ResolveBuilder('sessionData', sessd);
            ct4rb.msktgenImg(f1);          
            m = mlfourd.ImagingContext([f1 '_mskt.4dfp.ifh']);
            n = m.numericalNiftid;
            n.img = n.img/n.dipmax;
            n.fileprefix = [f1 '_msktNorm'];
            n.filesuffix = '.4dfp.ifh';
            n.save;
            n = mlfourd.ImagingContext(n);
        end
        function [b,ct4rb] = brainmaskBinarized(sessd, msktNorm)
            fdgSumt = mlpet.PETImagingContext([sessd.tracerRevision('typ','fqfp') '_sumt.4dfp.ifh']); 
            fnii = fdgSumt.numericalNiftid;
            msktNorm = mlfourd.ImagingContext(msktNorm);
            mnii = msktNorm.numericalNiftid;
            fnii = fnii.*mnii;
            fdgSumt = mlpet.PETImagingContext(fnii);
            fdgSumt.filepath = pwd;
            fdgSumt.fileprefix = [sessd.tracerRevision('typ','fqfp') '_sumt_brain'];
            fdgSumt.filesuffix = '.4dfp.ifh';
            fdgSumt.save;
            
            brainmask = mlfourd.ImagingContext(sessd.brainmask);
            brainmask.fourdfp;
            brainmask.filepath = pwd;
            brainmask.save;
            
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, ...
                'theImages', {fdgSumt.fileprefix brainmask.fileprefix});
            if (lexist(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.ifh'], 'file'))
                b = mlpet.PETImagingContext(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.ifh']);
                return
            end
            ct4rb = ct4rb.resolve;
            b = ct4rb.product{2};
            b.numericalNiftid;
            b = b.binarizeBlended;
            b.saveas(['brainmaskBinarizeBlended_' ct4rb.resolveTag '.4dfp.ifh']);
        end
        function aa = aparcAseg(sessd, ct4rb)
            if (lexist(sessd.maskAparcAseg('typ','.4dfp.ifh'), 'file'))
                aa = mlpet.PETImagingContext(sessd.maskAparcAseg('typ','.4dfp.ifh'));
                return
            end
            
            aa = sessd.aparcAseg('typ', 'mgz');
            aa = sessd.mri_convert(aa, 'aparcAseg.nii');
            aa = mybasename(aa);
            sessd.nifti_4dfp_4(aa);
            aa = ct4rb.t4img_4dfp( ...
                sessd.brainmask('typ','fp'), aa, 'opts', '-n'); 
            aa = mlfourd.ImagingContext([aa '.4dfp.ifh']);
            aa.numericalNiftid;
            aa = aa.binarizeBlended(0); % set threshold to intensity floor
            aa.saveas(['aparcAsegBinarizeBlended_' ct4rb.resolveTag '.4dfp.ifh']);
        end  
        
        function cbf = estimateModelCbf(As, petobs)
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
 		function this = AbstractHerscovitch1985(varargin)
 			%% ABSTRACTHERSCOVITCH1985
 			%  Usage:  this = AbstractHerscovitch1985()
 			%  @param named sessionData
            %  @param named aif
            %  @param named timeDuration
            %  @param named mask

 			this = this@mlpipeline.AbstractDataBuilder(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.IScannerData'));
            addParameter(ip, 'aif', [], @(x) isa(x, 'mlpet.IAifData'));
            addParameter(ip, 'timeDuration', this.TIME_DURATION, @isnumeric);
            addParameter(ip, 'mask', this.sessionData.maskAparcAseg('typ', 'mlfourd.ImagingContext'), ...
                @(x) isa(x, 'mlfourd.ImagingData'));
            parse(ip, varargin{:});
                   
            this.aif_ = ip.Results.aif;
            if (ip.Results.timeDuration > 0)
                this.aif_.timeDuration = ip.Results.timeDuration;
            else
                this.aif_.timeDuration = this.TIME_DURATION;
            end
            this.scanner_ = ip.Results.scanner;            
            this.scanner_.timeDuration = ip.Results.timeDuration;
            this.mask_ = ip.Results.mask;
        end
        
        %% a1, a2 for CBF
        
        function this = buildA1A2(this)
            petobs = this.estimatePetobs(this.aif, this.canonFlows);
            this = this.buildModelCbf(petobs, this.canonFlows);
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
            
            fprintf('AbstractHerscovitch1985.buildA1A2 ..........\n');
            mdl    = fitnlm( ...
                ensureColVector(petobs), ensureColVector(cbf), @mlpet.AbstractHerscovitch1985.estimateModelCbf, [1 1]);            
            disp(mdl)
            fprintf('mdl.RMSE -> %g, min(rho) -> %g, max(rho) -> %g\n', mdl.RMSE, min(petobs), max(petobs));
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
            sc.img = this.a1*sc.img.*sc.img + this.a2*sc.img;
            sc.fileprefix = this.sessionData.cbf('typ','fp','suffix',this.resolveTag);
            sc = sc.blurred(this.petPointSpread);
            this.product_ = mlpet.PETImagingContext(sc.component);
        end
        function this = buildCbfWholebrain(this, varargin)
            this  = this.ensureMask;
            mskvs = this.mask.volumeSummed;
            
            if (lexist(this.sessionData.cbf('typ','fqfn','suffix',this.resolveTag)))
                cbf_ = this.sessionData.cbf('typ','mlpet.PETImagingContext','suffix',this.resolveTag);
            else
                this = this.buildCbfMap;
                cbf_ = this.product;
            end            
            cbf_  = cbf_.masked(this.mask.niftid);
            cbfvs = cbf_.volumeSummed;
            this.product_ = cbfvs.double/mskvs.double;
        end
        
        %% b1, b2, b3, b4 for OEF
        
        function this = buildB1B2(this)
            this = this.ensureAifHOMetab;
            flowHOMetab = this.aif.W*this.estimatePetobs(this.aifHOMetab, this.canonFlows);
            this = this.buildModelOOFlow(flowHOMetab, this.canonFlows);
            model = this.product;
            this.product_ = [ ...
                model.Coefficients{1, 'Estimate'} ...
                model.Coefficients{2, 'Estimate'}];
        end
        function this = buildB3B4(this)
            this = this.ensureAifOO;
            flowOO = this.aif.W*this.estimatePetobs(this.aifOO, this.canonFlows);
            this = this.buildModelOOFlow(flowOO, this.canonFlows);
            model = this.product;
            this.product_ = [ ...
                model.Coefficients{1, 'Estimate'} ...
                model.Coefficients{2, 'Estimate'}];
        end
        function this = buildModelOOFlow(this, flows, cbf)
            %% BUILDMODELOOFLOW 
            %  @param petobs are numeric PETobs := \int_{t \in \text{obs}} dt' \varrho(t').
            %  @param cbf are numeric CBF.
            %  @returns this with this.product := mdl.  A1, A2 are in mdl.Coefficients{:,'Estimate'}.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            fprintf('Herscovitch1985.buildA1A2 ..........\n');
            mdl    = fitnlm( ...
                ensureColVector(cbf), ensureColVector(flows), @mlpet.AbstractHerscovitch1985.estimateModelCbf, [1 1]);            
            disp(mdl)
            fprintf('mdl.RMSE -> %g, min(rho) -> %g, max(rho) -> %g\n', mdl.RMSE, min(flows), max(flows));
            if (isempty(getenv(upper('Test_Herscovitch1985'))))
                plotResiduals(mdl);
                plotDiagnostics(mdl, 'cookd');
                plotSlice(mdl);
            end
            this.product_ = mdl;
        end
        function this = buildCbvWholebrain(this, varargin)
            this  = this.ensureMask;
            mskvs = this.mask.volumeSummed;
            
            if (lexist(this.sessionData.cbv('typ','fqfn','suffix',this.resolveTag)))
                cbv_ = this.sessionData.cbv('typ','mlpet.PETImagingContext','suffix',this.resolveTag);
                cbv_.numericalNiftid;
            else
                this = this.buildCbvMap;
                cbv_ = this.product;
            end
            cbv_ = cbv_.masked(this.mask.niftid);
            cbv_ = cbv_.volumeSummed;
            this.product_ = cbv_.double/mskvs.double;
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
            nimg = this.oefNumer(sc.img);
            dimg = this.oefDenom;
            sc.img = this.is0to1(nimg./dimg);
            sc = sc.blurred(this.petPointSpread);
            sc.fileprefix = this.sessionData.oef('typ','fp','suffix',this.resolveTag);
            this.product_ = mlpet.PETImagingContext(sc.component);
        end
        function this = buildOefWholebrain(this, varargin)
            this  = this.ensureMask;
            mskvs = this.mask.volumeSummed;
            
            if (lexist(this.sessionData.oef('typ','fqfn','suffix',this.resolveTag)))
                oef_ = this.sessionData.oef('typ','mlpet.PETImagingContext');
            else
                this = this.buildOefMap;
                oef_ = this.product;
            end
            oef_  = oef_.masked(this.mask.niftid);
            oefvs = oef_.volumeSummed;
            this.product_ = oefvs.double/mskvs.double;
        end
        function this = buildCmro2Wholebrain(this, varargin)
            this  = this.ensureMask;
            mskvs = this.mask.volumeSummed;
            
            if (lexist(this.sessionData.cmro2('typ','fqfn','suffix',this.resolveTag)))
                cmro2_ = this.sessionData.cmro2('typ','mlpet.PETImagingContext');
            else
                this = this.buildCmro2Map;
                cmro2_ = this.product;
            end
            cmro2_  = cmro2_.masked(this.mask.niftid);
            cmro2vs = cmro2_.volumeSummed;
            this.product_ = cmro2vs.double/mskvs.double;
        end
        
        %% support for buildOefWholebrain
        
        function nimg = oefNumer(this, petobs)
            vimg = this.cbv.niftid.img;
            nimg = petobs*this.aif.W - this.flowHOMetab - this.aifOOIntegral*vimg;
            
            %this = this.ensureMask;
            %nimg = nimg.*this.mask.niftid.img;
        end
        function dimg = oefDenom(this)
            vimg = this.cbv.niftid.img;
            dimg = this.flowOO - 0.835*this.aifOOIntegral*vimg;
            
            %this = this.ensureMask;
            %dimg = dimg.*this.mask.niftid.img;
            %dimg(abs(dimg) < eps) = 1;
        end
        function img  = is0to1(this, img)
            img = img .* isfinite(img);
            img = img .* ~isnan(img);
            img = img .* (img > 0) .* (img < 1);
            
            msk = this.sessionData.mask('typ','mlfourd.ImagingContext');
            msk = msk.blurred(this.petPointSpread);
            img = img.*msk.niftid.img;
            img = img/dipmax(img);
        end
        function f    = flowHOMetab(this)
            img = this.cbf.niftid.img;
            f = this.b1*img.^2 + this.b2*img;
        end
        function f    = flowOO(this)
            img = this.cbf.niftid.img;
            f = this.b3*img.^2 + this.b4*img;
        end
 	end 
    
    methods (Abstract)
        aif  = estimateAifOO(this)
        aif  = estimateAifHOMetab(this)
        aif  = estimateAifOOIntegral(this)
    end

    %% PROTECTED
    
	properties (Access = protected)
 		aif_
        aifHOMetab_
        aifOO_
        aifOOIntegral_
        mask_
        scanner_
    end
    
    methods (Access = protected)        
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
            if (~lexist(this.mask_.fqfilename))
                this.mask_ = this.sessionData.maskAparcAseg('typ', 'mlfourd.ImagingContext');
            end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

