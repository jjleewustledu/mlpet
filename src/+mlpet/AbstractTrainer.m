classdef AbstractTrainer  
	%% ABSTRACTTRAINER   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$  	 

    properties (Constant) 
        MM_CASES = { ...
            'mm01-003_p7243_2008may21' 'mm01-005_p7270_2008jun18' 'mm01-007_p7267_2008jun16' ...
            'mm01-007_p7686_2010aug20' 'mm01-025_p7470_2009aug10' };
        DCV_SHIFTS   = [15 18 14 16 18]
        VIDEEN_FLOWS = [0.006628 0.006733 0.009106 0.005606 0.005856]
        PET_T0S      = [2.951719 3.940710 0.661142 5.993398 2.984008]
        WORK_DIR     = '/Volumes/SeagateBP3/cvl/np755/Training';
    end

	properties (Dependent) 	
        casePaths
        workPath
        dscMaskFn
        dscFn
        aifFn
        maskFn
        ecatFn
        hdrInfoFn
        
        pnum
        dcvShift
        dscShift
        ecatShift
        director
        product
    end 

    methods % GET, SET
        function ps = get.casePaths(this)
            ps = cellfun(@(x) fullfile(x, 'bayesian_pet', ''), ...
                 this.MM_CASES, 'UniformOutput', false);
        end
        function p  = get.workPath(~)
            p = pwd;
        end
        function fn = get.dscMaskFn(this)
            fn = fullfile(this.workPath, 'ep2d_mask.nii.gz');
        end
        function fn = get.dscFn(this)
            fn = fullfile(this.workPath, 'ep2d_default_mcf.nii.gz');
        end
        function fn = get.aifFn(this)
            fn = fullfile(this.workPath, [this.pnum 'ho1.dcv']);
        end
        function fn = get.maskFn(this)
            fn = fullfile(this.workPath, sprintf('aparc_a2009s+aseg_mask_on_%sho1_sumt.nii.gz', this.pnum));
            if (~lexist(fn, 'file'))
                fn = fullfile(this.workPath, sprintf('aparc_a2009s+aseg_mask_on_%str1.nii.gz', this.pnum));
            end
        end
        function fn = get.ecatFn(this)
            fn = fullfile(this.workPath, [this.pnum 'ho1_161616fwhh_masked.nii.gz']);
        end    
        function fn = get.hdrInfoFn(this)
            fn = fullfile(this.workPath, [this.pnum 'ho1_g3.hdr.info']);
        end    
        
        function n  = get.pnum(this)
            n = str2pnum(this.workPath);
        end
        function p  = get.dcvShift(this)
            assert(~isempty(this.dcvShift_));
            p = this.dcvShift_;
        end
        function p  = get.dscShift(this)
            assert(~isempty(this.dscShift_));
            p = this.dscShift_;
        end
        function p  = get.ecatShift(this)
            assert(~isempty(this.ecatShift_));
            p = this.ecatShift_;
        end
        function p  = get.director(this)
            assert(~isempty(this.director_));
            p = this.director_;
        end
        function this = set.director(this, d)
            assert(isa(d, 'mlpet.AutoradiographyDirector'));
            this.director_ = d;
        end
        function p  = get.product(this)
            assert(~isempty(this.director_.product));
            p = this.director_.product;
        end
        function this = set.product(this, p)
            assert(isa(p, 'mlpet.AutoradiographyBuilder'));
            this.director_.product = p;
        end
    end
    
    %% PROTECTED
    
    properties (Access = 'protected')
        dscShift_ = 18
        dcvShift_ = 18
        ecatShift_ = 5
        director_
    end   
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

