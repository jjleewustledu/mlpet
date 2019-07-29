classdef SubjectResolveBuilder < mlpet.StudyResolveBuilder
	%% SUBJECTRESOLVEBUILDER  

	%  $Revision$
 	%  was created 07-May-2019 01:16:29 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Constant)
        IS_FINISHED = false
    end
    
    methods (Static)
        function lns_resampling_restricted()
            ensuredir('resampling_restricted')
            pwdsub = pwd;
            fv = mlfourdfp.FourdfpVisitor();
            exts = {'.4dfp.hdr' '.4dfp.ifh' '.4dfp.img' '.4dfp.img.rec'};
            
            %cRB = mlfourdfp.CompositeT4ResolveBuilder();
            
            for e = exts
                try
                    mlbash(sprintf('ln -s %s/T1001%s %s/resampling_restricted/T1001%s', ...
                        pwdsub, e{1}, pwdsub, e{1}));
                catch ME
                    handwarning(ME)
                end
            end            
%% BUG! 
%             for t4 = asrow(glob('*dt*_to_op_fdg_avgr1_t4'))
%                 prefix = strsplit(t4{1}, '_');
%                 prefix = prefix{1};
%                 fv.t4_mul(t4{1}, 'fdg_avgr1_to_T1001r1_t4', ...
%                     fullfile('resampling_restricted', [prefix '_to_T1001_t4']));
%             end
%%            
            for ses = asrow(glob('ses-E*'))
                for hdr = asrow(glob(fullfile(ses{1}, '*dt*.4dfp.hdr')))
                    re = regexp(mybasename(hdr{1}), '^(?<prefix>(fdg|ho|oo|oc)dt(\d+|\d+_avgt))$', 'names');
                    if ~isempty(re)
                        for e = exts
                            try
                                mlbash(sprintf('ln -s %s%s %s%s', ...
                                    fullfile(pwdsub, ses{1}, re.prefix), e{1}, ...
                                    fullfile(pwdsub, 'resampling_restricted', re.prefix), e{1}));
                            catch ME
                                handwarning(ME)
                            end
                        end
                    end
                end
                
            end
        end        
        function sub_struct = compose_t4s(varargin)
            ip = inputParser;
            addParameter(ip, 'compositionTarget', '', @ischar)
            parse(ip, varargin{:});
            
            import mlpet.SubjectResolveBuilder.*
            
            switch ip.Results.compositionTarget
                case 'subjectT1001'
                    compose_t4s_to_subjectT1001();
                    sub_struct = [];
                otherwise
                    sub_struct = compose_t4s_to_subjectTracers();
            end
        end
        function              compose_t4s_to_subjectT1001()
            %% COMPOSE_T4S simply globs('ses-E*') without looking in study json files.
            
            import mlpet.SubjectResolveBuilder.*
            dirpref = strsplit(mybasename(pwd), '-');
            assert(strcmp(dirpref{1}, 'sub'))
            fv = mlfourdfp.FourdfpVisitor;
            
            % compose t4s:  tracer -> session -> subject T1001
            for ses = asrowdirs(glob('ses-E*'))
                seslbl = strsplit(ses{1}, '-');
                seslbl = seslbl{2};
                try
                    lns_4dfp(fullfile(ses{1}, 'T1001'), ['T1001_' seslbl]);
                    mlbash(sprintf('mpr2atl1_4dfp T1001_%s -TT1001', seslbl));
                    mlbash(sprintf('t4img_4dfp T1001_%s_to_T1001_t4 T1001_%s T1001_%s_on_T1001 -OT1001', seslbl, seslbl, seslbl));
                    %mlbash(sprintf('fsleyes T1001.4dfp.img T1001_%s_on_T1001.4dfp.img', seslbl))                       
                    
                    load(fullfile(ses{1}, 't4_obj.mat'), 't4_obj')
                    tracers = {'fdg' 'ho' 'oo' 'oc'};
                    for tra = tracers
                        for itra = 1:length(t4_obj.(tra{1}))
                            tdt = tracerdt(t4_obj.(tra{1}){itra}, ses{1});
                            t4_tmp = [tempname '_to_temp_t4'];
                            fv.t4_mul(fullfile(ses{1}, t4_obj.(tra{1}){itra}), ...
                                      fullfile(ses{1}, 'fdg_avgr1_to_T1001r1_t4'), ...
                                      t4_tmp);
                            fv.t4_mul(t4_tmp, ...
                                      sprintf('T1001_%s_to_T1001_t4', seslbl), ...
                                      fullfile('resampling_restricted', [tdt '_to_T1001_t4']));
                        end
                    end
                catch ME
                    handwarning(ME)
                end
            end            
            ensuredir('resampling_restricted');
            copyfile('*.json', 'resampling_restricted', 'f');
        end
        function sub_struct = compose_t4s_to_subjectTracers()
            %% COMPOSE_T4S simply globs('ses-E*') without looking in study json files.
            % build sub_struct := {
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
            
            import mlpet.SubjectResolveBuilder.*
            
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
            ensuredir('resampling_restricted');
            copyfile('*.json', 'resampling_restricted', 'f');
            tracers = {'fdg' 'ho' 'oo' 'oc'};
            for tra = tracers
                for itra = 1:length(sub_struct.tra_struct.(tra{1}))                    
                    t4sub = sub_struct.tra_struct.(tra{1}){itra};
                    try
                        [sesfold,t4ses] = find_sesfold_and_t4ses(t4sub, sub_struct, tra{1});
                    catch ME
                        disp(t4sub)
                        disp(sub_struct.ses_struct)
                        disp(tra{1})
                        handexcept(ME, 'mlpet:RuntimeWarning', 'SubjectResolveBuilder.compose_t4s()')
                    end
                    deleteExisting(t4_ses2sub(t4sub)) % paranoia
                    fv.t4_mul(fullfile(sesfold, t4ses), t4sub, t4_ses2sub(t4sub));
                    fv.t4_mul(t4_ses2sub(t4sub), 'fdg_avgr1_to_T1001r1_t4', ...
                              fullfile('resampling_restricted', [tracerdt(t4sub, sesfold) '_to_T1001_t4']));
                end
            end
        end        
        function [sesfold,t4] = find_sesfold_and_t4ses(sub_t4, sub_struct, tra)
            %% @return sesfolder and t4 filename
            
            import mlpet.SubjectResolveBuilder.*
            
            for ses = asrow(fields(sub_struct.ses_struct))
                assert(~isempty(sub_struct.ses_struct.(ses{1}).tra_struct.(tra)), ...
                    'mfiles:RuntimeError', 'compose_t4s.find_sesfold_and_t4ses() received empty tracer list')
                for tdt = asrow(sub_struct.ses_struct.(ses{1}).tra_struct.(tra))
                    sesfold = strrep(ses{1}, '_', '-');
                    if strcmpi(tra, 'fdg') && lstrfind(tracerpref(sub_t4), fdgdt(ses{1})) % fdg is privileged as reference
                        t4 = sub_struct.ses_struct.(ses{1}).tra_struct.fdg{1};
                        return
                    end
                    if issingleton(sub_struct.ses_struct.(ses{1}).tra_struct.(tra)) && ...
                            strcmpi(tra, 'oc') && lstrfind(tracerpref(sub_t4), ocdt(ses{1})) % oc has t4_resolve to fdgdt<datetime>_frames1to8_avgtr1
                        % sub_struct.ses_struct.(ses{1}).tra_struct.oc{1} ~ oc_avgr1_to_op_oc_avgr1_t4 ~ identity
                        t4s = glob(fullfile(sesfold, 'oc_avg_sqrtr1_to_op_fdgdt*_frames1to*_avgtr1_t4'));
                        assert(1 == length(t4s))
                        t4  = mybasename(t4s);
                        return
                    end
                    if issingleton(sub_struct.ses_struct.(ses{1}).tra_struct.(tra)) && ...
                            lstrfind(tracerpref(sub_t4), singletondt(tra, ses{1})) % singleton t4s for ho, oo
                        % sub_struct.ses_struct.(ses{1}).tra_struct.(tra) ~ tra_avgr1_to_op_tra_avgr1_t4 ~ identity
                        t4s = glob(fullfile(sesfold, [tra '*_to_op_fdg*_t4']));
                        assert(1 == length(t4s))
                        t4  = mybasename(t4s);
                        return
                    end
                    if strcmp(tracerpref(sub_t4), tracerpref(tdt{1})) % found matching
                        t4 = tdt{1};
                        return
                    end
                end
            end
        end
        function [sesfold,t4] = find_sesfold_and_t4ses_(sub_t4, sub_struct, tra)
            %% @return sesfolder and t4 filename
            
            import mlpet.SubjectResolveBuilder.*
            
            for ses = asrow(fields(sub_struct.ses_struct))
                assert(~isempty(sub_struct.ses_struct.(ses{1}).tra_struct.(tra)), ...
                    'mfiles:RuntimeError', 'compose_t4s.find_sesfold_and_t4ses() received empty tracer list')
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
        function [sesfold,t4] = find_sesfold_and_t4ses__(sub_t4, sub_struct, tra)
            %% verified to work on subjects/sub-S63372, but the sub-S63372 folder becomes corrupted unexpectedly
            
            import mlpet.SubjectResolveBuilder.*
            
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
        function tdt = fdgdt(ses1)
            %% @returns first fdgdt12345678 object found in ses1
            sesfold = strrep(ses1, '_', '-');
            for g = glob(fullfile(sesfold, 'fdgdt*.4dfp.hdr'))
                tdt = mybasename(g{1});
                if ~isempty(regexp(tdt, '^fdgdt\d+$', 'once'))
                    return
                end
            end
            error('mfiles:RuntimeError', 'compose_t4s.fdgdt.sesfold is missing fdg')
        end
        function tf = issingleton(tra_list)
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
            error('mfiles:RuntimeError', 'compose_t4s.fdgdt.sesfold is missing fdg')
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
        function tdt = tracerdt(t4, varargin)
            %% @returns tracerdt12345678 from some tracerdt12345678_to<...>_t4
            
            import mlpet.SubjectResolveBuilder.*
            
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
        function t4 = t4_ses2sub(t4_)
            t4 = sprintf('%s_ses2sub_t4', t4_(1:end-3));
        end
    end
    
	methods
        function this = alignCommonModal(this, varargin)
            %  @param required tracer is char.
            %  @return resolution of all scans with specified tracer in the session.
            
            ip = inputParser;
            addRequired(ip, 'tracer', @ischar);
            parse(ip, varargin{:});
            this.tracer = ip.Results.tracer;
            
            prefixes = this.stageSubjectScans(ip.Results.tracer, '_avgt');
            if ~isempty(prefixes)
                this = this.resolve(prefixes, varargin{2:end});
            end
        end  
        function this = configureSessions(this)
            %% explores the sessions within the subject-path,
            %  aligns images within each session, 
            %  and initializes this.collectionRB_ with the last discovered session data.
            
            import mlsystem.DirTool
            if isempty(this.subjectData_)
                return
            end    
            pwd0 = pushd(this.subjectData_.subjectPath);
            dt = DirTool('ses-*');
            for ses = dt.dns

                pwd1 = pushd(ses{1});
                if this.validTracerSession()
                    sd = mlraichle.SessionData( ...
                        'studyData', this.studyData_, ...
                        'projectData', mlraichle.ProjectData('sessionStr', ses{1}), ...
                        'subjectData', this.subjectData_, ...
                        'sessionFolder', ses{1}, ...
                        'tracer', this.studyData_.referenceTracer, ...
                        'ac', true); % referenceTracer   
                    %mlpet.SessionResolveBuilder.makeClean()
                    srb = mlpet.SessionResolveBuilder('sessionData', sd);
                    if ~srb.isfinished
                        srb.align
                    end
                    srb.t4_mul
                end
                popd(pwd1)
            end
            popd(pwd0)
        end
        function tf   = isfinished(this)
            tf = this.IS_FINISHED;
            return
            
            import mlsystem.DirTool
            pwd0 = pushd(fullfile(this.collectionRB_.sessionData.subjectPath, ''));
            dt_fdg = DirTool('fdg*_op_fdg_on_op_fdg_avgr1.4dfp.img');
            dt_ho  = DirTool('ho*_op_ho*_on_op_fdg_avgr1.4dfp.img');
            dt_oo  = DirTool('oo*_op_oo*_on_op_fdg_avgr1.4dfp.img');
            dt_oc  = DirTool(sprintf('oc*_op_oc*_on_op_fdg*_frames1to%i_avgtr1.4dfp.img', this.N_FRAMES_FOR_BOLUS));
            popd(pwd0)
            
            tf = ~isempty(dt_fdg.fqfns) && ...
                 ~isempty(dt_ho.fqfns) && ...
                 ~isempty(dt_oo.fqfns) && ...
                 ~isempty(dt_oc.fqfns);
        end
        function        lns_json_all(this)            
            import mlsystem.DirTool
            if isempty(this.subjectData_)
                return
            end
            
            pwd0 = pushd(this.subjectData_.subjectPath);            
            dt = DirTool('ses-*');
            for ses = dt.dns
                prjData = this.subjectData_.createProjectData('sessionStr', ses{1});
                prj_ses_pth = prjData.projectSessionPath(ses{1});
                jsons = glob(fullfile(prj_ses_pth, '*_DT*.000000-Converted-AC', 'output', 'PET', '*_DT*.json'));
                for j = asrow(jsons)
                    if ~isfile(basename(j{1}))
                        mlbash(sprintf('ln -s %s', j{1}))
                    end
                end
            end            
            popd(pwd0)
        end
        function prefixes = stageSubjectScans(this, varargin)
            %% Creates links to tracer images distributed on the filesystem so that resolve operations may be done in the pwd.
            %  e.g.:  HO_DT(yyyymmddHHMMSS).000000-Converted-AC/ho_avgt.4dfp.hdr -> hodt(yyyymmddHHMMSS)_avgt.4dfp.hdr
            %  @param required tracer is char.
            %  @param optional suffix is char, e.g., _avgt.
            %  @return prefixes = cell(1, N(available images)) as unique fileprefixes in the pwd.
            %  TODO:  stageSessionScans -> stageImages
            
            ip = inputParser;
            addRequired(ip, 'tracer', @ischar);
            addOptional(ip, 'suffix', '', @ischar);
            parse(ip, varargin{:});         
            
            prefixes = {};
            dt = mlsystem.DirTool('ses-E*');
            for ses = dt.dns
                try
                    glob = sprintf('%s.4dfp.hdr', this.finalTracerGlob(ip.Results.tracer));
                    glob = basename(glob);
                    files = this.collectionRB_.lns_with_datetime(fullfile(ses{1}, glob));
                    prefixes = [prefixes this.collectionRB_.uniqueFileprefixes(files)]; %#ok<AGROW>
                catch ME
                    handwarning(ME)
                end
            end
        end   
        function this     = t4imgDynamicImages(this, varargin)
            this.collectionRB_ = this.collectionRB_.t4imgDynamicImages( ...
                varargin{:}, 'staging_handle', @this.stageSubjectScans);
        end        
        
 		function this = SubjectResolveBuilder(varargin)
 			%% SUBJECTRESOLVEBUILDER
 			%  @param .
            
            this = this@mlpet.StudyResolveBuilder(varargin{:});
            this.collectionRB_ = mlfourdfp.CollectionResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'workpath', fullfile(this.sessionData_.subjectPath, ''));
 		end
 	end 
    
    %% PRIVATE
    
    methods (Access = private)
        function tf   = containsReferenceTracer(this, pth)
            tf = ~isempty(glob(fullfile(pth, [this.ReferenceTracer '_DT*.000000-Converted-AC'])));
        end        
        function this = stageT1001FromReferenceTracer(this)
            pwd0 = pushd(this.workpath);
            for ses = asrow(glob('ses-E*'))
                if this.containsReferenceTracer(ses{1})                    
                    mlfourdfp.FourdfpVisitor.lns_4dfp(fullfile(ses{1}, 'T1001'));
                    assert(isfile('T1001.4dfp.hdr'))
                    return
                end
            end
            popd(pwd0)
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

