classdef AutoradiographyDirector  
	%% AUTORADIOGRAPHYDIRECTOR uses the builder design pattern to separate the processes/algorithms  
    %  for constructing autoradiography objects from object representations specific to PET, MR-PET.
    %  All autoradiography builders must conform to AutoradiographyBuilder although unnecessary 
    %  methods may be left empty.  

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 
    properties (Dependent)
        product         % Autoradiography Builder obj
        aif             % IWellData obj
        mask            % INIfTId obj
        ecat            % IScannerData obj
        times           % double
        concentration_a % double
        concentration_obs % double
    end
    
    methods %% GET
        function a = get.product(this)
            assert(~isempty(this.builder_));
            a = this.builder_;
        end
        function a = get.aif(this)
            a = this.builder_.aif;
        end
        function a = get.mask(this)
            a = this.builder_.mask;
        end
        function a = get.ecat(this)
            a = this.builder_.ecat;
        end
        function t = get.times(this)
            t = this.builder_.times;
        end
        function t = get.concentration_a(this)
            t = this.builder_.concentration_a;
        end
        function t = get.concentration_obs(this)
            t = this.builder_.concentration_obs;
        end
    end
    
    methods (Static)
        function this = loadPET(maskFn, aifFn, pie, ecatFn, varargin)
            p = inputParser;
            addRequired(p, 'maskFn',       @(x) lexist(x, 'file'));
            addRequired(p, 'aifFn',        @(x) lexist(x, 'file'));
            addRequired(p, 'pie',          @(x) isnumeric(x) && isscalar(x));
            addRequired(p, 'ecatFn',       @(x) lexist(x, 'file'));
            addOptional(p, 'dcvShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(p, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(p, maskFn, aifFn, pie, ecatFn, varargin{:});
            
            import mlpet.*;           
            this = AutoradiographyDirector( ...
                   PETAutoradiography.load( ...
                       p.Results.maskFn, p.Results.aifFn, p.Results.pie, p.Results.ecatFn, ...
                       p.Results.dcvShift, p.Results.ecatShift));
        end
        function this = loadDSC(maskFn, aifMaskFn, aifFn, pie, ecatFn, varargin)
            p = inputParser;
            addRequired(p, 'maskFn',       @(x) lexist(x, 'file'));
            addRequired(p, 'aifMaskFn',    @(x) lexist(x, 'file'));
            addRequired(p, 'aifFn',        @(x) lexist(x, 'file'));
            addRequired(p, 'pie',          @(x) isnumeric(x) && isscalar(x));
            addRequired(p, 'ecatFn',       @(x) lexist(x, 'file'));
            addOptional(p, 'dcvShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(p, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(p, maskFn, aifMaskFn, aifFn, pie, ecatFn, varargin{:});
            
            import mlpet.*;           
            this = AutoradiographyDirector( ...
                   DSCAutoradiography.load( ...
                       p.Results.maskFn, p.Results.aifMaskFn, p.Results.aifFn, p.Results.pie, p.Results.ecatFn, ...
                       p.Results.dcvShift, p.Results.ecatShift));
        end
        function aparc2mask(fn)
            fn = mlpet.AutoradiographyWorker.removeAparcDot(fn);
            assert(lstrfind(fn, 'a2009s') && lstrfind(fn, 'aseg'));
            toremove = [16 7 8 46 47 14 15 4 43 31 63 24]; % brainstem cerebellumx4 ventriclesx4 choroidplexus csf
            
            import mlfourd.*;
            niid = NIfTId.load(fn);
            for r = 1:length(toremove)
                niid.img(niid.img == toremove(r)) = 0;
            end
            niid.img = double(niid.img > 0);
            niid = niid.append_fileprefix('_mask');
            niid.save;
        end
        function flirtOrigOnTr(origfn, trfn)
            import mlpet.AutoradiographyWorker.*;
            if (lstrfind(origfn, '.mgz'))
                origfn = convert2niigz(origfn); end
            [~,origfp] = filepartsx(origfn, '.nii.gz');
            [pth,trfp] = filepartsx(trfn,   '.nii.gz');
            outfn = fullfile(pth, [origfp '_on_' trfp '.nii.gz']);
            matfn = fullfile(pth, [origfp '_on_' trfp '.mat']);
            mlbash(sprintf( ...
                'flirt -in %s -ref %s -out %s -omat %s -bins 256 -cost normmi -dof 6 -interp trilinear', ...
                origfn, trfn, outfn, matfn));
        end
        function applyxfmToAparcmask(matfn)
            pth    = filepartsx(matfn, '.nii.gz');
            pnum   = str2pnum(pth);
            maskfp = 'aparc_a2009+aseg_mask';
            maskfn = fullfile(pth, [maskfp '.nii.gz']);
            outfn  = fullfile(pth, [maskfp '_on_' pnum 'tr1.nii.gz' ]);
            reffn  = fullfile(pth, [pnum 'tr1.nii.gz']);
            mlbash(sprintf( ...
                'flirt -in %s -applyxfm -init %s -out %s -interp nearestneighbour -ref %s', ...
                maskfn, matfn, outfn, reffn));
        end
        function tvec = prepareHo
            import mlfourd.*;
            pnum = str2pnum(pwd);
            hofn = fullfile(pwd, [pnum 'ho1.nii.gz']);
            maskfn = fullfile(pwd, ['aparc_a2009s+aseg_mask_on_' pnum 'tr1.nii.gz']);
            dyn  = DynamicNIfTId.load(hofn);
            dyn  = dyn.mcflirtedAfterBlur([16 16 16]);
            dyn  = dyn.revertFrames(NIfTId.load(hofn), 1:7);
            dyn  = dyn.masked(NIfTId.load(maskfn));
            dyn  = dyn.volumeSummed;
            tvec = sqeeze(dyn.img);
            plot(tvec);
        end
        function fn1 = removeAparcDot(fn)
            [pth,fp,ext] = fileparts(fn);
            if (strncmp(fp, 'aparc.', 6))
                fp(1:6) = 'aparc_';
                fn1 = fullfile(pth, [fp ext]);
                mlbash(sprintf('cp %s %s', fn, fn1));
            end
        end
        function fn1 = convert2niigz(fn)
            [pth,fp] = fileparts(fn);
            fn1 = fullfile(pth, [fp '.nii.gz']);
            mlbash(sprintf('mri_convert %s %s', fn, fn1));
        end
    end
    
    methods 
        function this = simulateItsMcmc(this)
            %% SIMULATEITSMCMC returns an entirely synthetic Autoradiography (viz., builder, product) object
            
            this.builder_ =  ...
                this.builder_.simulateItsMcmc(this.concentration_a);
            this.builder_.plotProduct;
        end
        function this = runItsAutoradiography(this)
            %% RUNITSAUTORADIOGRAPHY returns an Autoradiography (builder, product) object based on aif, ecat &
            %  mutually consistent times
            
            this.builder_ = ...
                this.builder_.runAutoradiography(this.concentration_a, this.times, this.concentration_obs);
            this.builder_.plotProduct;
        end
        function this = estimatePriors(this)
        end
        
 		function this = AutoradiographyDirector(buildr) 
 			%% AUTORADIOGRAPHYDIRECTOR 
 			%  Usage:  director = AutoradiographyDirector(AutoradiographyBuilder_object) 
            
            import mlpet.* mlfourd.*;
            assert(isa(buildr, 'mlpet.AutoradiographyBuilder'));            
            this.builder_ = buildr;
        end
        function        plotInitialData(this)
            this.builder_.plotInitialData;
        end
        function        plotParVars(this, par, vars)
            this.builder_.plotParVars(par, vars);
        end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        builder_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

