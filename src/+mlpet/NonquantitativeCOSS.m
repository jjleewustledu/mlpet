classdef NonquantitativeCOSS  
	%% NONQUANTITATIVECOSS constructs non-quantitative OEF maps according to:
    %  Derdeyn, Videen, Simmons, et al., Radiology 1999; 212:499-506, "Image Processing and Analysis";
    %  it predominantly uses NIfTI over ImagingContext

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.1.0.604 (R2013a) 
 	%  $Id$ 	 
	
    properties (Constant)
        
        %% Derdeyn, Videen, Simmons, et al., Radiology 1999; 212:499-506, "Image Processing and Analysis"
        COSS_MEAN_OEF  = 0.4; 
        MASK_THRESHOLD = 0.1;   % 0.2;
        BOTTOM_FRAC    = 0.5; % 0.25;
        TOP_FRAC       = 0.0625;
        
        MASK_WITHOUT_PHARYNX = 'bt1_default_mask';
    end

    properties (Dependent)
        workPath
        ho
        maskOnPet
        maskWithoutPharynx
        oefFileprefix
        oo
        t1
    end
    
    methods %% GET/SET
        function pth  = get.workPath(this)
            assert(~isempty(this.workPath_));
            pth = this.workPath_;
        end
        function this = set.ho(this, h)
            this.ho_ = imcast(h, 'mlfourd.ImagingContext');
            assert(lexist(this.ho_.fqfilename, 'file'));
        end
        function ic   = get.ho(this)
            assert(~isempty(this.ho_));
            ic = this.ho_;
        end
        function this = set.maskWithoutPharynx(this, m)
            this.maskWithoutPharynx_ = imcast(m, 'mlfourd.ImagingContext');
            assert(lexist(this.maskWithoutPharynx_.fqfilename, 'file'));
        end
        function ic   = get.maskWithoutPharynx(this)            
            assert(~isempty(this.maskWithoutPharynx_));
            ic = this.maskWithoutPharynx_;
        end
        function ic   = get.maskOnPet(this)
            this = this.ensureT1OnHo;
            pad = mlpet.PETAlignmentDirector.factory('product', this.t1, 'referenceImage', this.ho);
            pad.xfm = fullfile(this.ho.filepath, [this.t1.fileprefix '_on_' this.ho.fileprefix '.mat']);
            ic = pad.applyXfm(this.maskWithoutPharynx);
            ic = imcast(ic, 'mlfourd.NIfTI');
        end
        function this = set.oo(this, o)
            this.oo_ = imcast(o, 'mlfourd.ImagingContext');
            assert(lexist(this.oo_.fqfilename, 'file'));
        end
        function this = set.oefFileprefix(this, fp)
            assert(ischar(fp));
            this.oefFileprefix_ = fp;
        end
        function fp   = get.oefFileprefix(this)
            assert(~isempty(this.oefFileprefix_));
            fp = this.oefFileprefix_;
        end
        function ic   = get.oo(this)            
            assert(~isempty(this.oo_));
            ic = this.oo_;
        end
        function this = set.t1(this, t)
            this.t1_ = imcast(t, 'mlfourd.ImagingContext');
            assert(lexist(this.t1_.fqfilename, 'file'));
        end
        function ic   = get.t1(this)            
            assert(~isempty(this.t1_));
            ic = this.t1_;
        end
    end
    
	methods (Static)
        function oef = constructOEF(varargin)

            nqcoss = mlpet.NonquantitativeCOSS(varargin{:});
            mask   = nqcoss.maskOnPet;
            mask   = mask .* nqcoss.maskByThreshold(nqcoss.ho, nqcoss.MASK_THRESHOLD);
            
            oef            = nqcoss.safe_quotient(nqcoss.oo, nqcoss.ho);
            %oef            = oef .* mask; % 2015oct10, JJL; removing masking of oef image to avoid clipping of
                                           %freesurfer parcellation-based ROIs
            oef            = oef .* nqcoss.cos_ratio(nqcoss.oo, nqcoss.ho, mask); 
            oef.fileprefix = nqcoss.oefFileprefix;
            oef.save;
        end
        function nii = safe_quotient(niiA, niiB)
            niiA = imcast(niiA, 'mlfourd.NIfTI');
            niiB = imcast(niiB, 'mlfourd.NIfTI');
            fmsk = isfinite(niiA.img ./ niiB.img);
            
            niiA.img = niiA.img .* fmsk;
            niiB.img = niiB.img + (~fmsk);
            nii      = niiA.clone;
            nii.img  = niiA.img ./ niiB.img;
            nii.img  = scrubNaNs(nii.img, true);
            nii.fileprefix = [niiA.fileprefix '_safeQuotient_' niiB.fileprefix];
        end
    end

    %% PRIVATE 
    
    properties (Access = 'private')
        workPath_
        ho_
        maskWithoutPharynx_
        oefFileprefix_
        oo_
        t1_
    end
    
    methods (Access = 'private')
 		function this  = NonquantitativeCOSS(varargin)
 			%% NONQUANTITATIVECOSS 
 			%  Usage:  this = NonquantitativeCOSS([parameter, parameter_value, ...]) 
            
            p = inputParser;
            addParameter(p, 'OO',                 imcast(fullfile(pwd, filename(mlpet.O15Builder.OO_MEANVOL_FILEPREFIX)), 'mlfourd.ImagingContext'), ...
                                                  @(x) assert(~isempty(x)));
            addParameter(p, 'HO',                 imcast(fullfile(pwd, filename(mlsurfer.PETSegstatsBuilder.HO_MEANVOL_FILEPREFIX)), 'mlfourd.ImagingContext'),...
                                                  @(x) assert(~isempty(x)));
            addParameter(p, 'T1',                 imcast(fullfile(pwd, 't1_default.nii.gz'), 'mlfourd.ImagingContext'), ...
                                                  @(x) assert(~isempty(x)));
            addParameter(p, 'MaskWithoutPharynx', imcast(fullfile(pwd, filename(this.MASK_WITHOUT_PHARYNX)), 'mlfourd.ImagingContext'), ...
                                                  @(x) assert(~isempty(x)));
            addParameter(p, 'Workpath',           pwd, ...
                                                  @(x) assert(lexist(x, 'dir')));
            addParameter(p, 'OEFFileprefix',      'oefnq_default_161616fwhh', ...
                                                  @(x) ischar(x));
            parse(p, varargin{:});    

            this.oo                 = p.Results.OO;
            this.ho                 = p.Results.HO;
            this.t1                 = p.Results.T1;
            this.maskWithoutPharynx = p.Results.MaskWithoutPharynx;
            this.workPath_          = p.Results.Workpath;
            this.oefFileprefix      = p.Results.OEFFileprefix;
            
            fprintf('NonquantitativeCOSS methods are currently operating in:  %s\n', pwd);
            fprintf('Using:  %s\n', imcast(this.ho, 'filename'));
            fprintf('        %s\n', imcast(this.oo, 'filename'));
            fprintf('        %s\n', imcast(this.t1, 'filename'));
            fprintf('        %s\n', imcast(this.maskWithoutPharynx, 'filename'));
 		end 
        function nii   = cos_scale_images(~, nii)
        end
        function scale = cos_ratio(this, oo, ho, msk)
            ooShort  = this.truncateNifti(oo);
            hoShort  = this.truncateNifti(ho);
            mskShort = this.truncateNifti(msk);
            mskShort = this.maskByThreshold(mskShort, this.MASK_THRESHOLD);   

            scale = this.COSS_MEAN_OEF * ...
                    this.meanValueByMask(hoShort, mskShort) / ...
                    this.meanValueByMask(ooShort, mskShort);          
        end
        function nii   = maskByThreshold(~, nii, thr)
            nii = imcast(nii, 'mlfourd.NIfTI');
            
            nii.img        =  nii.img > thr * nii.dipmax;
            nii.fileprefix = [nii.fileprefix '_' num2str(thr) 'mask'];
            nii            =  nii.clone;
        end
        function slab  = truncateNifti(this, nii)
            nii = imcast(nii, 'mlfourd.NIfTI');
            top = floor((1 - this.TOP_FRAC) * size(nii, 3));
            bot =  ceil(  this.BOTTOM_FRAC  * size(nii, 3));
            assert(top > bot);
            
            slab = nii.zeros;
            slab.img(:,:,bot:top) = nii.img(:,:,bot:top);
            slab.fileprefix = sprintf('%s_s%sto%s', nii.fileprefix, num2str(bot), num2str(top));
        end
        function mean  = meanValueByMask(~, nii, msk)
            assert(isa(nii, 'mlfourd.NIfTI'));
            assert(isa(msk, 'mlfourd.NIfTI'));
            assert(msk.dipmax == 1);

            mean = sum(sum(sum(nii.img .* msk.img))) / sum(sum(sum(msk.img)));
            assert(~isnan(mean));
        end
        function this  = ensureT1OnHo(this)
            if (~lexist( ...
                    fullfile(this.ho.filepath, [this.t1.fileprefix '_on_' this.ho.fileprefix '.mat'])))
                mlbash(sprintf('cp %s %s', this.t1.fqfilename, this.ho.filepath));  %% KLUDGE
                t1          = this.t1;
                t1.filepath = this.ho.filepath;
                this.t1     = t1;
                pad = mlpet.PETAlignmentDirector.factory('product', this.ho, 'referenceImage', this.t1);
                pad.alignMR2PET(this.t1, this.ho);
            end
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

