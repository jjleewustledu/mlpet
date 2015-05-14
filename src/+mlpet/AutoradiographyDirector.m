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
    
    properties (Constant)
        AUTO_FREEVIEW = false
    end
 	 
    properties (Dependent)
        product         % Autoradiography Builder obj
        aif             % IWellData obj
        mask            % INIfTId obj
        ecat            % IScannerData obj
        times           % double
        concentration_a % double
        concentration_obs % double
    end
    
    methods %% GET/SET
        function a = get.product(this)
            assert(~isempty(this.builder_));
            a = this.builder_;
        end
        function this = set.product(this, bldr)
            assert(isa(bldr, 'mlpet.AutoradiographyBuilder'));
            this.builder_ = bldr;
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
        function this = loadPET(maskFn, aifFn, ecatFn, varargin)
            p = inputParser;
            addRequired(p, 'maskFn',       @(x) lexist(x, 'file'));
            addRequired(p, 'aifFn',        @(x) lexist(x, 'file'));
            addRequired(p, 'ecatFn',       @(x) lexist(x, 'file'));
            addOptional(p, 'dcvShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(p, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(p, maskFn, aifFn, ecatFn, varargin{:});
            
            import mlpet.*;           
            this = AutoradiographyDirector( ...
                   PETAutoradiography.load( ...
                       p.Results.maskFn, p.Results.aifFn, p.Results.ecatFn, ...
                       p.Results.dcvShift, p.Results.ecatShift));
        end
        function this = loadPETHersc(maskFn, aifFn, ecatFn, varargin)
            p = inputParser;
            addRequired(p, 'maskFn',       @(x) lexist(x, 'file'));
            addRequired(p, 'aifFn',        @(x) lexist(x, 'file'));
            addRequired(p, 'ecatFn',       @(x) lexist(x, 'file'));
            addOptional(p, 'dcvShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(p, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(p, maskFn, aifFn, ecatFn, varargin{:});
            
            import mlpet.*;           
            this = AutoradiographyDirector( ...
                   PETHerscAutoradiography.load( ...
                       p.Results.maskFn, p.Results.aifFn, p.Results.ecatFn, ...
                       p.Results.dcvShift, p.Results.ecatShift));
        end
        function this = loadDSC(maskFn, aifMaskFn, aifFn, ecatFn, varargin)
            p = inputParser;
            addRequired(p, 'maskFn',       @(x) lexist(x, 'file'));
            addRequired(p, 'aifMaskFn',    @(x) lexist(x, 'file'));
            addRequired(p, 'aifFn',        @(x) lexist(x, 'file'));
            addRequired(p, 'ecatFn',       @(x) lexist(x, 'file'));
            addOptional(p, 'dscShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(p, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(p, maskFn, aifMaskFn, aifFn, ecatFn, varargin{:});
            
            import mlpet.*;           
            this = AutoradiographyDirector( ...
                   DSCAutoradiography.load( ...
                       p.Results.maskFn, p.Results.aifMaskFn, p.Results.aifFn, p.Results.ecatFn, ...
                       p.Results.dscShift, p.Results.ecatShift));
        end
        function this = loadDSCHersc(maskFn, aifMaskFn, aifFn, ecatFn, varargin)
            p = inputParser;
            addRequired(p, 'maskFn',       @(x) lexist(x, 'file'));
            addRequired(p, 'aifMaskFn',    @(x) lexist(x, 'file'));
            addRequired(p, 'aifFn',        @(x) lexist(x, 'file'));
            addRequired(p, 'ecatFn',       @(x) lexist(x, 'file'));
            addOptional(p, 'dscShift',  0, @(x) isnumeric(x) && isscalar(x));
            addOptional(p, 'ecatShift', 0, @(x) isnumeric(x) && isscalar(x));
            parse(p, maskFn, aifMaskFn, aifFn, ecatFn, varargin{:});
            
            import mlpet.*;           
            this = AutoradiographyDirector( ...
                   DSCHerscAutoradiography.load( ...
                       p.Results.maskFn, p.Results.aifMaskFn, p.Results.aifFn, p.Results.ecatFn, ...
                       p.Results.dscShift, p.Results.ecatShift));
        end
        function this = loadVideen(maskFn, aifFn, ecatFn, varargin)
            p = inputParser;
            addRequired(p, 'maskFn',       @(x) lexist(x, 'file'));
            addRequired(p, 'aifFn',        @(x) lexist(x, 'file'));
            addRequired(p, 'ecatFn',       @(x) lexist(x, 'file'));
            addOptional(p, 'dcvShift',  16, @(x) isnumeric(x) && isscalar(x));
            addOptional(p, 'ecatShift', 5, @(x) isnumeric(x) && isscalar(x));
            parse(p, maskFn, aifFn, ecatFn, varargin{:});
            
            import mlpet.*;           
            this = AutoradiographyDirector( ...
                   VideenAutoradiography.load( ...
                       p.Results.maskFn, p.Results.aifFn, p.Results.ecatFn, ...
                       p.Results.dcvShift, p.Results.ecatShift));
        end        
        
        %% PREPARATIONS
        
        function        prepareAparcmask
            import mlpet.*;
            pth  = pwd;
            pnum = str2pnum(pwd);
            AutoradiographyDirector.aparc2mask( ...
                fullfile(pth, 'aparc.a2009s+aseg.mgz'));
            AutoradiographyDirector.renameTr( ...
                fullfile(pth, [pnum 'tr1_01.nii.gz']));
            AutoradiographyDirector.flirtOntoRef( ...
                fullfile(pth, 'orig.mgz'), ...
                fullfile(pth, [pnum 'tr1.nii.gz']));
            AutoradiographyDirector.applyxfmToAparcmask( ...
                fullfile(pth, ['orig_on_' pnum 'tr1.mat']));
            if (AutoradiographyDirector.AUTO_FREEVIEW)
                mlbash(sprintf('freeview %str1.nii.gz aparc_a2009s+aseg_mask_on_%str1.nii.gz', pnum, pnum));
            end
        end
        function        prepareAparcmask2
            import mlpet.*;
            pth  = pwd;
            pnum = str2pnum(pwd);
            dnii = mlfourd.DynamicNIfTId.load([pnum 'ho1.nii.gz']);
            dnii = dnii.timeSummed;
            dnii.save;
            
            AutoradiographyDirector.flirtOntoRef( ...
                fullfile(pth, 'brain.mgz'), ...
                fullfile(pth, [pnum 'ho1_sumt.nii.gz']));
            AutoradiographyDirector.applyxfmToAparcmask( ...
                fullfile(pth, ['brain_on_' pnum 'ho1_sumt.mat']));
            if (AutoradiographyDirector.AUTO_FREEVIEW)
                mlbash(sprintf('freeview %sho1_sumt.nii.gz aparc_a2009s+aseg_mask_on_%sho1_sumt.nii.gz', pnum, pnum)); 
            end
        end
        function        prepareAparcmask3
            import mlpet.*;
            pth  = pwd;
            pnum = str2pnum(pwd);
            bnii = mlfourd.BlurringNIfTId.load([pnum 'ho1_sumt.nii.gz']);
            bnii = bnii.blurred([10 10 10]);
            bnii.save;
            
            AutoradiographyDirector.flirtOntoRef( ...
                fullfile(pth, [pnum 'ho1_sumt_101010fwhh.nii.gz']), ...
                fullfile(pth, 'orig.nii.gz'));
            AutoradiographyDirector.invertXfm( ...
                fullfile(pth, [pnum 'ho1_sumt_101010fwhh_on_orig.mat']), ...
                fullfile(pth, ['orig_on_' pnum 'ho1_sumt_101010fwhh.mat']));
            AutoradiographyDirector.applyxfmToAparcmask( ...
                fullfile(pth, ['orig_on_' pnum 'ho1_sumt_101010fwhh.mat']));
            if (AutoradiographyDirector.AUTO_FREEVIEW)
                mlbash(sprintf('freeview %sho1_sumt.nii.gz aparc_a2009s+aseg_mask_on_%sho1_sumt.nii.gz', pnum, pnum)); 
            end
        end
        function tvec = prepareHo
            import mlfourd.* mlpet.*;
            pth  = pwd;
            pnum = str2pnum(pth);
            hofn = fullfile(pth, [pnum 'ho1.nii.gz']);
            
            dyn  = DynamicNIfTId.load(hofn);
            dyn  = dyn.mcflirtedAfterBlur([10 10 10]);
            dyn  = dyn.revertFrames(NIfTId.load(hofn), 1:7);
            dyn  = dyn.masked(NIfTId.load(AutoradiographyDirector.maskFilename(pth)));
                   dyn.save;
            if (AutoradiographyDirector.AUTO_FREEVIEW)
                   dyn.freeview; end
            dyn  = dyn.volumeSummed;
            tvec = squeeze(dyn.img);
            if (AutoradiographyDirector.AUTO_FREEVIEW)
                   plot(tvec); 
                   title('AutoradiographyDirector.prepareHo'); 
                   ylabel('well-counts');
                   xlabel('time/s');
            end
        end
        function        blurHo
            import mlfourd.* mlpet.*;
            pth   = pwd;
            pnum  = str2pnum(pth);
            hofn  = fullfile(pth, [pnum 'ho1.nii.gz']);           
            
            dyn = DynamicNIfTId.load(hofn);
            dyn = dyn.blurred([16 16 16]);
            dyn = dyn.masked(NIfTId.load(AutoradiographyDirector.maskFilename(pth)));
            dyn.save;
            
            [~,hofp] = filepartsx(hofn, '.nii.gz');
            mlbash(sprintf('cp %s.img.rec %s.img.rec', hofp, dyn.fileprefix));
            if (AutoradiographyDirector.AUTO_FREEVIEW)
                dyn.freeview; end
        end
        function        prepareEp2dmask
            import mlfourd.*;
            pth = pwd;
            meanvolFn = fullfile(pth, 'ep2d_default_mcf_meanvol.nii.gz');
            mcfFn     = fullfile(pth, 'ep2d_default_mcf.nii.gz');
            maskFn    = fullfile(pth, 'ep2d_mask.nii.gz');
            
            msk = MaskingNIfTId(NIfTId.load(meanvolFn), 'pthresh', 0.2);
            msk.saveas(maskFn);
            
            dyn = DynamicNIfTId(NIfTId.load(mcfFn), 'mask', msk);
            dyn.save;
            %dyn.freeview;
        end
        function        aparc2mask(fn)
            fn = mlpet.AutoradiographyDirector.removeAparcDot(fn);
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
        function        flirtOntoRef(origfn, reffn, varargin)
            p = inputParser;
            addRequired(p, 'origfn',          @(x) lexist(x, 'file'));
            addRequired(p, 'reffn',           @(x) lexist(x, 'file'));
            addOptional(p, 'cost',  'normmi', @ischar);
            parse(p, origfn, reffn, varargin{:});
            
            import mlpet.*;
            if (lstrfind(origfn, '.mgz'))
                origfn = AutoradiographyDirector.convert2niigz(origfn); end
            [~,origfp] = filepartsx(origfn, '.nii.gz');
            [pth,trfp] = filepartsx(reffn,   '.nii.gz');
            outfn = fullfile(pth, [origfp '_on_' trfp '.nii.gz']);
            matfn = fullfile(pth, [origfp '_on_' trfp '.mat']);
            mlbash(sprintf( ...
                'flirt -in %s -ref %s -out %s -omat %s -bins 256 -cost %s -dof 6 -interp trilinear', ...
                origfn, reffn, outfn, matfn, p.Results.cost)); %% corratio, normmi
        end
        function        invertXfm(matIn, matOut)
            mlbash(sprintf('convert_xfm -omat %s -inverse %s', matOut, matIn));
        end
        function        applyxfmToAparcmask(matfn)
            pth    = filepartsx(matfn, '.nii.gz');
            if (~isempty(pth))
                pnum = str2pnum(pth);
            else
                pnum = str2pnum(pwd);
            end
            if (strfind(matfn, 'tr'))
                studyCode = 'tr1';
            elseif (strfind(matfn, 'ho1_sumt'))
                studyCode = 'ho1_sumt';
            else
                error('mlpet:unsupportedFilename', ...
                    'AutoradiographyDirector.applyxfmToAparcmask has limited functionality for xfm filenames; found %s', matfn);
            end
            maskfp = 'aparc_a2009s+aseg_mask';
            maskfn = fullfile(pth, [maskfp '.nii.gz']);
            outfn  = fullfile(pth, [maskfp '_on_' pnum studyCode '.nii.gz' ]);
            reffn  = fullfile(pth, [pnum studyCode '.nii.gz']);
            mlbash(sprintf( ...
                'flirt -in %s -applyxfm -init %s -out %s -interp nearestneighbour -ref %s', ...
                maskfn, matfn, outfn, reffn));
        end
        function [cbf,aflow,bflow] = getVideenCbf
            import mlfourd.* mlpet.*;
            pth  = pwd;
            pnum = str2pnum(pth);
            
            mnii = MaskingNIfTId.load(fullfile(pth, [pnum 'ho1_g3.nii.gz']));
            msk  = NIfTId.load(AutoradiographyDirector.maskFilename(pth));
            mnii = mnii.masked(msk);
            
            [aflow,bflow] = AutoradiographyDirector.videenCoeffs(fullfile(pth, [pnum 'ho1_g3.hdr.info']));
            pett = MaskingNIfTId.sumall(mnii)/MaskingNIfTId.sumall(msk);
            cbf  = aflow*pett*pett + bflow*pett;
            
            fprintf('AutoradiographyDirector.getVideenCbf:\n');
            fprintf('\tcbf %g, aflow %12.8G, bflow %12.8G\n', cbf, aflow, bflow);
        end
        
        function aif  = prepareLaif2
            import mlperfusion.*;            
            pth   = pwd;   
            dscFn = fullfile(pth, 'ep2d_default_mcf_masked.nii.gz');
            mskFn = fullfile(pth, 'ep2d_mask.nii.gz');
            storageFn = fullfile(pth, 'DSCAutoradiography_loadAif_aif.mat');     
            
            wbDsc = WholeBrainDSC(dscFn, mskFn);
            aif = Laif2.runLaif(wbDsc.times, wbDsc.itsMagnetization); 
            save(storageFn, 'aif');
        end
    end
    
    methods 
        function this = simulateItsMcmc(this)
            %% SIMULATEITSMCMC returns an entirely synthetic Autoradiography (viz., builder, product) object
            
            this.builder_ =  ...
                this.builder_.simulateItsMcmc(this.concentration_a);
            this.builder_.plotProduct;
        end
        function this = estimateAll(this)
            %% ESTIMATEALL returns an Autoradiography (builder, product) object based on aif, ecat &
            %  mutually consistent times
            
            this.builder_ = this.builder_.estimateAll;
            this.builder_.plotProduct
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
    
    methods (Static, Access = 'private')        
        function       renameTr(fqfn)
            try
                pth = filepartsx(fqfn, '.nii.gz');
                mlbash(sprintf('mv %s %str1.nii.gz', fqfn, fullfile(pth, str2pnum(fqfn))))
            catch ME
                handexcept(ME);
            end
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
        function fn  = maskFilename(pth)  
            pnum = str2pnum(pth);
            if (lexist(    fullfile(pth, ['aparc_a2009s+aseg_mask_on_' pnum 'tr1.nii.gz']), 'file'))
                fn =       fullfile(pth, ['aparc_a2009s+aseg_mask_on_' pnum 'tr1.nii.gz']);
            elseif (lexist(fullfile(pth, ['aparc_a2009s+aseg_mask_on_' pnum 'ho1_sumt.nii.gz']), 'file'))
                fn =       fullfile(pth, ['aparc_a2009s+aseg_mask_on_' pnum 'ho1_sumt.nii.gz']);
            else
                error('mlpet:requiredFileNotFound', ...
                      'AutoradiographyDirector.maskFilename could not find mask NIfTI file');
            end
        end        
        function [aflow,bflow] = videenCoeffs(hdrfilename)
            %% MODELFLOWS
            %  Usage:  [aflow bflow] = modelFlows(hdrfilename)
            %           hdrfilename:   *.hdr.info text-file
            %           aflow, bflow: values from ho1 hdr files
            %
            %       Herscovitch P, Markham J, Raichle ME. Brain blood flow measured
            % with intravenous H2(15)O: I. theory and error analysis.
            % J Nucl Med 1983;24:782??789
            %       Videen TO, Perlmutter JS, Herscovitch P, Raichle ME. Brain
            % blood volume, blood flow, and oxygen utilization measured with
            % O-15 radiotracers and positron emission tomography: revised metabolic
            % computations. J Cereb Blood Flow Metab 1987;7:513??516
            %       Herscovitch P, Raichle ME, Kilbourn MR, Welch MJ. Positron
            % emission tomographic measurement of cerebral blood flow and
            % permeability: surface area product of water using [15O] water and
            % [11C] butanol. J Cereb Blood Flow Metab 1987;7:527??542
            
            import mlfourd.*;
            EXPRESSION = { ...
                'A Coefficient \(Flow\)\s*=\s*(?<aflow>\d+\.?\d*E-?\d*)' ...
                'B Coefficient \(Flow\)\s*=\s*(?<bflow>\d+\.?\d*E-?\d*)' };
            import mlfourd.*;
            contents = cell(1,1);
            aflow = -1; bflow = -1;
            try
                fid = fopen(hdrfilename);
                i   = 1;
                while 1
                    tline = fgetl(fid);
                    if ~ischar(tline),   break,   end
                    contents{i} = tline;
                    i = i + 1;
                end
                fclose(fid);
            catch ME
                disp(ME);
                warning('mfiles:IOErr', ['modelFlows:  could not process file ' hdrfilename ' with fid ' num2str(fid)]);
            end
            cline = '';
            try
                for j = 1:length(contents) %#ok<FORFLG>
                    cline = contents{j}; 
                    if (strcmp('A Coef', cline(2:7)))
                        [~, names] = regexpi(cline, EXPRESSION{1},'tokens','names'); 
                        aflow      = str2double(names.aflow); 
                    end
                    if (strcmp('B Coef', cline(2:7)))
                        [~, names] = regexpi(cline, EXPRESSION{2},'tokens','names');
                        bflow      = str2double(names.bflow); 
                    end
                end 
            catch ME
                fprintf('AutoradiographyDirector.videenCoeffs:  could not find coeffients of flow from file %s\n', hdrfilename);
                handexcept(ME, 'mlpet:internalDataErr', 'videenCoeffs:  regexpi failed for %s', cline);
            end
        end 
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

