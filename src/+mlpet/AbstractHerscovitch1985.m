classdef (Abstract) AbstractHerscovitch1985 < mlfourdfp.AbstractSessionBuilder
	%% ABSTRACTHERSCOVITCH1985 abstracts PET scanner platforms such as the Biograph mMR and ECAT EXACT HR+
    %  See also:
    %  1. Herscovitch P, Mintun MA, Raichle ME (1985) Brain oxygen utilization measured with oxygen-15 radiotracers and 
    %  positron emission tomography: generation of metabolic images. J Nucl Med 26(4):416?417.
    %  2. Videen TO, Perlmutter JS, Herscovitch P, Raichle ME (1987) Brain blood volume, flow, and oxygen utilization 
    %  measured with 15O radiotracers and positron emission tomography: revised metabolic computations. 
    %  J Cereb Blood Flow Metab 7(4):513?516.
    %
	%  $Revision$
 	%  was created 06-Feb-2017 21:31:05
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%  It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2016, 2017 John Joowon Lee

    properties (Abstract)
        canonFlows
        MAGIC
        W
    end
    
    methods (Abstract, Static)
        fwhh   = petPointSpread
    end
    
    methods (Abstract)
        this   = buildCbfMap(this)
        petobs = estimatePetdyn(this)
        petobs = estimatePetobs(this)
    end
    
    properties (Constant)
        LAMBDA = 0.95           % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        DENSITY_BRAIN = 1.05    % assumed mean brain density, g/mL
        RBC_FACTOR = 0.766      % per Tom Videen, metproc.inc, line 193  
        RATIO_SMALL_LARGE_HCT = 0.85 % Grubb, et al., 1978               
        
        CBF_UTHRESH = 500
        CBV_UTHRESH = 10
    end
    
    properties
        ooPeakTime  = 0
        ooFracTime  = 120
        fracHOMetab = 153/263
        
        a1 % CBF per Videen 1987
        a2
        b1 % OEF per Videen 1987
        b2
        b3
        b4
    end

	properties (Dependent)
        aif
        aifHOMetab
        aifOO
        aifOOIntegral
        cbf
        cbv
        oef
        scanner
        aifTimeShift
        mask
        resolveTag
        scannerTimeShift
        videenBlur
        voxelVolume
    end
    
    methods (Static)
        function cbf = estimateModelCbf(As, petobs)
            cbf = petobs.^2*As(1) + petobs*As(2);
        end    
        function cbf = f1ToCbf(f1)
            cbf = 6000*f1/mlpet.Herscovitch1985.DENSITY_BRAIN;
        end
        function f1  = cbfToF1(cbf)
            f1 = cbf*mlpet.Herscovitch1985.DENSITY_BRAIN/6000;
        end
    end
    
	methods
        
        %% GET, SET
        
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
        function g = get.cbf(this)
            %if (~isempty(this.cbf_))
                g = this.cbf_;
            %    return
            %end
            %g = this.sessionData.cbfOpFdg('typ', 'mlfourd.ImagingContext');
        end
        function this = set.cbf(this, s)
            this.cbf_ = s;
        end
        function g = get.cbv(this)
            %if (~isempty(this.cbv_))
                g = this.cbv_;
            %    return
            %end
            %g = this.sessionData.cbvOpFdg('typ', 'mlfourd.ImagingContext');
        end
        function this = set.cbv(this, s)
            this.cbv_ = s;
        end
        function g = get.oef(this)
            if (~isempty(this.oef_))
                g = this.oef_;
                return
            end
            g = this.sessionData.oefOpFdg('typ', 'mlfourd.ImagingContext');
        end
        function this = set.oef(this, s)
            this.oef_ = s;
        end
        function g = get.scanner(this)
            g = this.scanner_;
        end
        function this = set.scanner(this, s)
            assert(isa(s, 'mlfourd.INIfTI') || isa(s, 'mlfourd.ImagingContext'))
            this.scanner_ = s;
        end
        function g = get.aifTimeShift(this)
            g = this.aif_.aifTimeShift;
        end
        function g = get.mask(this)
            g = this.mask_;
        end
        function g = get.resolveTag(this)
            g = this.sessionData.resolveTag;
        end
        function g = get.scannerTimeShift(this)
            g = this.scanner_.scannerTimeShift;
        end   
        function g = get.videenBlur(this) %#ok<MANU>
            fhalf = 0.3; % half-wave number in cm^{-1}; cf. gauss_4dfp
            fwhh  = 10*2*log(2)/(pi*fhalf);
            g     = fwhh*[1 1 1];
        end
        function g = get.voxelVolume(this)
            g = prod(this.scanner_.mmppix(1:3)/10); % cm^3
        end
        
        %% a1, a2 for CBF
        
        function this = buildA1A2(this)
            this.aif_.isDecayCorrected = false;
            petobs = this.estimatePetobs(this.aif, this.canonFlows);
            this = this.buildModelCbf(petobs, this.canonFlows);
            model = this.product;
            this.product_ = [ ...
                model.Coefficients{1, 'Estimate'} ...
                model.Coefficients{2, 'Estimate'}];
            this.a1 = this.product_(1);
            this.a2 = this.product_(2);
        end
        function this = buildModelCbf(this, petobs, cbf)
            %% BUILDMODELCBF 
            %  @param petobs are numeric PETobs := \int_{t \in \text{obs}} dt' \varrho(t').
            %  @param cbf are numeric CBF.
            %  @returns this with this.product := mdl.  A1, A2 are in mdl.Coefficients{:,'Estimate'}.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            fprintf('AbstractHerscovitch1985.buildModelCbf ..........\n');
            mdl = fitnlm( ...
                ensureColVector(petobs), ...
                ensureColVector(cbf), ...
                @mlpet.AbstractHerscovitch1985.estimateModelCbf, ...
                [1 1]);
            disp(mdl)
            fprintf('mdl.RMSE -> %g, min(rho) -> %g, max(rho) -> %g\n', mdl.RMSE, min(petobs), max(petobs));            
            this.product_ = mdl;
            if (~isempty(getenv('DEBUG_HERSCOVITCH1985')))
                plotResiduals(mdl);
                plotDiagnostics(mdl, 'cookd');
                plotSlice(mdl);
            end
        end
        function this = buildCbfWholebrain(this, varargin)
            if (lexist(this.sessionData.cbfOpFdg('typ','fqfn')))
                cbf__ = this.sessionData.cbfOpFdg('typ','mlfourd.ImagingContext');
            else
                this = this.buildCbfMap;
                cbf__ = this.product;
            end 
            this  = this.ensureMask;
            cbf__.numericalNiftid;
            if (~isempty(getenv('TEST_HERSCOVITCH1985')))
                cbf__.view(this.mask.fqfn);
            end
            cbf__ = cbf__.masked(this.mask.niftid);  
            cbfvs = cbf__.volumeSummed;
            
            msk   = this.mask_.numericalNiftid;
            msk   = msk .* cbf__.numericalNiftid.binarized;
            mskvs = msk.volumeSummed;
            this.product_ = cbfvs.double/mskvs.double;
        end
        
        %% b1, b2, b3, b4 for OEF, CMRO2
        
        function this = buildB1B2(this)
            this = this.ensureAifHOMetab;
            flowHOMetab = this.W*this.estimatePetobs(this.aifHOMetab, this.canonFlows);
            this = this.buildModelOOFlow(flowHOMetab, this.canonFlows);
            model = this.product;
            this.product_ = [ ...
                model.Coefficients{1, 'Estimate'} ...
                model.Coefficients{2, 'Estimate'}];
            this.b1 = this.product_(1);
            this.b2 = this.product_(2);
        end
        function this = buildB3B4(this)
            this = this.ensureAifOO;
            flowOO = this.W*this.estimatePetobs(this.aifOO, this.canonFlows);
            this = this.buildModelOOFlow(flowOO, this.canonFlows);
            model = this.product;
            this.product_ = [ ...
                model.Coefficients{1, 'Estimate'} ...
                model.Coefficients{2, 'Estimate'}];
            this.b3 = this.product_(1);
            this.b4 = this.product_(2);
        end
        function this = buildModelOOFlow(this, flows, cbf)
            %% BUILDMODELOOFLOW 
            %  @param petobs are numeric PETobs := \int_{t \in \text{obs}} dt' \varrho(t').
            %  @param cbf are numeric CBF.
            %  @returns this with this.product := mdl.  A1, A2 are in mdl.Coefficients{:,'Estimate'}.
            %  See also:  https://www.mathworks.com/help/releases/R2016b/stats/nonlinear-regression-workflow.html
            
            fprintf('Herscovitch1985.buildModelOOFlow ..........\n');
            mdl    = fitnlm( ...
                ensureColVector(cbf), ensureColVector(flows), @mlpet.AbstractHerscovitch1985.estimateModelCbf, [1 1]);            
            disp(mdl)
            fprintf('mdl.RMSE -> %g, min(rho) -> %g, max(rho) -> %g\n', mdl.RMSE, min(flows), max(flows));
            plotResiduals(mdl);
            plotDiagnostics(mdl, 'cookd');
            plotSlice(mdl);
            this.product_ = mdl;
        end
        function this = buildCbvWholebrain(this, varargin)
            if (lexist(this.sessionData.cbvOpFdg('typ','fqfn')))
                cbv__ = this.sessionData.cbvOpFdg('typ','mlfourd.ImagingContext');
            else
                this = this.buildCbvMap;
                cbv__ = this.product;
            end
            cbv__.numericalNiftid;
            this  = this.ensureMask;
            if (~isempty(getenv('TEST_HERSCOVITCH1985')))
                cbv__.view(this.mask.fqfn);
            end
            cbv__ = cbv__.masked(this.mask.niftid);
            cbvvs = cbv__.volumeSummed;            
            
            msk   = this.mask_.numericalNiftid;
            msk   = msk .* cbv__.numericalNiftid.binarized;
            mskvs = msk.volumeSummed;
            this.product_ = cbvvs.double/mskvs.double;
        end        
        function this = buildOefWholebrain(this, varargin)
            
            if (lexist(this.sessionData.oefOpFdg('typ','fqfn')))
                oef__ = this.sessionData.oefOpFdg('typ','mlfourd.ImagingContext');
            else
                this = this.buildOefMap;
                oef__ = this.product;
            end
            oef__.numericalNiftid;
            this  = this.ensureMask;
            if (~isempty(getenv('TEST_HERSCOVITCH1985')))
                oef__.view(this.mask.fqfn);
            end
            oef__  = oef__.masked(this.mask.niftid);
            oefvs = oef__.volumeSummed;            
            
            msk   = this.mask_.numericalNiftid;
            msk   = msk .* oef__.numericalNiftid.binarized;
            mskvs = msk.volumeSummed;
            this.product_ = oefvs.double/mskvs.double;
        end
        function this = buildCmro2Wholebrain(this, varargin)
            this  = this.ensureMask;
            mskvs = this.mask.volumeSummed;
            
            if (lexist(this.sessionData.cmro2OpFdg('typ','fqfn')))
                cmro2_ = this.sessionData.cmro2OpFdg('typ','mlfourd.ImagingContext');
            else
                this = this.buildCmro2Map;
                cmro2_ = this.product;
            end
            cmro2_  = cmro2_.masked(this.mask.niftid);
            cmro2vs = cmro2_.volumeSummed;
            this.product_ = cmro2vs.double/mskvs.double;
        end
        function nimg = oefNumer(this, petobs)            
            import mlfourd.*;
            ic = ImagingContext(petobs);
            %ic = ic.blurred(this.petPointSpread);
            petobs = ic.niftid.img;
            vimg = this.cbv.niftid.img;
            nnn  = NumericalNIfTId(NIfTId(petobs*this.W - this.flowHOMetab - this.aifOOIntegral*vimg));
            nimg = nnn.img;
        end
        function dimg = oefDenom(this)
            vimg = this.cbv.niftid.img;
            import mlfourd.*;
            dnn  = NumericalNIfTId(NIfTId(this.flowOO - 0.835*this.aifOOIntegral*vimg));
            dimg = dnn.img;
        end
        function img  = is0to1(this, img)
            
            sdFdg = this.sessionData;
            sdFdg.tracer = 'FDG';
            msk = sdFdg.MaskOpFdg;
            msk.numericalNiftid;
            msk = msk.blurred(this.petPointSpread);
            msk = msk.binarized;
            img = img.*msk.numericalNiftid.img;            
            img(~isfinite(img)) = 0;
            img(isnan(img)) = 0;
            img(img < 0) = 0;
            img(img > 1) = 1;
        end
        function f    = flowHOMetab(this)
            img = this.cbf.niftid.img;
            f = this.b1*img.^2 + this.b2*img;
        end
        function f    = flowOO(this)
            img = this.cbf.niftid.img;
            f = this.b3*img.^2 + this.b4*img;
        end        
        
        %%
        
 		function this = AbstractHerscovitch1985(varargin)
 			%% ABSTRACTHERSCOVITCH1985
 			%  @param named sessionData
            %  @param named aif
            %  @param named timeWindow
            %  @param named mask

 			this = this@mlfourdfp.AbstractSessionBuilder(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'scanner', [], @(x) isa(x, 'mlpet.IScannerData') || isempty(x));
            addParameter(ip, 'aif', this.configAcquiredAifData, @(x) isa(x, 'mlpet.IAifData'));
            addParameter(ip, 'timeWindow', [], @isnumeric);
            addParameter(ip, 'mask', this.sessionData.MaskOpFdg, @(x) isa(x, 'mlfourd.ImagingContext'));
            parse(ip, varargin{:});
            this.aif_ = ip.Results.aif;
            assert(~isempty(this.aif_));
            this.scanner_ = ip.Results.scanner;             
            assert(~isempty(this.scanner_));            
            if (~isempty(ip.Results.timeWindow))
                this.aif_.timeWindow = ip.Results.timeWindow;
                if (~isempty(this.scanner_))
                    this.scanner_.timeWindow = ip.Results.timeWindow;
                end
            end          
            this.mask_ = ip.Results.mask;
            this.mask_.filesuffix = '.4dfp.hdr'; % KLUDGE; POSSIBLE BUG
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
        cbf_
        cbv_
        mask_
        oef_
        scanner_
    end
    
    methods (Access = protected)
        function aif = configAcquiredAifData(~)  
            aif = [];
        end
        function aif = configAcquiredFdgAif(~)
            aif = [];
        end
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
            if (~lexist([this.mask_.fqfp '.4dfp.hdr']))
                sessdFdg = this.sessionData;
                sessdFdg.tracer = 'FDG';
                assert(lexist(sessdFdg.brainmaskBinarizeBlended));
                this.mask_ = sessdFdg.MaskOpFdg;
                this.mask_ = this.mask_.numericalNiftid;
            end
            if (~lexist([this.mask_.fqfp '.nii.gz']))
                ic = mlfourd.ImagingContext2(strcat(this.mask_.fqfp, '.4dfp.hdr'));
                ic.selectNiftiTool();
                ic.save();
            end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

