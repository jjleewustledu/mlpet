classdef PETMake < mlfsl.FslMake
    %% PETMAKE makes typical FSL targets for image analysis
    %  Version $Revision$ was created $Date$ by $Author$
    %  and checked into svn repository $URL$
    %  Developed on Matlab 7.10.0.499 (R2010a)
    %  $Id$
    %  N.B. classdef (Sealed, Hidden, InferiorClasses = {?class1,?class2}, ConstructOnLoad)

    properties
        makecbf   = true;
        makecbv   = true;
        makemtt   = true;
        makeoef   = true;
        makecmro2 = true;
        petFilterSuffix = '';
    end
    
    properties (Constant)
        FILES_4DFP = { '*lat*' '*g3*' '*_xr3d*' '*_msk*' '*_sqrt*' '*_t4' '*.ifh' '*.img.rec' ...
                       '*_b100.4dfp.*' '*_b10.4dfp.*' '*_b20.4dfp.*' '*_b30.4dfp.*' '*_b40.4dfp.*' ...
                       '*_b50.4dfp.*'  '*_b60.4dfp.*' '*_b70.4dfp.*' '*_b80.4dfp.*' '*_b90.4dfp.*'};
        PET_INDEX = 1;
    end
    
    properties (Dependent)
        path962
        petTracers
        petTries
        petNames
        petFileprefixes
        petFilenames
    end  
    
    methods
        
        function this = PETMake(varargin)
            
            %% PETMAKE (ctor)
            %  Usage:  obj = PETMake([filter, orientationFlips]);
            %                         ^ string to filter dir listing at current dir
            %                                 ^ struct specifying orientations of corrections, e. g.,
            %                                   struct('pet','x','ase','z','ep2d','','asl','z','flair','z');
            this = this@mlfsl.FslMake(varargin{:});
            deprecated('mlpet.PETMake');
            if (this.verbose)
                fprintf('PETMake.ctor:    current   working path is %s\n\n', pwd);
            end
        end % PETMake (ctor)
        
        

        function pth  = get.path962(this)
            pth = this.fslf.path962;
        end 
        
        function t    = get.petTracers(this)
            t = this.fslf.petTracers;
        end
        
        function t    = get.petTries(this)
            t = this.fslf.petTries;
        end
        
        function nms  = get.petNames(this)
            nms = cellfun(@(x)[x '*'], this.petTracers, 'UniformOutput', false);
        end

        function dirp = get.petFilenames(this)
            
            %% GET.PETFILENAMES returns a struct-array of pet-tries with fields ho, oo, oc,
            %                  containing PET filenames
            import mlfourd.* mlfsl.*;
            dirp = struct('ho', {}, 'oo', {}, 'oc', {});           % will grow to become struct-array
            for p = 1:length(this.petFileprefixes)                 %#ok<FORFLG>
                dirp(p).ho = filename(this.petFileprefixes(p).ho); %#ok<PFBNS>
                dirp(p).oo = filename(this.petFileprefixes(p).oo);
                dirp(p).oc = filename(this.petFileprefixes(p).oc);
            end
        end % get.petFilenames
        
        function dirp = get.petFileprefixes(this)
            
            %% GET.PETPREFIXES returns a struct-array of pet-tries with fields ho, oo, oc,
            %                  containing PET fileprefixes
            import mlfourd.* mlfsl.*;
            Ntries = length(this.petTries);
            hc = cell(1,Ntries); oc = cell(1,Ntries); cc = cell(1,Ntries);
            hi = 1;              oi = 1;              ci = 1;
            for c = 1:Ntries %#ok<FORFLG,PFUNK>
                for t = 1:length(this.petTracers) %#ok<PFBNS>
                    
                    switch (this.petTracers{t}(1:2))
                        case 'ho'
                            tmp = [this.petTracers{t} 'sum' this.petTries{c} this.rotSuff];
                            if (exist(filename(tmp), 'file'))
                                hc{hi} = tmp;  %#ok<PFPIE>
                            else
                                %warning('mlfsl:fileNotFound', 'PETMake.get.petFileprefixes could not find %s\n', filename(tmp));
                                hc{hi} = hc{max(hi-1,1)};
                            end
                            hi  = hi + 1;
                        case 'oo'
                            tmp = [this.petTracers{t} 'sum' this.petTries{c} this.rotSuff];
                            if (exist(filename(tmp), 'file'))
                                oc{oi} = tmp;  %#ok<PFPIE>
                            else
                                %warning('mlfsl:fileNotFound', 'PETMake.get.petFileprefixes could not find %s\n', filename(tmp));
                                oc{oi} = oc{max(oi-1,1)};
                            end
                            oi  = oi + 1;
                        case 'oc'
                            tmp = [this.petTracers{t}       this.petTries{c} this.rotSuff];
                            if (exist(filename(tmp), 'file'))
                                cc{ci} = tmp;  %#ok<PFPIE>
                            else
                                %warning('mlfsl:fileNotFound', 'PETMake.get.petFileprefixes could not find %s\n', filename(tmp));
                                cc{ci} = cc{max(ci-1,1)};
                            end
                            ci  = ci + 1;
                        otherwise
                    end
                end % for t
            end % for c
            dirp = struct('ho', hc, 'oo', oc, 'oc', cc); % will grow to become struct-array
        end % get.petFileprefixes
        
        function this   = reorient(this)
            
            %% REORIENT
            try

                % do business
                pcells = cellfun(@(x)[x '*'], this.petTracers, 'UniformOutput', false);
                pcells = dir2cell(pcells);
                flips  = this.orientationFlips.pet;
                for p = 1:length(pcells)
                    if (~isempty(strfind( pcells{p}, mlfourd.INIfTI.FILETYPE_EXT)))
                        mlpet.PETMake.orientRepair(pcells{p}, flips);
                    end
                end
            catch MEloop
                handwarning(MEloop, ['skipping idx->' num2str(idx)]);
            end % try
        end % reorient
        
        function this   = coregisterPet(this)
            
            %% COREGISTERPET
            %
            import mlfsl.* mlfourd.*;
            copyfiles(fullfile(this.bettedPath, [this.ref_fps{1} '_mask']));
            flirtf = FlirtBuilder;
            try
                pfp = this.petFileprefixes;
                hi  = 2;
                oi  = 2;
                ci  = 1;
                %%for hi = 1:length(pfp) %#ok<FORFLG>
                %%    for oi = 1:length(pfp)
                %%        for ci = 1:length(pfp)
                        
                if (~isempty(pfp(hi).ho) && ...
                    ~isempty(pfp(oi).oo) && ...
                    ~isempty(pfp(ci).oc))
                             flirtf.flirtPet({[' -H ' pfp(hi).ho ...
                                               ' -O ' pfp(oi).oo ...
                                               ' -C ' pfp(ci).oc]}); %#ok<PFBNS>
                elseif (~isempty(pfp(hi).ho) && ...
                        ~isempty(pfp(oi).oo))
                             flirtf.flirtPet({[' -H ' pfp(hi).ho ...
                                               ' -O ' pfp(oi).oo]});
                end
            catch ME
                handwarning(ME);
            end
        end % coregisterPet
        
        function this   = coregisterPetOn(this, target_fp)
            
            %% REGISTERPETTO
            %  Usage:   this = this.coregisterPetOn(target_fp)
            %                                     ^ e.g., 'base_rot_mcf_meanvol'
            import mlfsl.* mlfourd.*;
            target_fp = fileprefix(target_fp);
            
            % gather files
            pwd0 = pwd;
            cd(this.bettedPath);
            copyfiles( ...
                dir2cell( ...
                    cellfun(@(x) fullfile(this.fslPath, [x '*']), this.petTracers, 'UniformOutput', false)));
