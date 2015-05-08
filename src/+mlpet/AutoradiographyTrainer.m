classdef AutoradiographyTrainer  
	%% AUTORADIOGRAPHYTRAINER   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
 	 
    properties (Constant)        
    end
    
	properties (Dependent) 		 
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
    
	methods	(Static)
        function this = trainVideen(dcvSh, ecatSh)
            diary(sprintf('AutoradiographyTrainer.trainVideen_%s.log', datestr(now, 30)));
            import mlpet.*;
            this = AutoradiographyTrainer;
            this.dcvShift_ = dcvSh;
            this.ecatShift_ = ecatSh;
            
            [cbf,aflow,bflow] = AutoradiographyDirector.getVideenCbf;
            this.director_ = ...
                AutoradiographyDirector.loadVideen( ...
                    this.maskFn, this.aifFn, this.ecatFn, this.dcvShift, this.ecatShift);
            prod = this.product;    
            prod.f = cbf/6000/1.05;
            prod.af = aflow;
            prod.bf = bflow;
            this.director_.product = prod;
            this.director_ = this.director_.estimateAll;   
            prod = this.director_.product; %#ok<NASGU>
            save('AutoradiographyTrainer.trainVideen.prod.mat', 'prod');
            diary off
        end
        function this = trainPET(dcvSh)
            diary(sprintf('AutoradiographyTrainer.trainPET_%s.log', datestr(now, 30)));
            import mlpet.*;
            this = AutoradiographyTrainer;
            this.dcvShift_ = dcvSh;
            
            this.director_ = ...
                AutoradiographyDirector.loadPET( ...
                    this.maskFn, this.aifFn, this.ecatFn, this.dcvShift);
            this.director_ = this.director_.estimateAll;
            prod = this.director_.product; %#ok<NASGU>
            save('AutoradiographyTrainer.trainPET.prod.mat', 'prod');
            diary off
        end
        function this = trainPETHersc
            diary(sprintf('AutoradiographyTrainer.trainPETHersc_%s.log', datestr(now, 30)));
            import mlpet.*;
            this = AutoradiographyTrainer;
            this.dcvShift_ = 16;
            
            this.director_ = ...
                AutoradiographyDirector.loadPETHersc( ...
                    this.maskFn, this.aifFn, this.ecatFn, this.dcvShift);
            this.director_ = this.director_.estimateAll;
            prod = this.director_.product; %#ok<NASGU>
            save('AutoradiographyTrainer.trainPETHersc.prod.mat', 'prod');
            diary off
        end
        function this = trainDSC
            diary(sprintf('AutoradiographyTrainer.trainDSC_%s.log', datestr(now, 30)));
            import mlpet.*;
            this = AutoradiographyTrainer;
            
            this.director_ = ...
                AutoradiographyDirector.loadDSC( ...
                    this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn);
            this.director_ = this.director_.estimateAll;
            prod = this.director_.product; %#ok<NASGU>
            save('AutoradiographyTrainer.trainDSC.prod.mat', 'prod');
            diary off
        end
        function this = trainDSCHersc
            diary(sprintf('AutoradiographyTrainer.trainDSCHersc_%s.log', datestr(now, 30)));
            import mlpet.*;
            this = AutoradiographyTrainer;
            
            this.director_ = ...
                AutoradiographyDirector.loadDSCHersc( ...
                    this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn);
            this.director_ = this.director_.estimateAll;
            prod = this.director_.product; %#ok<NASGU>
            save('AutoradiographyTrainer.trainDSCHersc.prod.mat', 'prod');
            diary off
        end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        dscShift_ = 18
        dcvShift_ = 18
        ecatShift_ = 5
        director_
    end    
    
    methods (Access = 'private')
        function        plotKernel(~, o, t, dcvCurve)            
            figure;
            plot(o.times, o.estimateData, t, dcvCurve, 'o');
            legend('Bayesian DCV', 'DCV');
            title('AutoradiographyTrainer:  case kernel', 'Interpreter', 'none');
            xlabel('time/s');
            ylabel('well-counts');
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

