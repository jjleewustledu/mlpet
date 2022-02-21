classdef SubjectResolverTools < handle & matlab.mixin.Copyable
	%% SUBJECTRESOLVERTOOLS is a delegate for mlpet.SubjectResolverTo{FDG, HO, ...}.

	%  $Revision$
 	%  was created 14-Jan-2020 13:25:37 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    properties (Constant)        
        SURFER_OBJS = {'brain' 'wmparc'}
        DO_FINALIZE = false
    end
    
    properties (Dependent)
        referenceTracer
        ReferenceTracer
        resamplingRestrictedPath
        subjectPath
        tracers
    end
    
	methods
        
        %% GET
        
        function g = get.referenceTracer(this)
            g = this.resolver_.client.sessionData.referenceTracer;
            assert(ischar(g))
            g = lower(g);
        end
        function g = get.ReferenceTracer(this)
            g = this.resolver_.client.sessionData.referenceTracer;
            assert(ischar(g))
            g = upper(g);
        end
        function g = get.resamplingRestrictedPath(this)
            g = fullfile(this.subjectPath, 'resampling_restricted', '');
        end
        function g = get.subjectPath(this)
            g = this.resolver_.client.sessionData.subjectData.subjectPath;
        end
        function g = get.tracers(this)
            g = this.resolver_.client.sessionData.tracers;
            assert(iscell(g) && ischar(g{1}))
        end
        
        %%
        
        function        constructResamplingRestricted(this, varargin)
            ip = inputParser;
            addParameter(ip, 'compositionTarget', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.lns_resampling_restricted();
            this.compose_t4s('compositionTarget', ipr.compositionTarget);
            this.t4img_4dfp_on_T1001(this.resamplingRestrictedPath);
            this.copySurfer(this.subjectPath, this.resamplingRestrictedPath);
            copyfile('*.json', this.resamplingRestrictedPath, 'f')
            if this.DO_FINALIZE
                this.finalize()
            end
        end
        function fps  = linkAndSimplifyScans(this, varargin)
            %% Creates links to tracer images distributed on the filesystem so that resolve operations may be done in the pwd.
            %  e.g.:  HO_DT(yyyymmddHHMMSS).000000-Converted-AC/ho_avgt.4dfp.hdr -> hodt(yyyymmddHHMMSS)_avgt.4dfp.hdr
            %  @param required tracer is char.
            %  @param optional suffix is char, e.g., _avgt.
            %  @return prefixes = cell(1, N(available images)) as unique fileprefixes in the pwd.
            
            ip = inputParser;
            addRequired(ip, 'tracer', @ischar);
            addOptional(ip, 'suffix', '', @ischar);
            parse(ip, varargin{:});         
            
            fps = {};
            dt = mlsystem.DirTool( ...
                fullfile(this.subjectPath, 'ses-E*'));
            for ses = dt.fqdns
                try
                    toglob = sprintf('%s.4dfp.hdr', this.resolver_.finalTracerGlob(ip.Results.tracer, 'path', ses{1}));
                    toglob = basename(toglob);
                    files = this.resolver_.collectionRB.lns_with_datetime(fullfile(ses{1}, toglob));
                    fps = [fps this.resolver_.collectionRB.uniqueFileprefixes(files)]; %#ok<AGROW>
                catch ME
                    handwarning(ME)
                end
            end
            fps = unique(fps);
        end
        function        lns_resampling_restricted(this)
            if isfolder(this.resamplingRestrictedPath)
                mlbash(sprintf('rm -rf %s', this.resamplingRestrictedPath))
            end
            ensuredir(this.resamplingRestrictedPath)
            exts = {'.4dfp.hdr' '.4dfp.ifh' '.4dfp.img' '.4dfp.img.rec'};
            
            pwd0 = pushd(this.subjectPath);
            
            for e = exts
                try
                    mlbash(sprintf('ln -s %s/T1001%s %s/T1001%s', ...
                        this.subjectPath, e{1}, this.dataPath, e{1}));
                catch ME
                    handwarning(ME)
                end
            end            
            for ses = asrow(glob('ses-E*'))
                for hdr = asrow(glob(fullfile(ses{1}, '*dt*.4dfp.hdr')))
                    re = regexp(mybasename(hdr{1}), '^(?<prefix>(fdg|ho|oo|oc)dt(\d+|\d+_avgt))$', 'names');
                    if ~isempty(re)
                        for e = exts
                            try
                                mlbash(sprintf('ln -s %s%s %s%s', ...
                                    fullfile(this.subjectPath, ses{1}, re.prefix), e{1}, ...
                                    fullfile(this.resamplingRestrictedPath, re.prefix), e{1}));
                            catch ME
                                handwarning(ME)
                            end
                        end
                    end
                end                
            end
            
            popd(pwd0)
        end
		  
 		function this = SubjectResolverTools(varargin)
            ip = inputParser;
            addParameter(ip, 'resolver', [], @(x) isa(x, 'mlpet.ResolverToTracerStrategy'))
            parse(ip, varargin{:})
            this.resolver_ = ip.Results.resolver;
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        resolver_
    end
    
    methods (Static, Access = protected)
        function tdt = fdgdt(ses1)
            %% @returns first fdgdt12345678 object found in ses1
            sesfold = strrep(ses1, '_', '-');
            for g = glob(fullfile(sesfold, 'fdgdt*.4dfp.hdr'))
                tdt = mybasename(g{1});
                if ~isempty(regexp(tdt, '^fdgdt\d+$', 'once'))
                    return
                end
            end
            error('mlpet:RuntimeError', 'fdgdt.sesfold is missing fdg')
        end
        function tdt = hodt(ses1)
            %% @returns first hodt12345678 object found in ses1
            sesfold = strrep(ses1, '_', '-');
            for g = glob(fullfile(sesfold, 'hodt*.4dfp.hdr'))
                tdt = mybasename(g{1});
                if ~isempty(regexp(tdt, '^hodt\d+$', 'once'))
                    return
                end
            end
            error('mlpet:RuntimeError', 'hodt.sesfold is missing ho')
        end
        function tf  = issingleton(tra_list)
            tf = length(tra_list) == 1;
        end
        function tdt = ocdt(ses1)
            %% @returns first ocdt12345678 object found in ses1
            sesfold = strrep(ses1, '_', '-');
            for g = glob(fullfile(sesfold, 'ocdt*.4dfp.hdr'))
                tdt = mybasename(g{1});
                if ~isempty(regexp(tdt, '^ocdt\d+$', 'once'))
                    return
                end
            end
            error('mlpet:RuntimeError', 'ocdt.sesfold is missing oc')
        end
        function t4  = ses2sub_t4(t4_)
            t4 = sprintf('%s_ses2sub_t4', t4_(1:end-3));
        end
        function tdt = singletondt(tra, ses1)
            %% @returns first tracerdt12345678 object found in ses1
            
            sesfold = strrep(ses1, '_', '-');
            for g = glob(fullfile(sesfold, [tra 'dt*.4dfp.hdr']))
                tdt = mybasename(g{1});
                if ~isempty(regexp(tdt, sprintf('^%sdt\\d+$', tra), 'once'))
                    return
                end
            end
            error('mfiles:RuntimeError', 'compose_t4s.singletondt.sesfold is missing %s', tra)
        end
        function       t4img_4dfp_on_T1001(varargin)
            
            ip = inputParser;
            addRequired(ip, 'targPth', @isfolder)
            addParameter(ip, 'viewer', '', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            fold = basename(pwd);
            assert(strcmp(fold(1:5), 'sub-S'))
            pwd0 = pushd(ipr.targPth);
            for t4s = asrow(glob('*dt*_to_T1001_t4'))
                src = strsplit(t4s{1}, '_');
                mlbash(sprintf('t4img_4dfp %s %s_avgt %s_avgt_on_T1001 -OT1001', t4s{1}, src{1}, src{1}));
            end
            if ~isempty(ipr.viewer)
                try
                    mlbash(sprintf('%s *dt*_on_T1001.4dfp.img T1001.4dfp.img', ipr.viewer));
                catch ME
                    dispexcept(ME)
                end
            end
            popd(pwd0)
        end
        function tdt = tracerdt(t4, varargin)
            %% @returns tracerdt12345678 from some tracerdt12345678_to<...>_t4
            
            import mlpet.SubjectResolverTools.*
            
            ip = inputParser;
            addOptional(ip, 'sesfold', '', @ischar)
            parse(ip, varargin{:})
            
            t4fp = tracerpref(t4);
            if regexp(t4fp, '^[a-z]+dt\d+$', 'once')
                tdt = t4fp;
                return
            end
            
            % find associated datetime
            try
                g = glob([t4fp 'dt*.4dfp.*']);
                tdt = strsplit(g{1}, '.');
                tdt = tdt{1};
            catch ME
                handwarning(ME)
                tdt = singletondt(t4fp, ip.Results.sesfold);
            end
        end
        function tdt = tracerpref(t4)
            %% @returns tracerdt12345678 from some tracerdt12345678_to<...>_t4
            tdt = strsplit(t4, '_');
            tdt = tdt{1};
        end
        function t4  = tracerToT1001(varargin)
            %% @param required tracer 
            %  @param optional t1001
            %  @param blur := 7.5 by default
            %  @param atlas := TRIO_Y_NDC by default
            
            ip = inputParser;
            addRequired(ip, 'tracer', @(x) isfile([x '.4dfp.hdr']))
            addOptional(ip, 't1001', 'T1001', @(x) isfile([x '.4dfp.hdr']))
            addParameter(ip, 'atlas', 'TRIO_Y_NDC', @ischar)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            fv = mlfourdfp.FourdfpVisitor;
            if ~isfile([ipr.t1001 '_to_' ipr.atlas '_t4'])
                fv.mpr2atl1_4dfp(ipr.t1001, 'options', sprintf('-T%s/%s -S711-2B', getenv('REFDIR'), ipr.atlas));
            end
            fqfp = fv.epi2t1w_4dfp(ipr.tracer, ipr.t1001);
            [pth,fp] = fileparts(fqfp);
            t4 = fullfile(pth, [strrep(fp, '_on_', '_to_') '_t4']);
        end
    end
    
    methods (Access = protected)
        function sub_struct = compose_t4s(this, varargin)
            import mlpet.SubjectResolverTools.*
            
            ip = inputParser;
            addParameter(ip, 'compositionTarget', '', @ischar)
            parse(ip, varargin{:});
                        
            switch ip.Results.compositionTarget
                case 'subjectT1001'
                    this.compose_t4s_to_subjectT1001();
                    sub_struct = [];
                otherwise
                    sub_struct = this.compose_t4s_to_subjectTracers();
            end
        end
        function              compose_t4s_to_subjectT1001(this)
            %% COMPOSE_T4S simply globs('ses-E*') without looking in study json files.
            
            import mlpet.SubjectResolverTools.*
            dirpref = strsplit(mybasename(pwd), '-');
            assert(strcmp(dirpref{1}, 'sub'))
            fv = mlfourdfp.FourdfpVisitor;
            
            % compose t4s:  tracer -> session -> subject T1001
            for ses = globT('ses-E*')
                seslbl = strsplit(ses{1}, '-');
                seslbl = seslbl{2};
                try
                    lns_4dfp(fullfile(ses{1}, 'T1001'), ['T1001_' seslbl]);
                    mlbash(sprintf('mpr2atl1_4dfp T1001_%s -TT1001', seslbl));
                    mlbash(sprintf('t4img_4dfp T1001_%s_to_T1001_t4 T1001_%s T1001_%s_on_T1001 -OT1001', seslbl, seslbl, seslbl));
                    %mlbash(sprintf('fsleyes T1001.4dfp.img T1001_%s_on_T1001.4dfp.img', seslbl))                       
                    
                    load(fullfile(ses{1}, 't4_obj.mat'), 't4_obj')
                    for tra = this.tracers
                        for itra = 1:length(t4_obj.(tra{1}))
                            tdt = tracerdt(t4_obj.(tra{1}){itra}, ses{1});
                            t4_tmp = [tempname '_to_temp_t4'];
                            fv.t4_mul(fullfile(ses{1}, t4_obj.(tra{1}){itra}), ...
                                      fullfile(ses{1}, [this.referenceTracer '_avgr1_to_T1001r1_t4']), ...
                                      t4_tmp);
                            fv.t4_mul(t4_tmp, ...
                                      sprintf('T1001_%s_to_T1001_t4', seslbl), ...
                                      fullfile(this.resamplingRestrictedPath, [tdt '_to_T1001_t4']));
                        end
                    end
                catch ME
                    handwarning(ME)
                end
            end            
            ensuredir(this.resamplingRestrictedPath);
            copyfile('*.json', this.resamplingRestrictedPath, 'f');
        end
        function sub_struct = compose_t4s_to_subjectTracers(this)
            import mlpet.SubjectResolverTools.*
            
            pwd0 = pushd(this.subjectPath);            
            assert(isfile('t4_obj.mat'))
            sub_struct = this.compose_t4s_to_subjectTracers_tree();
            popd(pwd0)
        end
        function sub_struct = compose_t4s_to_subjectTracers_tree(this)
            %% COMPOSE_T4S simply globs('ses-E*') without looking in study json files.
            %  @param tracers := {'fdg' 'ho' 'oo' 'oc'}, default.  1st tracer will be reference for t4_resolve.
            %  @return sub_struct := {
            %   "tra_struct" = {
            %     "fdg" = { "fdgdt<datetime>_to_op_fdg_avgr1_t4" },
            %     "ho"  = { "hodt<datetime>_to_op_fdg_avgr_t4", ... },
            %     "oc"  = { "ocdt<datetime>_to_op_fdg_avgr1_t4", ... }, ...
            %   },
            %   "ses_struct" = {
            %     "ses-E00001" = {
            %       "tra_struct" = {
            %         "fdg" = { "fdg_avgr1_to_op_fdg_avgr1_t4" },
            %         "ho"  = { "hodt<datetime>_to_op_fdg_avgr_t4", ... },
            %         "oc"  = { "ocdt<datetime>_to_op_fdg_avgr1_t4", ... }, ...
            %   },
            %     "ses-E00002" = {
            %       "tra_struct" = {
            %         "fdg" = { "fdgdt<datetime>_to_op_fdg_avgr1_t4" },
            %         "ho"  = { "hodt<datetime>_to_op_fdg_avgr_t4", ... },
            %         "oc"  = { "oc_avgr1_to_op_oc_avgr1_t4" }, ...
            %     }
            %   }
            % }
            %%
            
            import mlpet.SubjectResolverTools.*
            
            load('t4_obj.mat', 't4_obj')
            sub_struct = struct('tra_struct', t4_obj);
            for ses = asrow(glob('ses-E*'))
                try
                    load(fullfile(ses{1}, 't4_obj.mat'), 't4_obj');
                    ses_field = strrep(strrep(ses{1}, '/', ''), '-', '_');
                    sub_struct.ses_struct.(ses_field).tra_struct = t4_obj;
                catch ME
                    handwarning(ME)
                end
            end
            
            % compose t4s:  tracer -> session -> subject -> T1001
            
            fv = mlfourdfp.FourdfpVisitor;
            %if ~isempty(glob('resampling_restricted/*'))
            %    system('rm -f resampling_restricted/*');
            %end
            ensuredir(this.resamplingRestrictedPath);
            copyfile('*.json', this.resamplingRestrictedPath, 'f');
            to_T1001_t4 = tracerToT1001([this.tracers{1} '_avg']); % e.g., 'fdg_avg_to_T1001_t4'
            for tra = this.tracers
                for itra = 1:length(sub_struct.tra_struct.(tra{1}))                    
                    sub_t4 = sub_struct.tra_struct.(tra{1}){itra};
                    try
                        [sesfold,ses_t4] = this.find_sesfold_and_t4ses(sub_t4, sub_struct, tra{1});
                    catch ME
                        disp(sub_t4)
                        disp(sub_struct.ses_struct)
                        disp(tra{1})
                        handexcept(ME, 'mlpet:RuntimeWarning', 'SubjectResolveBuilder.compose_t4s()')
                    end
                    deleteExisting(ses2sub_t4(sub_t4)) % paranoia
                    fv.t4_mul(fullfile(sesfold, ses_t4), sub_t4, ses2sub_t4(sub_t4));
                    fv.t4_mul(ses2sub_t4(sub_t4), to_T1001_t4, ...
                              fullfile(this.resamplingRestrictedPath, [tracerdt(sub_t4, sesfold) '_to_T1001_t4']));
                end
            end
        end
        function sub_struct = compose_t4s_to_subjectTracers_trunk(this)
            %% COMPOSE_T4S simply globs('ses-E*') without looking in study json files.
            %  @param tracers := {'fdg' 'ho' 'oo' 'oc'}, default.  1st tracer will be reference for t4_resolve.
            %  @return sub_struct := {
            %   "tra_struct" = {
            %     "fdg" = { "fdgdt<datetime>_to_op_fdg_avgr1_t4" },
            %     "ho"  = { "hodt<datetime>_to_op_fdg_avgr_t4", ... },
            %     "oc"  = { "ocdt<datetime>_to_op_fdg_avgr1_t4", ... }, ...
            %   },
            %   "ses_struct" = {
            %     "ses-E00001" = {
            %       "tra_struct" = {
            %         "fdg" = { "fdg_avgr1_to_op_fdg_avgr1_t4" },
            %         "ho"  = { "hodt<datetime>_to_op_fdg_avgr_t4", ... },
            %         "oc"  = { "ocdt<datetime>_to_op_fdg_avgr1_t4", ... }, ...
            %   },
            %     "ses-E00002" = {
            %       "tra_struct" = {
            %         "fdg" = { "fdgdt<datetime>_to_op_fdg_avgr1_t4" },
            %         "ho"  = { "hodt<datetime>_to_op_fdg_avgr_t4", ... },
            %         "oc"  = { "oc_avgr1_to_op_oc_avgr1_t4" }, ...
            %     }
            %   }
            % }
            %%
            
            import mlpet.SubjectResolverTools.*
              
            ses = globT('ses-E*');
            assert(1 == length(ses))
            load(fullfile(ses{1}, 't4_obj.mat'), 't4_obj');
            sub_struct = struct('tra_struct', t4_obj);
            ses_field = strrep(strrep(ses{1}, '/', ''), '-', '_');
            sub_struct.ses_struct.(ses_field).tra_struct = t4_obj;
            
            % compose t4s:  tracer -> session -> subject -> T1001
            
            fv = mlfourdfp.FourdfpVisitor;
            %if ~isempty(glob('resampling_restricted/*'))
            %    system('rm -f resampling_restricted/*');
            %end
            ensuredir(this.resamplingRestrictedPath);
            copyfile('*.json', this.resamplingRestrictedPath, 'f');
            
            pwd0 = pushd(ses{1});
            to_T1001_t4 = tracerToT1001([this.tracers{1} '_avg']); % e.g., 'fdg_avg_to_T1001_t4'
            
            error('mlpet:NotImplementedError', 'SubjectResolverTools.compose_t4s_to_subjectTracers_trunk')
            
            for tra = this.tracers
                for itra = 1:length(sub_struct.tra_struct.(tra{1}))                    
                    sub_t4 = sub_struct.tra_struct.(tra{1}){itra};
                    try
                        [sesfold,ses_t4] = this.find_sesfold_and_t4ses(sub_t4, sub_struct, tra{1});
                    catch ME
                        disp(sub_t4)
                        disp(sub_struct.ses_struct)
                        disp(tra{1})
                        handexcept(ME, 'mlpet:RuntimeWarning', 'SubjectResolveBuilder.compose_t4s()')
                    end
                    deleteExisting(ses2sub_t4(sub_t4)) % paranoia
                    fv.t4_mul(fullfile(sesfold, ses_t4), sub_t4, ses2sub_t4(sub_t4));
                    fv.t4_mul(ses2sub_t4(sub_t4), to_T1001_t4, ...
                              fullfile(this.resamplingRestrictedPath, [tracerdt(sub_t4, sesfold) '_to_T1001_t4']));
                end
            end
            popd(pwd0)
        end
        function              copySurfer(this, sourcePath, destPath)
            globbed = asrow(glob(fullfile(sourcePath, 'ses-E*')));
            for ig = length(globbed):-1:1
                if isfile(fullfile(globbed{ig}, 'T1001.4dfp.hdr'))
                    for s = this.SURFER_OBJS
                        fqfp = fullfile(globbed{ig}, s{1});
                        if ~isfile([fqfp '.nii']) || ~isfile([fqfp '.4dfp.hdr'])
                            % stage SURFER_OBJS in g{1}
                            pwd_ = pushd(globbed{ig});
                            mlbash(sprintf('mri_convert mri/%s.mgz %s.nii', basename(fqfp), basename(fqfp)));
                            mlbash(sprintf('nifti_4dfp -4 -N %s.nii %s.4dfp.hdr', basename(fqfp), basename(fqfp)));
                            popd(pwd_);
                        end
                        for x = {'.nii' '.4dfp.hdr' '.4dfp.img' '.4dfp.ifh' '.4dfp.img.rec'}
                            copyfile([fqfp x{1}], destPath, 'f');
                        end
                    end
                    
                    return
                    
                end
            end
            error('mlpet:RuntimeError', 'StudyResolveBuilder.copySurfer could not create files %s/{%s}', ...
                sourcePath, cell2str(this.SURFER_OBJS))
        end
        function that       = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
            % N.B.:  that.object_ = copy(this.object_);
        end
        function              finalize(this)
            pwd0 = pushd(this.subjectPath);
            
            for t = this.tracers
                deleteExisting(sprintf('%s*.4dfp.*', t{1}))
                for ses = asrow(glob('ses-E*'))
                    deleteExisting(fullfile(ses{1}, [t{1} '*_op_*.4dfp.*']))
                    deleteExisting(fullfile(ses{1}, [t{1} '_avg*.4dfp.*']))
                end
            end
            
            deleteExisting('*dt*_avgtr1.4dfp.*')
            deleteExisting('*dt*_avgtr1_b*.4dfp.*')            
            deleteExisting('T1001_b*.4dfp.*')
            deleteExisting('*_mskt.4dfp.*')
            deleteExisting('*dt*_avgtr1_op_*dt*_avgtr1.4dfp.*')
            deleteExisting('T1001r1_op_*dt*_avgtr1.4dfp.*')
            
            popd(pwd0);
        end                 
        function [sesfold,ses_t4] = find_sesfold_and_t4ses(this, varargin)
            switch class(this.resolver_)
                case 'mlpet.SubjectResolverToFDG'
                    [sesfold,ses_t4] = this.find_sesfold_and_t4ses_FDG(varargin{:});
                case 'mlpet.SubjectResolverToHO'
                    [sesfold,ses_t4] = this.find_sesfold_and_t4ses_HO(varargin{:});
                otherwise
                    error('mlpet:ValueError', ...
                        'SubjectResolverTools.find_sesfold_and_t4ses() does not support %s', class(this.resolver_))
            end
            
        end
        function [sesfold,ses_t4] = find_sesfold_and_t4ses_FDG(~, sub_t4, sub_struct, tra)
            %% @return sesfolder and t4 filename
            
            import mlpet.SubjectResolverTools.*
            
            for ses = asrow(fields(sub_struct.ses_struct))
                assert(~isempty(sub_struct.ses_struct.(ses{1}).tra_struct.(tra)), ...
                    'mlpet:RuntimeError', 'find_sesfold_and_t4ses_FDG() received empty tracer list')
                for tdt = asrow(sub_struct.ses_struct.(ses{1}).tra_struct.(tra))
                    sesfold = strrep(ses{1}, '_', '-');
                    if strcmpi(tra, 'fdg') && lstrfind(tracerpref(sub_t4), fdgdt(ses{1})) % fdg is privileged as reference
                        ses_t4 = sub_struct.ses_struct.(ses{1}).tra_struct.fdg{1};
                        return
                    end
                    if issingleton(sub_struct.ses_struct.(ses{1}).tra_struct.(tra)) && ...
                            strcmpi(tra, 'oc') && lstrfind(tracerpref(sub_t4), ocdt(ses{1})) % oc has t4_resolve to fdgdt<datetime>_frames1to8_avgtr1
                        % sub_struct.ses_struct.(ses{1}).tra_struct.oc{1} ~ oc_avgr1_to_op_oc_avgr1_t4 ~ identity
                        t4s = glob(fullfile(sesfold, 'oc_avg_sqrtr1_to_op_fdgdt*_frames1to*_avgtr1_t4'));
                        assert(1 == length(t4s))
                        ses_t4  = mybasename(t4s);
                        return
                    end
                    if issingleton(sub_struct.ses_struct.(ses{1}).tra_struct.(tra)) && ...
                            lstrfind(tracerpref(sub_t4), singletondt(tra, ses{1})) % singleton t4s for ho, oo
                        % sub_struct.ses_struct.(ses{1}).tra_struct.(tra) ~ tra_avgr1_to_op_tra_avgr1_t4 ~ identity
                        t4s = glob(fullfile(sesfold, [tra '*_to_op_fdg*_t4']));
                        assert(1 == length(t4s))
                        ses_t4  = mybasename(t4s);
                        return
                    end
                    if strcmp(tracerpref(sub_t4), tracerpref(tdt{1})) % found matching
                        ses_t4 = tdt{1};
                        return
                    end
                end
            end
        end
        function [sesfold,ses_t4] = find_sesfold_and_t4ses_HO(~, sub_t4, sub_struct, tra)
            %% @return sesfolder and t4 filename
            
            import mlpet.SubjectResolverTools.*
            
            for ses = asrow(fields(sub_struct.ses_struct))
                assert(~isempty(sub_struct.ses_struct.(ses{1}).tra_struct.(tra)), ...
                    'mlpet:RuntimeError', 'find_sesfold_and_t4ses_HO() received empty tracer list')
                for tdt = asrow(sub_struct.ses_struct.(ses{1}).tra_struct.(tra))
                    sesfold = strrep(ses{1}, '_', '-');
                    if strcmpi(tra, 'ho') && lstrfind(tracerpref(sub_t4), hodt(ses{1})) % ho{1} is privileged as reference
                        ses_t4 = sub_struct.ses_struct.(ses{1}).tra_struct.ho{1};
                        return
                    end
                    if issingleton(sub_struct.ses_struct.(ses{1}).tra_struct.(tra)) && ...
                            lstrfind(tracerpref(sub_t4), singletondt(tra, ses{1})) % singleton t4s for oo, oc
                        % sub_struct.ses_struct.(ses{1}).tra_struct.(tra) ~ tra_avgr1_to_op_tra_avgr1_t4 ~ identity
                        t4s = glob(fullfile(sesfold, [tra '*_to_op_ho*_t4']));
                        assert(1 == length(t4s))
                        ses_t4  = mybasename(t4s);
                        return
                    end
                    if strcmp(tracerpref(sub_t4), tracerpref(tdt{1})) % found matching
                        ses_t4 = tdt{1};
                        return
                    end
                end
            end
        end
    end
    
    
    %% HIDDEN, DEPRECATED
    
    methods (Hidden)
        function [sesfold,t4] = find_sesfold_and_t4ses_(~, sub_t4, sub_struct, tra)
            %% @return sesfolder and t4 filename
            
            import mlpet.SubjectResolverTools.*
            
            for ses = asrow(fields(sub_struct.ses_struct))
                assert(~isempty(sub_struct.ses_struct.(ses{1}).tra_struct.(tra)), ...
                    'mfiles:RuntimeError', 'compose_t4s.find_sesfold_and_t4ses_() received empty tracer list')
                for tdt = asrow(sub_struct.ses_struct.(ses{1}).tra_struct.(tra))
                    if strcmpi(tra, 'oc') && lstrfind(tracerpref(sub_t4), ocdt(ses{1})) % oc has t4_resolve to fdgdt<datetime>_frames1to8_avgtr1
                        sesfold = strrep(ses{1}, '_', '-');
                        % sub_struct.ses_struct.(ses{1}).tra_struct.oc{1} ~ oc_avgr1_to_op_oc_avgr1_t4 ~ identity
                        t4s = glob(fullfile(sesfold, 'oc_avg_sqrtr1_to_op_fdgdt*_frames1to*_avgtr1_t4'));
                        assert(1 == length(t4s))
                        t4  = mybasename(t4s);
                        return
                    end
                    if strcmp(tracerpref(sub_t4), tracerpref(tdt{1})) % found matching
                        sesfold = strrep(ses{1}, '_', '-');
                        t4 = tdt{1};
                        return
                    end
                end
            end
        end
        function [sesfold,t4] = find_sesfold_and_t4ses__(~, sub_t4, sub_struct, tra)
            %% verified to work on subjects/sub-S63372, but the sub-S63372 folder becomes corrupted unexpectedly
            
            import mlpet.SubjectResolverTools.*
            
            for ses = asrow(fields(sub_struct.ses_struct))
                for tdt = asrow(sub_struct.ses_struct.(ses{1}).tra_struct.(tra)) % special for fdg
                    if strcmpi(tra, 'fdg') && lstrfind(tracerpref(sub_t4), fdgdt(ses{1}))
                        sesfold = strrep(ses{1}, '_', '-');
                        t4 = sub_struct.ses_struct.(ses{1}).tra_struct.fdg{1};
                        return
                    end
                    if strcmp(tracerpref(sub_t4), tracerpref(tdt{1}))
                        sesfold = strrep(ses{1}, '_', '-');
                        t4 = tdt{1};
                        return
                    end
                end
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

