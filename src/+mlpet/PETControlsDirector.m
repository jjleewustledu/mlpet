classdef PETControlsDirector < mlfsl.AlignmentDirectorDecorator
	%% PETCONTROLSDIRECTOR ... 

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.73043 (R2014a) 
 	%  $Id$ 
    
    properties (Constant)        
        MNIREF_FILEPREFIX = 'MNI152_T1_1mm_brain'
        OEFNQ_FILEPREFIX  = 'oefnq_default_101010fwhh'
        CEREB_FILEPREFIX  = 'Cerebellum-MNIfnirt-1mm-no-sinus-mask'
        MCA_HOME          = '/Users/jjlee/MATLAB-Drive/mlfsl/data/atlases/MNI'
        HEMISPHERES = { 'left' 'right' 'bilateral' }
        TERRITORIES = { 'ACA' 'ACA+MCA' 'MCA' 'Cerebellum' }
    end
    
    properties (Dependent)
        ctRef
        mniRef
        pNumber
        rpho
        rphoFileprefix
        rpoo
        rpooOnHo
        sessionPath
        fslPath
        maskCerebellumMni
        maskAcaMni
        maskAcaMcaMni
        maskMcaMni
        maskLeftMni
        maskRightMni
        oefMni
    end
    
    methods %% SET/GET
        function r    = get.ctRef(this)
            tisFqfn = fullfile(this.fslPath, [this.pNumber 'tis.nii.gz']);
            if (~lexist(this.thresholdedFilename(tisFqfn), 'file'))
                this.thresholdCT(tisFqfn); end
            r = mlfourd.ImagingContext.load(this.thresholdedFilename(tisFqfn));
        end
        function r    = get.mniRef(this) 
            r = mlfourd.ImagingContext.load( ...
                        fullfile(getenv('FSL_DIR'), 'data', 'standard', filename(this.MNIREF_FILEPREFIX)));
        end
        function p    = get.pNumber(this)
            [~,p] = fileparts(this.sessionPath);
        end
        function ic   = get.rpho(this)
            ic = mlfourd.ImagingContext.load( ...
                         fullfile(this.fslPath, filename(this.rphoFileprefix)));
        end
        function fp   = get.rphoFileprefix(this)            
            if (strcmp('p5397', this.pNumber))
                hoSuffix = 'ho2_g3';
            else
                hoSuffix = 'ho1_g3';
            end
            fp = ['r' this.pNumber hoSuffix];
        end
        function ic   = get.rpoo(this)            
            ic = mlfourd.ImagingContext.load( ...
                         fullfile(this.fslPath, filename(['r' this.pNumber 'oo1_g3'])));
        end
        function ic   = get.rpooOnHo(this)            
            ic = mlfourd.ImagingContext.load( ...
                         fullfile(this.fslPath, filename(['r' this.pNumber 'oo1_g3_on_' this.rpho.fileprefix])));
        end
        function this = set.sessionPath(this, wd)
            assert(lexist(wd, 'dir'));
            this.sessionPath_ = wd;
        end
        function pth  = get.sessionPath(this)
            pth = this.sessionPath_;
        end
        function pth  = get.fslPath(this)
            pth = fullfile(this.sessionPath, 'fsl', '');
        end
        function msk  = get.maskCerebellumMni(this)
            msk = mlfourd.ImagingContext.load( ...
                          fullfile(this.MCA_HOME, filename(this.CEREB_FILEPREFIX)));
        end
        function msk  = get.maskAcaMni(this)
            msk = mlfourd.ImagingContext.load( ...
                          fullfile(this.MCA_HOME, filename('MNI152_T1_1mm_ACA_smooth')));
        end
        function msk  = get.maskAcaMcaMni(this)
            msk = mlfourd.ImagingContext.load( ...
                          fullfile(this.MCA_HOME, filename('MNI152_T1_1mm_ACA+MCA_smooth')));
        end
        function msk  = get.maskMcaMni(this)
            msk = mlfourd.ImagingContext.load( ...
                          fullfile(this.MCA_HOME, filename('MNI152_T1_1mm_MCA_smooth')));
        end
        function msk  = get.maskLeftMni(this)
            msk = mlfourd.ImagingContext.load( ...
                          fullfile(this.MCA_HOME, filename('MNI152_T1_1mm_left')));
        end
        function msk  = get.maskRightMni(this)
            msk = mlfourd.ImagingContext.load( ...
                          fullfile(this.MCA_HOME, filename('MNI152_T1_1mm_right')));
        end
        function ic   = get.oefMni(this)
            oeffn = fullfile(this.fslPath, filename([this.OEFNQ_FILEPREFIX '_on_' this.MNIREF_FILEPREFIX]));
            if (~lexist(oeffn, 'file'))
                bldr = this.builder.clone;
                bldr.product = fullfile(this.fslPath, filename(this.OEFNQ_FILEPREFIX));
                bldr.referenceImage = this.mniRef;
                bldr.xfm = fullfile(this.fslPath, filename([this.rphoFileprefix '_on_' this.MNIREF_FILEPREFIX], '.mat'));
                bldr.buildFlirtedWithXfm;
            end
            ic = mlfourd.ImagingContext.load(oeffn);
        end
    end    
 	 
    methods (Static)
        function pcd = alignPNumber(pth)
            cd(pth);
            pcd     = mlpet.PETControlsDirector.factory;
            pcd.sessionPath = pth;
            ooOnHo  = pcd.alignPET2PET(pcd.rpoo, pcd.rpho);
            hoOnMni = pcd.alignPET2MNI(pcd.rpho);            
            
            xfms = { pcd.xfmFilename(ooOnHo.fqfilename) ...
                     pcd.xfmFilename(hoOnMni.fqfilename) };
                 
            pcd.builder.product        = pcd.rpoo;
            pcd.builder.referenceImage = pcd.mniRef;
            [pcd.builder, ...
             pcd.builder.xfm]          = pcd.builder.concatXfms(xfms);            
            pcd.builder                = pcd.builder.buildFlirtedWithXfm;
        end
        function oef = constructOEF(pth)
            cd(pth);
            pcd = mlpet.PETControlsDirector.factory;            
            pcd.fslPath = pth;
            
            ctMask = mlfourd.NIfTI.load(fullfile(pth, filename([pcd.pNumber 'tis_thr_on_' this.MNIREF_FILEPREFIX])));
            ctMask.img = ctMask.img > 0;
            ctMask.fileprefix = [ctMask.fileprefix '_mask'];
            ctMask.save;
            
            oef = mlpet.NonquantitativeCOSS.constructOEF('OO',                 pcd.rpooOnHo, ...
                                                         'HO',                 pcd.rpho, ...
                                                         'T1',                 pcd.mniRef, ...
                                                         'MaskWithoutPharynx', ctMask, ...
                                                         'Workpath',           pcd.fslPath, ...
                                                         'OEFFileprefix',      fullfile(pcd.fslPath, filename(pcd.OEFNQ_FILEPREFIX)));
        end
        function pcd = factory(varargin)
            %% FACTORY returns a PETControlsDirector with an AlignmentDirector with a PETAlignmentBuilder
            %  Usage:   pad = PETAlignmentDirector.factory([varargin for PETAlignmentBuilder])
            
            import mlpet.* mlfsl.*;
            pcd = PETControlsDirector( ...
                  AlignmentDirector( ...
                  PETAlignmentBuilder(varargin{:})));
        end
        function       listOefRatiosInStudy
            fprintf('%s \n %s \t %s \t %s \t %s \t %s \t %s \t %s \t %s \t %s \t %s \t %s \n\n', ...
                'PETControlsDirector.listOefRatios', ...
                'mean(oefRight)',     'mean(oefLeft)', 'mean(oefCerebellum)', ...
                'oefRatioRight',      'oefRatioLeft', ...
                'std(oefRight)', 'std(oefLeft)', 'std(oefCerebellum)', ...
                'N(MCA R)', 'N(MCA L)', 'N(Cerebellum)');
            dt      = mlsystem.DirTools('p*');
            for t = 1:dt.length
                cd(fullfile(dt.fqdns{t}));
                mlpet.PETControlsDirector.listOefRatios;
            end
        end
        function       listOefRatios
                pcd     = mlpet.PETControlsDirector.factory;
                [or,Nr] = pcd.oef('right', 'MCA', @mean);
                [ol,Nl] = pcd.oef('left',  'MCA', @mean);
                [oc,Nc] = pcd.oef('bilateral', 'Cerebellum', @mean);
                fprintf('%f \t %f \t %f \t %f \t %f \t %f \t %f \t %f \t %i \t %i \t %i \n', ...
                        or, ol, oc, or/oc, ol/oc, ...
                        pcd.oef('right', 'MCA', @std), pcd.oef('left', 'MCA', @std), pcd.oef('bilateral', 'Cerebellum', @std), ...
                        Nr, Nl, Nc);
        end
    end
    
	methods        
        function prd   = alignPET2MNI(this, prd)
            prd1 = this.alignPET2CT(prd);
            prd2 = this.alignCT2MR;
            xfms = { this.xfmFilename(imcast(prd1, 'fqfilename')) ...
                     this.xfmFilename(imcast(prd2, 'fqfilename')) };
            
            petBldr                = this.builder.clone;
            petBldr.product        = prd;
            petBldr.referenceImage = this.mniRef;            
            [petBldr,petBldr.xfm]  = petBldr.concatXfms(xfms);            
            petBldr                = petBldr.buildFlirtedWithXfm;
            prd                    = petBldr.product;
        end
        function prd   = alignCT2MR(this)
            ctBldr                = mlct.CTAlignmentBuilder;
            ctBldr.product        = this.ctRef;
            ctBldr.referenceImage = this.mniRef;
            ctBldr                = ctBldr.buildFlirtedSmallAngles;
            prd                   = ctBldr.product;
        end
        function prd   = alignPET2CT(this, prd)
            petBldr                = this.builder.clone;
            petBldr.product        = prd;
            petBldr.referenceImage = this.ctRef;
            petBldr                = petBldr.buildFlirtedSmallAngles;
            prd                    = petBldr.product;
        end
        function pet1  = alignPET2PET(this, pet, petRef)
            petBldr                = this.builder.clone;
            petBldr.product        = pet;
            petBldr.referenceImage = petRef;
            petBldr                = petBldr.buildFlirtedSmallAngles;
            pet1                   = petBldr.product;
        end
        
        function [o,N] = oef(this, hemi, territory, statHandle)
            msk = this.specificMask(hemi, territory, this.oefMni);
            o   = this.oefMni.nifti;
            o   = o.img(msk.img == 1);
            N   = length(o);
            o   = statHandle(o);
        end
        function o     = oefRatio(this, hemi, territory, statHandle)
            o = this.oef(hemi, territory, statHandle) / this.oef('bilateral', 'Cerebellum', statHandle);
        end        
        
 		function this = PETControlsDirector(varargin) 
 			%% PETCONTROLSDIRECTOR 
 			%  ... 
 			
            this = this@mlfsl.AlignmentDirectorDecorator(varargin{:});
            assert(isa(this.builder, 'mlpet.PETAlignmentBuilder'));
            this.sessionPath = pwd;
 		end 
    end 
   
    %% PRIVATE
    
    properties (Access = 'private')
        sessionPath_
    end
    
    methods (Static, Access = 'private')        
        function fqfn = thresholdedFilename(fqfn)
            fqfn = filename([fileprefix(fqfn) '_thr']);
        end
        function fqfn = xfmFilename(fqfn)
            if (lstrfind(fqfn, '.mat'))
                return; end
            if (lstrfind(fqfn, '.nii.gz'))
                fqfn = [fileprefix(fqfn) '.mat']; end
        end
    end
    
    methods (Access = 'private')
        function        thresholdCT(this, fqfn)
            mlbash(sprintf('fslmaths %s -thr -10000 %s', fqfn, this.thresholdedFilename(fqfn)));
        end
        function msk  = specificMask(this, hemi, territory, oef)
            import mlfourd.*;
            hemi      = this.hemisphereMask(hemi);
            territory = this.territoryMask(territory);
            oef       = imcast(oef, 'mlfourd.NIfTI');
            oef.img   = oef.img > 0;
            msk       = ImagingComposite.load(hemi, territory, oef);
            msk       = this.intersectionMask(msk);
        end
        function msk  = hemisphereMask(this, hemi)
            assert(lstrfind(hemi, this.HEMISPHERES));
            import mlfourd.*;
            switch (hemi)
                case { 'left' 'right' }
                    msk = NIfTI.load( ...
                          fullfile(this.MCA_HOME, filename(['MNI152_T1_1mm_' hemi])));
                case 'bilateral'
                    msk     = this.mniRef.nifti;
                    msk.img = ones(msk.size);
                otherwise
                    error('mlpet:unsupportedParamValue', 'PETControlsDirector.hemisphereMask.hemi->%s', hemi);
            end
        end
        function msk  = territoryMask(this, terr)
            assert(lstrfind(terr, this.TERRITORIES));
            import mlfourd.*;
            if (strcmp('Cerebellum', terr))
                msk = NIfTI.load(this.maskCerebellumMni.fqfilename);
                return
            end
                msk = NIfTI.load( ...
                      fullfile(this.MCA_HOME, filename(['MNI152_T1_1mm_' terr '_smooth'])));
        end
        function msk  = intersectionMask(~, msks)
            msks = imcast(msks, 'mlfourd.ImagingComposite');
            msk  = msks{1};
            msk  = msk.ones;
            msk.fileprefix = ['intersectionMask_' datestr(now,30)];
            for m = 1:msks.length
                nii = msks{m};
                msk.img = msk.img .* (nii.img > 0);
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

