classdef AutoradiographyTrainer  
	%% AUTORADIOGRAPHYTRAINER   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
 	 

	properties (Dependent) 		 
        workPath
        dscMaskFn
        dscFn
        aifFn
        maskFn
        ecatFn
        hdrInfoFn
        
        pnum
        pie
        dcvShift
        dscShift
        ecatShift
        product
    end 

    methods % GET
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
            fn = fullfile(this.workPath, [this.pnum 'ho1_mcf_revf1to7_masked.nii.gz']);
        end    
        function fn = get.hdrInfoFn(this)
            fn = fullfile(this.workPath, [this.pnum 'ho1_g3.hdr.info']);
        end    
        
        function n  = get.pnum(this)
            n = str2pnum(this.workPath);
        end
        function p  = get.pie(this)
            assert(~isempty(this.pie_));
            p = this.pie_;
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
        function p  = get.product(this)
            assert(~isempty(this.director_.product));
            p = this.director_.product;
        end
    end
    
	methods		  
 		function this = AutoradiographyTrainer(bldr)
 			%% AUTORADIOGRAPHYTRAINER 
 			%  Usage:  this = AutoradiographyTrainer

            assert(lstrfind(lower(bldr), {'pet' 'dsc' 'videen'}));
            this = this.readPie;       
            switch (lower(bldr))
                case 'pet'
                    this.director_ = mlpet.AutoradiographyDirector.loadPET( ...
                        this.maskFn, this.aifFn, this.pie, this.ecatFn, this.dcvShift, this.ecatShift);
                case 'dsc'
                    this.director_ = mlpet.AutoradiographyDirector.loadDSC( ...
                        this.maskFn, this.dscMaskFn, this.dscFn, this.pie, this.ecatFn, this.dscShift, this.ecatShift);
                case 'videen'
                    this.director_ = mlpet.AutoradiographyDirector.loadVideen( ...
                        this.maskFn, this.aifFn, this.pie, this.ecatFn, this.dcvShift, this.ecatShift);
            end
            this.director_ = this.director_.runItsAutoradiography;
 		end 
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        pie_
        dcvShift_ = 18
        dscShift_ = 18
        ecatShift_ = 5
        director_
    end
    
    methods (Access = 'private')
        function this = readPie(this)
            tp = mlio.TextParser.loadx(this.hdrInfoFn, '.hdr.info');
            this.pie_ = tp.parseAssignedNumeric('Pie Slope');
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