%            betless_ref_fp = BetBuilder.stripbet(this.ref_fp);
%            copyfiles(fullfile(this.fslPath, filename(betless_ref_fp)));
%             assert(2 == exist(                                       filename(target_fp), 'file'), ...
%                  ['PETMake.coregisterPetOn:  could not find ' fullfile(pwd, filename(target_fp))]);
%             assert(2 == exist(                                       filename(betless_ref_fp), 'file'), ...
%                  ['PETMake.coregisterPetOn:  could not find ' fullfile(pwd, filename(betless_ref_fp))]);
            
            N   = length(this.petFilenames);
            fho = cell(1,N); foo  = cell(1,N); foc  = cell(1,N);
            
            
            % register filtered PET to target_fp;             NO PARFOR
            for p = 1:N                                       %#ok<FORFLG>
                fho{p} = fileprefix(this.petFilenames(p).ho); 
                foo{p} = fileprefix(this.petFilenames(p).oo);
                foc{p} = fileprefix(this.petFilenames(p).oc);
            end
            this.flirt2steps( ...
                 cellfun(@(x)[x this.petFilterSuffix], fho, 'UniformOutput', false), ...
                 target_fp, this.ref_fp, fho);
            this.flirt2steps( ...
                 cellfun(@(x)[x this.petFilterSuffix], foo, 'UniformOutput', false), ...
                 target_fp, this.ref_fp, foo);
            this.flirt2steps( ...
                 cellfun(@(x)[x this.petFilterSuffix], foc, 'UniformOutput', false), ...
                 target_fp, this.ref_fp, foc);
                          
            % kludge to register the oo-ho ratio of counts
            flirtb = mlfsl.FlirtBuilder;
            copyfiles(fullfile(this.fslPath, ['oosum_rothosum_rot_on_' this.ref_fp]));
            flirtb.applyTransform(target_fp, ['oosum_rothosum_rot_on_' this.ref_fp], ['oosum_rothosum_rot_ratio_on_' target_fp], ...
                            flirtb.xfmName(this.ref_fp, target_fp));
            cd(pwd0);
        end % coregisterPetOn
        
        function this   = flirtPETOntoRefs(this, fcells, ref_fps)
            
            %% FLIRTPETONTOREFS works on only PET from the current directory
            import mlfsl.*;
            if (~exist('fcells', 'var'));  fcells  = dir2cell(this.petNames); end
            if (~iscell(fcells));          fcells  = {fcells};                end
            fcells1 = {[]};
            f1      = 0;
            for f = 1:length(fcells) %#ok<FORFLG,PFUNK>
                if (isempty(strfind(fcells{f}, mlfsl.FlirtVisitor.XFM_SUFFIX)) && ...
                    isempty(strfind(fcells{f}, '_on_')))
                            f1  = f1 + 1;
                    fcells1{f1} = fcells{f}; %#ok<PFPIE,PFOUS>
                end
            end
                                           fcells  = fileprefixes(fcells);
            if (~exist('ref_fps', 'var')); ref_fps = this.fslf.t1('fp');     end
            if (~iscell(ref_fps));         ref_fps = {ref_fps};              end
            
