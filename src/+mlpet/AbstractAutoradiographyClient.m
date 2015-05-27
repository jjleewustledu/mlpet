classdef (Abstract) AbstractAutoradiographyClient  
	%% ABSTRACTAUTORADIOGRAPHYCLIENT   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
    
    properties (Abstract)
        moyamoyaCases
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
                 this.moyamoyaCases, 'UniformOutput', false);
        end
        function p  = get.workPath(~)
            p = pwd; %% KLUDGE
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

