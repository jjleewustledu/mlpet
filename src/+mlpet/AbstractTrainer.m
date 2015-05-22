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
            'mm01-009_p7660_2010jun22'
            'mm01-025_p7470_2009aug10'
            'mm01-029_p7577_2010mar1'
            'mm02-001_p7146_2008jan4'
            'mm02-001_p7384_2009feb13'
            'mm02-001_p7770_2011jan24'            
            'mm06-001_p7321_2008sep8' } %   'mm01-009_p7266_2008jun16' 'mm03-001_p7229_2008apr28'
        DCV_SHIFTS   = [-15 -17 -23 -16 -16 -15       -30 -18 -11 -30 -20 -21       -13] % -23 -34 
        ECAT_SHIFTS  = [  0  -2  -3   0  -3  -3       -13  -3   0 -15  -8  -8        -1] %   0 -10
        ECAT_SHIFTS2 = [  0   0   0   0   0   0         0   0   0  10   0   0         0]
        VIDEEN_FLOWS = ...
            [0.00730699976432019 0.00742305209476312 0.00846959210737666 ...
             0.0100396521354396  0.00618007809100511 0.00713882068758923 ...
                                 0.00704483003810026 0.00645642519548373 ...
             0.00517404783351609 0.00585876736005123 0.00509534978929015 ...
             0.00572545389104142                     0.00860511249621619]
        PET_FLOWS = ...
            [0.010465 0.009474 0.01095 ...
             0.012283 0.01177  0.006818 ...
                      0.01008  0.010344 ...
             0.008857 0.008671 0.006023 ...
             0.011005          0.012072]
        PETHERSC_FLOWS = ...
            [0.010036 0.008734 0.010464 ...
             0.012277 0.01229  0.006254 ...
                      0.009396 0.01011 ...
             0.007832 0.008081 0.005413 ...
             0.010624          0.011845]
        A0 = [0.008961 0.009234 0.009877 0.009586 0.007695 0.013967 0.009157  0.009011 0.007553 0.009571 0.012553 0.007262  0.009547]
        Ew = [0.907717 0.911242 0.894694 0.929659 0.906637 0.89779  0.895336  0.920644 0.861967 0.909823 0.90071  0.924817  0.906658]
        PS = [0.030459 0.033911 0.029452 0.036118 0.035102 0.033286 0.030588  0.026589 0.028538 0.032795 0.028021 0.033142  0.031255]
        A  = [1.826823 3.980367 4.615217 0.280722 3.703919 3.593586 7.960085  4.253388 2.167704 5.024727 2.256674 0.559928  1.429512]
        D  = [0.92436  0.976998 0.953245 1.020942 0.927668 0.931662 1.006895  0.893323 0.877977 0.886973 0.957254 0.943556  0.957946]
        % D_DSC      [0.927521 0.976488 0.954647 1.020359 0.930747 0.927566 1.00843 0.90099 0.902483 0.887405 0.956771 0.944668 0.958372]
        % D_DSCHERSC [0.928449 0.978447 0.963418 1.021509 0.944248 0.930641 1.029721 0.902045 0.905826 0.88816 0.99997 0.977593 0.966599]
        P  = [0.245801 0.414169 0.385202 0.272528 0.327217 0.386138 0.534507  0.234991 0.286319 0.225262 0.400037 0.260478  0.290438]
        Q0_DSC      = [20351998.044778 18975454.105974 16923503.7031 16899337.364145 20245498.751932 12353790.24278  16288896.175678 15776415.245952 26528115.534134 19975714.804799 22066962.188692 21376581.949367 13025094.378904]
        Q0_DSCHERSC = [19700226.774714 17932789.460333 16054561.8918 16696992.987695 19363864.258283 11291024.114326 14221748.651733 15594000.049838 24121634.497521 18810326.851312 19468835.513939 19824849.361625 12735714.947648]
        T0_DSC      = [1.899118 2.251684 4.264742 0.80612  6.389927 2.997906 14.658316 2.63802  0.300566 0.325272 9.130395 10.880811 4.199567]
        T0_DSCHERSC = [1.896655 1.892467 1.879929 0.803885 1.949936 2.273611  1.92049  1.913777 0.05175  0.272504 1.981962  2.021304 2.563806]
        WORK_DIR    = '/Volumes/SeagateBP3/cvl/np755/Training'
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