%             tmp  = cellfun(@(x) BetBuilder.stripbet(x), ref_fps, 'UniformOutput', false);
%             ref_fps = [ref_fps tmp];            
%             ref_fps = fileprefixes(ref_fps);
            flirtf = FlirtBuilder;
            flirtf.flirtOntoRefs(fcells, ref_fps);
        end % flirtPETOntoRefs
                
        function this   = quantifyPet(this, msk_fp, ref_fp)
            
            %% QUANTIFYPET 
            %  Usage:  obj = PETMake.quantifyPet(msk_fp [, ref_fp])
            %                                    ^ mask fileprefix in current dir
            %                                            ^ reference fileprefix in current dir
            import mlfsl.* mlfourd.*;
            if (~exist('ref_fp','var')); ref_fp = ''; end
            [~,msk_fp,~] = filepartsx( msk_fp, mlfourd.INIfTI.FILETYPE_EXT);
            [~,ref_fp,~] = filepartsx( ref_fp, mlfourd.INIfTI.FILETYPE_EXT);
               msk_fp    = fileprefix(msk_fp);
               ref_fp    = fileprefix(ref_fp);
            if (~isempty(ref_fp))
                suff     = ['_on_' ref_fp mlfourd.INIfTI.FILETYPE_EXT];
            else
                suff     = mlfourd.INIfTI.FILETYPE_EXT;
            end            
            disp(['PETMake.quantifyPet is working in folder ' pwd]);
            
            % BUSINESS with PETConverter 
            
            reg    = Np797Registry.instance(pwd);
            msknii = NIfTI.load(fullfile(this.fslPath, msk_fp));
            msknii = double(msknii);
            petc   = PETconverter(reg.pid, msknii, reg.petBlur, reg.blockSize);
            if (this.makecbf)
                try
                    petc.honii = petc.make_honii(fullfile(this.fslPath, [this.petFileprefixes(this.PET_INDEX).ho suff]));
                           nii = petc.make_cbfnii;
                           nii.saveas(['cbf_' nii.fileprefix], 64);
                catch ME
                    handwarning(ME, 'make_cbfnii');
                end
            end
            if (this.makecbv)
                try
                    petc.ocnii = petc.make_ocnii(fullfile(this.fslPath, [this.petFileprefixes(this.PET_INDEX).oc suff]));
                           nii = petc.make_cbvnii;
                           nii.saveas(['cbv_' nii.fileprefix], 64);
                catch ME
                    handwarning(ME, 'make_cbvnii');
                end
            end
            if (this.makeoef)
                try
                    petc.oonii = petc.make_oonii(fullfile(this.fslPath, [this.petFileprefixes(this.PET_INDEX).oo suff]));
                           nii = petc.make_oefnii;
                           nii.saveas(['oef_' nii.fileprefix], 64);
                catch ME
                    handwarning(ME, 'make_oefnii');
                end
            end
            if (this.makemtt)
                try
                         nii = petc.make_mttnii;
                         nii.saveas(['mtt_' nii.fileprefix], 64);
                catch ME
                    handwarning(ME, 'make_mttnii');
                end
            end
            if (this.makecmro2)
                try
                         nii = petc.make_cmro2nii;
                         nii.saveas(['cmro2_' nii.fileprefix], 64);
                catch ME
                    handwarning(ME, 'make_cmro2nii');
                end
            end

        end % quantifyPet
        
 		function [s,msg,id] = renamePetSums(this, patt, pname, sumName)
            
            %% RENAMEPETSUMS 
            %  [s,msg,id] = obj.renamePetSums(pattern, param_name, sum_name)
            %               obj.renamePetSums('ho*',   'ndim',     'hosum')
            import mlfsl.* mlpet.*;
            s = -1; msg = ''; id = '';
            
            files = dir2cell(patt); 
            mark  = 0;
            for f = 1:length(files) %#ok<FORFLG,PFUNK>
                try
                    param = FslBuilder.fslhdParameter(files{f}, pname);
                    if (~isempty(param) && ...
                         str2double(param) == 3)
                        mark = mark + 1;
                        if (mark > 1)
                            [s,msg,id] = movefile(files{f}, [sumName num2str(mark) this.rotSuff PETMake.FILETYPE_EXT]); %#ok<PFBNS,PFTUS>
                        else
                            [s,msg,id] = movefile(files{f}, [sumName               this.rotSuff PETMake.FILETYPE_EXT]);
                        end
                    end
                catch ME
                    warning(ME.getReport);
                end
            end
        end % renamePetSums
    end
end

