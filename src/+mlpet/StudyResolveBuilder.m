classdef (Abstract) StudyResolveBuilder 
	%% STUDYRESOLVEBUILDER delegates properties and methods to mlfourdfp.CollectionResolveBuilder.
    %  It is the superclass to mlpet.SubjectResolveBuilder and mlpet.SessionResolveBuilder.

	%  $Revision$
 	%  was created 19-Jun-2019 00:19:40 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Constant)
        N_FRAMES_FOR_BOLUS = 8
        SURFER_OBJS = {'brain' 'wmparc'};
    end
    
    properties (Dependent)
        product
        referenceTracer
        ReferenceTracer
        subjectsJson
        tracer
        workpath
    end
    
    methods (Static)       
        function      copySurfer(targPath)
            fold = basename(pwd);
            assert(strcmp(fold(1:5), 'sub-S'))
            dt = mlsystem.DirTool('ses-E*');
            for s = mlpet.StudyResolveBuilder.SURFER_OBJS
                fqfp = fullfile(dt.fqdns{end}, s{1});
                if ~isfile([fqfp '.nii'])
                    pwd_ = pushd(fileparts(fqfp));
                    mlbash(sprintf('mri_convert mri/%s.mgz %s.nii', basename(fqfp), basename(fqfp)))
                    mlbash(sprintf('nifti_4dfp -4 %s.nii %s.4dfp.hdr', basename(fqfp), basename(fqfp)))
                    popd(pwd_)
                end
                for x = {'.nii' '.4dfp.hdr' '.4dfp.img' '.4dfp.ifh' '.4dfp.img.rec'}
                    copyfile([fqfp x{1}], targPath, 'f')
                end
            end
        end
        function dt = ensureDtFormat(dt)
            if isempty(dt)
                dt = '';
                return
            end
            if isdatetime(dt)
                dt = datestr(dt, 'yyyymmddHHMMSS');
            end
            assert(ischar(dt));
            if strcmp(dt, '*')
                return
            end
            if ~strncmp(dt, 'dt', 2)
                dt = ['dt' dt];
            end
            dt = strtok(dt, '.');
        end
        function      makeClean()
            ensuredir('Tmp')
            movefileExisting('ct.4dfp.*', 'Tmp')
            movefileExisting('T1001.4dfp.*', 'Tmp')
            deleteExisting('*.nii.gz')
            deleteExisting('*.nii')
            deleteExisting('*.4dfp.*')
            deleteExisting('*_t4')
            deleteExisting('*.log')
            deleteExisting('*.mat0')
            deleteExisting('*.sub')
            movefileExisting('Tmp/ct.4dfp.*')
            movefileExisting('Tmp/T1001.4dfp.*')
        end
        function      t4img_4dfp_on_T1001(varargin)
            
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
        function tf = validTracerSession(varargin)
            %% not ct, calibration or defective session
            %  @param  ipr is a struct with field 'tracerPattern' understandable to glob;
            %  default ipr.tracerPattern->'FDG_DT*.000000-Converted-AC'
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addOptional(ip, 'ipr', struct('tracerPattern', 'FDG_DT*.000000-Converted-AC'), @isstruct)
            parse(ip, varargin{:})
            ipr = ip.Results.ipr;
            assert(ischar(ipr.tracerPattern))
            tf = ~isempty(glob(ipr.tracerPattern));
        end
    end
    
    methods (Abstract)
        alignCommonModal(this)
    end

	methods
        
        %% GET/SET
        
        function g    = get.product(this)
            g = this.collectionRB_.product;
        end
        function this = set.product(this, s)
            this.collectionRB_.product = s;
        end
        function g    = get.referenceTracer(this)
            g = this.collectionRB_.referenceTracer;
        end
        function this = set.referenceTracer(this, s)
            this.collectionRB_.referenceTracer = s;
        end 
        function g    = get.ReferenceTracer(this)
            g = this.collectionRB_.ReferenceTracer;
        end
        function g    = get.subjectsJson(this)
            g = this.subjectsJson_;
        end
        function g    = get.tracer(this)
            g = this.collectionRB_.tracer;
        end
        function this = set.tracer(this, s)
            assert(ischar(s));
            this.collectionRB_.tracer = upper(s) ;
        end
        function g    = get.workpath(this)
            g = this.collectionRB_.workpath;
        end
        
        %%
        
        function this = align(this)
            this = this.alignCrossModal;
        end
        function this = alignCrossModal(this)
            %% ALIGNCROSSMODAL
            %  theFdg,theHo,theOo,theOc
            %  @return t4 in this.t4s:            e.g., {hov[1-9]r1_sumtr1_op_hov[1-9]r1_avgr1_to_op_fdgv1r1_t4}.
            %  @return resolved in this.product:  e.g., {hov[1-9]r1_sumtr1_op_hov[1-9]r1_avgr1_op_fdgv1r1.4dfp.hdr}.            

            pwd0     = pushd(this.workpath);            
            theHo    = this.alignCommonModal('HO');
            theHo    = theHo.productAverage('HO');            
            theOo    = this.alignCommonModal('OO');
            theOo    = theOo.productAverage('OO'); 
            theFdg   = this.alignCommonModal('FDG');
            theFdg   = theFdg.productAverage('FDG');
            this     = theFdg;
            prefixes = {theFdg.product{1}.fileprefix ...
                        theHo.product{1}.fileprefix ...
                        theOo.product{1}.fileprefix}; 
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/fdgv1r1_sumtr1_op_fdgv1r1_avg'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/hov1r1_sumtr1_op_hov1r1_avg'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/oov1r1_sumtr1_op_oov1r1_avg'

            this = this.resolve(prefixes, ...
                'compAlignMethod', 'align_crossModal', ...
                'NRevisions', 1, ...
                'maskForImages', 'Msktgen', ...
                'client', 'alignCrossModal_this');
            % cell2str(this.t4s_) =>
            % fdgv1r1_sumtr1_op_fdgv1r1_avgr1_to_op_fdgv1r1_t4
            % hov1r1_sumtr1_op_hov1r1_avgr1_to_op_fdgv1r1_t4
            % oov1r1_sumtr1_op_oov1r1_avgr1_to_op_fdgv1r1_t4
            % cellfun(@(x) ls(x.filename), this.product_, 'UniformOutput', false) =>
            % fdgv1r1_sumtr1_op_fdgv1r1_avgr1_op_fdgv1r1.4dfp.hdr
            % hov1r1_sumtr1_op_hov1r1_avgr1_op_fdgv1r1.4dfp.hdr
            % oov1r1_sumtr1_op_oov1r1_avgr1_op_fdgv1r1.4dfp.hdr

            this.alignDynamicImages('commonRef', theHo,  'crossRef', this);
            this.alignDynamicImages('commonRef', theOo,  'crossRef', this);
            theFdg = this.alignDynamicImages('commonRef', theFdg, 'crossRef', this);
            popd(pwd0);    

            theOc = theFdg.alignCrossModalSubset;
            this.collectionRB_.packageProduct([this.product theOc.product]);
            %this.constructReferenceTracerToT1001T4;
        end
        function this = alignCrossModalSubset(this)
            pwd0     = pushd(this.workpath);                     
            theFdg   = this.alignFramesSubset('FDG', 1:8);
            theOc    = this.alignCommonModal('OC'); 
            theOc    = theOc.productAverage('OC');
            theOc    = theOc.sqrt;            
            prefixes = {theFdg.product{1}.fileprefix ...
                        theOc.product{1}.fileprefix};
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/fdgv1r1_op_fdgv1r1_frames1to8_sumt_avg'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/ocv1r1_sumtr1_op_ocv1r1_avg_sqrt'

            this = this.resolve(prefixes, ...
                'compAlignMethod', 'align_crossModal', ...
                'NRevisions', 1, ...
                'maskForImages', 'none', ...
                'client', 'alignCrossModalSubset_this');
            % cell2str(this.t4s_) =>            
            % fdgv1r1_op_fdgv1r1_frames1to8_sumt_avgr1_to_op_fdgv1r1_t4
            % ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1_to_op_fdgv1r1_t4
            % cellfun(@(x) ls(x.filename), this.product_, 'UniformOutput', false) =>    
            % fdgv1r1_op_fdgv1r1_frames1to8_sumt_avgr1_op_fdgv1r1.4dfp.hdr
            % ocv1r1_sumtr1_op_ocv1r1_avg_sqrtr1_op_fdgv1r1.4dfp.hdr

            this.alignDynamicImages('commonRef', theOc,  'crossRef', this);
            popd(pwd0);
        end
        function this = alignDynamicImages(this, varargin)
            %% ALIGNDYNAMICIMAGES aligns common-modal source dynamic images to a cross-modal reference.
            %  @param commonRef, or common-modal reference, e.g., any of OC, OO, HO, FDG.
            %  @param crossRef,  or cross-modal reference, e.g., FDG.
            %  @return this.product := dynamic images aligned to a cross-modal reference is saved to the filesystem.
            
            %  TODO:  manage case of homo-tracer subsets
            
            ip = inputParser;
            addParameter(ip, 'commonRef', [], @(x) isa(x, 'mlpet.StudyResolveBuilder'));
            addParameter(ip, 'crossRef',  [], @(x) isa(x, 'mlpet.StudyResolveBuilder'));
            parse(ip, varargin{:});
            comm  = ip.Results.commonRef;
            cross = ip.Results.crossRef;
            
            pwd0 = pushd(this.workpath);            
            comm = comm.t4imgDynamicImages(comm.tracer); % comm.product := dynamic aligned to time-summed comm.product{1}
            comm_to_cross_t4 = cross.selectT4s('sourceTracer', lower(comm.tracer)); % construct t4s{r} for comm.product to cross.product{1}
    
            cross = cross.t4imgc(comm_to_cross_t4, comm.product);                
            
            cross.teardownIntermediates;
            this.collectionRB_ = this.collectionRB_.packageProduct(cross.product);
            popd(pwd0);
        end
        function this = alignFramesSubset(this, tracer, frames, varargin)
            assert(ischar(tracer));
            assert(isnumeric(frames));            
            pwd0 = pushd(this.workpath);
            %this = this.alignCommonModal(tracer, varargin{:});
            % this.t4s_{1}' =>
            % 'fdgv1r1_sumtr1_to_op_fdgv1r1_t4'
            % 'fdgv2r1_sumtr1_to_op_fdgv1r1_t4'
            %  cellfun(@(x) x.fqfilename, this.product_, 'UniformOutput', false)' =>
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/fdgv1r1_sumtr1_op_fdgv1r1.4dfp.hdr'
            % '/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/Vall/fdgv2r1_sumtr1_op_fdgv1r1.4dfp.hdr'  
            
            this = this.collectionRB_.constructFramesSubset(tracer, frames, varargin{:});
            popd(pwd0);
        end
        
        function            constructReferenceTracerToT1001T4(this)
            this.collectionRB_.constructReferenceTracerToT1001T4();
        end
        function            constructTracerRevisionToReferenceT4(this, varargin)
            this.collectionRB_.constructTracerRevisionToReferenceT4(varargin{:})
        end
        function fqfp     = finalFdg(this, dt, varargin)            
            ip = inputParser;
            addOptional(ip, 'suffix', '', @ischar)
            parse(ip, varargin{:})
            
            fqfp = fullfile(this.collectionRB_.workpath, ...
                sprintf('fdg%s_op_fdg%s_on_op_fdg_avgr1', this.ensureDtFormat(dt)));
        end
        function fqfp     = finalHo(this, dt, dt0, varargin)
            ip = inputParser;
            addOptional(ip, 'suffix', '', @ischar)
            parse(ip, varargin{:})
            
            fqfp = fullfile(this.collectionRB_.workpath, ...
                sprintf('ho%s_op_ho%s%s_on_op_fdg_avgr1', ...
                this.ensureDtFormat(dt), this.ensureDtFormat(dt0), ip.Results.suffix));
        end
        function fqfp     = finalOo(this, dt, dt0, varargin)
            ip = inputParser;
            addOptional(ip, 'suffix', '', @ischar)
            parse(ip, varargin{:})
            
            fqfp = fullfile(this.collectionRB_.workpath, ...
                sprintf('oo%s_op_oo%s%s_on_op_fdg_avgr1', ...
                this.ensureDtFormat(dt), this.ensureDtFormat(dt0), ip.Results.suffix));
        end
        function fqfp     = finalOc(this, dt, dt0, dtfdg, varargin)
            ip = inputParser;
            addOptional(ip, 'avgstr', '', @ischar)
            parse(ip, varargin{:})
            
            fqfp = fullfile(this.collectionRB_.workpath, ...
                sprintf('oc%s_op_oc%s%s_on_op_fdg%s_frames1to%i_avgtr1', ...
                this.ensureDtFormat(dt), this.ensureDtFormat(dt0), ip.Results.avgstr, this.ensureDtFormat(dtfdg), this.N_FRAMES_FOR_BOLUS));
        end
        function fqfp     = finalTracer(this, tr, varargin) 
            assert(ischar(tr));
            switch lower(tr)
                case 'fdg'
                    fqfp = this.finalFdg(varargin{:});
                case 'ho'
                    fqfp = this.finalHo(varargin{:});
                case 'oo'
                    fqfp = this.finalOo(varargin{:});
                case 'oc'
                    fqfp = this.finalOc(varargin{:});
                otherwise
                    error('mlpet:RuntimeError', 'StudyResolveBuilder.finalTracer')
            end
        end
        function fqfp     = finalTracerGlob(this, tr, varargin) 
            assert(ischar(tr));
            switch lower(tr)
                case 'fdg'
                    fqfp = this.finalFdg('*', varargin{:});
                case 'ho'
                    fqfp = this.finalHo('*', '*', varargin{:});
                case 'oo'
                    fqfp = this.finalOo('*', '*', varargin{:});
                case 'oc'
                    fqfp = this.finalOc('*', '*', '*', varargin{:});
                otherwise
                    error('mlpet:RuntimeError', 'StudyResolveBuilder.finalTracer')
            end
        end
        function this     = productAverage(this, varargin)
            this.collectionRB_ = this.collectionRB_.productAverage(varargin{:});
        end
        function this     = resolve(this, varargin)
            this.collectionRB_.setLogPath(fullfile(this.workpath, 'Log', ''));
            this.collectionRB_ = this.collectionRB_.resolve(varargin{:});
        end
        function            saveStandardized(this)
            this.collectionRB_.saveStandardized();
        end
        function            saveAvgtStandardized(this)
            this.collectionRB_.saveAvgtStandardized();
        end        
        function ts       = selectT4s(this, varargin)
            ts = this.collectionRB_.selectT4s(varargin{:});
        end
        function this     = sqrt(this, varargin)
            this.collectionRB_ = this.collectionRB_.sqrt(varargin{:});
        end
        function this     = t4imgc(this, varargin)
            this.collectionRB_ = this.collectionRB_.t4imgc(varargin{:});
        end
        function t4_obj   = t4_mul(this)
            
            fv = mlfourdfp.FourdfpVisitor;
            pwd0 = pushd(this.collectionRB_.workpath);
            
            %% FDG
            
            t4_obj.fdg = {};
            fdg_glob = this.fdgglob(); %('fdgdt[0-9]+_avgtr1_to_op_fdgdt[0-9]+r1_t4');
            fdg_to_op_fdg_t4 = 'fdg_avgr1_to_op_fdg_avgr1_t4';
            for f = asrow(fdg_glob)
                t4 = sprintf('%s_to_op_fdg_avgr1_t4',  this.collectionRB_.frontOfT4(f{1}));
                mlbash(sprintf('t4_mul %s %s %s', f{1}, fdg_to_op_fdg_t4, t4))
                t4_obj.fdg = [t4_obj.fdg t4];
            end
            if isempty(t4_obj.fdg)
                if ~isfile('fdg_avgr1_to_op_fdg_avgr1_t4')
                    fv.t4_ident('fdg_avgr1_to_op_fdg_avgr1_t4')
                end
                t4_obj.fdg = {'fdg_avgr1_to_op_fdg_avgr1_t4'};
            end
            
            %% HO
            
            t4_obj.ho = {};
            ho_glob = this.hoglob();
            ho_to_op_fdg_t4 = 'ho_avgr1_to_op_fdg_avgr1_t4';
            for h = asrow(ho_glob)
                t4 = sprintf('%s_to_op_fdg_avgr1_t4', this.collectionRB_.frontOfT4(h{1}));
                mlbash(sprintf('t4_mul %s %s %s', h{1}, ho_to_op_fdg_t4, t4))
                t4_obj.ho = [t4_obj.ho t4];
            end
            if isempty(t4_obj.ho)
                if ~isfile('ho_avgr1_to_op_ho_avgr1_t4')
                    fv.t4_ident('ho_avgr1_to_op_ho_avgr1_t4')
                end
                t4_obj.ho = {'ho_avgr1_to_op_ho_avgr1_t4'};
            end
            
            %% OO
            
            t4_obj.oo = {};
            oo_glob = this.ooglob();
            oo_to_op_fdg_t4 = 'oo_avgr1_to_op_fdg_avgr1_t4';
            for o = asrow(oo_glob)
                t4 = sprintf('%s_to_op_fdg_avgr1_t4', this.collectionRB_.frontOfT4(o{1}));
                mlbash(sprintf('t4_mul %s %s %s', o{1}, oo_to_op_fdg_t4, t4))
                t4_obj.oo = [t4_obj.oo t4];
            end
            if isempty(t4_obj.oo)
                if ~isfile('oo_avgr1_to_op_oo_avgr1_t4')
                    fv.t4_ident('oo_avgr1_to_op_oo_avgr1_t4')
                end
                t4_obj.oo = {'oo_avgr1_to_op_oo_avgr1_t4'};
            end
            
            %% OC
            
            t4_obj.oc = {};
            oc_glob = this.ocglob();
            oc_to_op_fdg_t4 = glob('oc_avg_sqrtr1_to_op_fdgdt*_frames1to[1-9]_avgtr1_t4');
            for c = asrow(oc_glob)
                t4 = sprintf('%s_to_op_fdg_avgr1_t4', this.collectionRB_.frontOfT4(c{1}));
                mlbash(sprintf('t4_mul %s %s %s', c{1}, oc_to_op_fdg_t4{1}, t4))
                t4_obj.oc = [t4_obj.oc t4];
            end
            if isempty(t4_obj.oc)
                if ~isfile('oc_avgr1_to_op_oc_avgr1_t4')
                    fv.t4_ident('oc_avgr1_to_op_oc_avgr1_t4')
                end
                t4_obj.oc = {'oc_avgr1_to_op_oc_avgr1_t4'};
            end
            
            deleteExisting('t4_ojb.mat')
            save('t4_obj.mat', 't4_obj')            
            popd(pwd0)
        end
        function globbed  = fdgglob(~)
            globbed = {};
            globbed0 = glob('fdgdt*_avgtr1_to_op_fdgdt*r1_t4');
            for g = asrow(globbed0)
                if ~lstrfind(g{1}, '_frames1to')
                    globbed = [globbed g{1}]; %#ok<AGROW>
                end
            end            
        end
        function globbed  = hoglob(~)
            globbed = glob('hodt*_avgtr1_to_op_hodt*_avgtr1_t4');
            if isempty(globbed)
                globbed = glob('hodt*_avgtr1_to_op_hodt*_t4');
            end
        end
        function globbed  = ooglob(~)
            globbed = glob('oodt*_avgtr1_to_op_oodt*_avgtr1_t4');
            if isempty(globbed)
                globbed = glob('oodt*_avgtr1_to_op_oodt*_t4');
            end
        end
        function globbed  = ocglob(~)
            globbed = glob('ocdt*_avgtr1_to_op_ocdt*_avgtr1_t4');
            if isempty(globbed)
                globbed = glob('ocdt*_avgtr1_to_op_ocdt*_t4');
            end
        end
        function            teardownIntermediates(this)
            this.collectionRB_.teardownIntermediates();
        end
        function            view(this)
            mlfourdfp.Viewer.view(this.product);
        end
		  
 		function this = StudyResolveBuilder(varargin)
 			%% STUDYRESOLVEBUILDER
 			%  @param sessionData is an mlpipeline.ISessionData and must be well-defined.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'studyData', [])
            addParameter(ip, 'subjectData', [])
            addParameter(ip, 'sessionData', [])
            addParameter(ip, 'makeClean', true, @islogical)
            parse(ip, varargin{:});            
            ipr = ip.Results;
            assert(isa(ipr.sessionData, 'mlpipeline.ISessionData'))
            this.studyData_ = ipr.studyData;
            this.subjectData_ = ipr.subjectData;
            this.sessionData_ = ipr.sessionData;
            if isempty(this.studyData_) && isa(this.sessionData_.studyData, 'mlpipeline.IStudyData')
                this.studyData_ = this.sessionData_.studyData;
            end
            if isempty(this.subjectData_) && isa(this.sessionData_.subjectData, 'mlpipeline.ISubjectData')
                this.subjectData_ = this.sessionData_.subjectData;
            end
            this.makeClean_ = ipr.makeClean;
            if this.makeClean_
                this.makeClean()
            end
            
            this = this.configureSubjectData__();
            this = this.configureCT__();
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        collectionRB_ % always nontrivial
        makeClean_
        sessionData_ % always nontrivial
        studyData_
        subjectData_
        subjectsJson_
    end
    
    methods (Access = protected)
        function this = configureCalibrations__(this)
            %% explores the sessions within the subject-path and
            %  sym-links calibration FDG orphaned to separate sessions.
            
            import mlsystem.DirTool
            import mlfourdfp.CollectionResolveBuilder.*
            if isempty(this.subjectData_)
                return
            end    
            pwd0 = pushd(this.subjectData_.subjectPath);
            dt = DirTool('ses-*');
            for ses = dt.dns

                pwd1 = pushd(ses{1});
                srcpth = fullfile(this.sessionData_.projectPath, ses{1}, '');
                dt1 = DirTool(fullfile(srcpth, '*_DT*.000000-Converted-AC'));
                if 1 == length(dt1.fqdns) && strncmp(dt1.dns{1}, 'FDG', 3)
                    lns_with_datetime(fullfile(srcpth, 'FDG_DT*.000000-Converted-AC/fdg*.4dfp.*'))
                end
                popd(pwd1)
            end
            popd(pwd0)
        end
        function this = configureCT__(this)
            %% explores the sessions within the subject-path and
            %  sym-links ct.
            
            import mlsystem.DirTool
            if isempty(this.subjectData_)
                return
            end    
            pwd0 = pushd(this.subjectData_.subjectPath);
            dt = DirTool('ses-*');
            for ses = dt.dns

                pwd1 = pushd(ses{1});
                srcpth = fullfile(this.sessionData_.projectPath, ses{1}, '');
                if isfile(fullfile(srcpth, 'ct.4dfp.hdr')) && ~isfile('ct.4dfp.hdr')
                    mlfourdfp.FourdfpVisitor.lns_4dfp(fullfile(srcpth, 'ct'))
                end
                popd(pwd1)
            end
            popd(pwd0)
        end
        function this = configureSubjectData__(this)
            %% iterates through this.subjectData_.subjectsJson,
            %  finds the initialized this.subjectData_.subjectFolder
            %  and initializes the subject path using this.subjectData_.aufbauSessionPath.
            
            if isempty(this.subjectData_)
                return
            end
            this.subjectsJson_ = this.subjectData_.subjectsJson;
            S = this.subjectsJson_;
            for sub = fields(S)'
                d = this.subjectData_.ensuredirSub(S.(sub{1}).sid);
                if this.makeClean_ && ...
                        strcmp(mybasename(d), this.subjectData_.subjectFolder)
                    this.subjectData_.aufbauSessionPath(d, S.(sub{1}));
                end
            end
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

