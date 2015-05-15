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
            'mm01-003_p7243_2008may21'
            'mm01-005_p7270_2008jun18'
            'mm01-006_p7260_2008jun9'
            'mm01-007_p7267_2008jun16'
            'mm01-007_p7686_2010aug20'
            'mm01-008_p7153_2008jan16'
            'mm01-009_p7266_2008jun16'
            'mm01-009_p7660_2010jun22'
            'mm01-025_p7470_2009aug10'
            'mm01-029_p7577_2010mar1'
            'mm02-001_p7146_2008jan4'
            'mm02-001_p7384_2009feb13'
            'mm02-001_p7770_2011jan24'
            'mm03-001_p7229_2008apr28'
            'mm06-001_p7321_2008sep8' }
        DCV_SHIFTS   = [-15 -17 -23 -16 -16 -15 -23 -30 -18 -11 -30 -20 -21 -34 -13]
        ECAT_SHIFTS  = [  0  -2  -3   0  -3  -3   0 -13  -3  -2 -15  -8  -8 -10  -1]
        VIDEEN_FLOWS = ...
            [0.00730699976432019 0.00742305209476312 0.00846959210737666 ...
             0.0100396521354396  0.00618007809100511 0.00713882068758923 ...
             0.00897098347405487 0.00704483003810026 0.00645642519548373 ...
             0.00517404783351609 0.00585876736005123 0.00509534978929015 ...
             0.00572545389104142 0.0119430779772605  0.00860511249621619]
        WORK_DIR     = '/Volumes/SeagateBP3/cvl/np755/Training'
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
    
    methods (Static)
        function saveFigs            
            theFigs = get(0, 'children');
            N = numel(theFigs);
            for f = 1:N
                aFig = theFigs(f);
                figure(aFig);
                saveas(aFig, sprintf('%03d.fig', N-f+1));
                saveas(aFig, sprintf('%03d.pdf', N-f+1));
                close(aFig);
            end
        end
    end
    
    %% PROTECTED
    
    properties (Access = 'protected')
        director_
    end   
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

