classdef (Abstract) StudyResolveBuilder < handle & matlab.mixin.Copyable
	%% STUDYRESOLVEBUILDER delegates properties and methods to mlfourdfp.CollectionResolveBuilder.
    %  It is the superclass to mlpet.SubjectResolveBuilder and mlpet.SessionResolveBuilder.

	%  $Revision$
 	%  was created 19-Jun-2019 00:19:40 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Dependent)
        sessionData
        subjectData
        subjectsJson
        workpath
    end
    
    methods (Static)       
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
            deleteDeadLink('*.4dfp.*')
            deleteExisting('t4_obj.mat')
        end
        function tf = validTracerSession(varargin)
            %% avoids sessions for only ct, only calibration or defective sessions
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addOptional(ip, 'pth', pwd, @isfolder)
            parse(ip, varargin{:})
            
            if isempty(globFolders(fullfile(ip.Results.pth, '*')))
                tf = true;
                return
            end 
            if lstrfind(ip.Results.pth, 'subjects_00993') % KLUDGE
                tf = true;
                return
            end
            pwd0 = pushd(ip.Results.pth);
            tf = ~isempty(globFolders('*-Converted-AC'));
            popd(pwd0)
        end
    end

	methods
        
        %% GET/SET
        
        function g    = get.sessionData(this)
            g = this.sessionData_;
        end
        function g    = get.subjectData(this)
            g = this.sessionData.subjectData;
        end
        function g    = get.subjectsJson(this)
            g = this.subjectsJson_;
        end
        function g    = get.workpath(this)
            g = this.resolverStrategy_.collectionRB.workpath;
        end
        
        %%
        
        function this = alignCrossModal(this)
            %% ALIGNCROSSMODAL
            %  theFdg,theHo,theOo,theOc
            %  @return t4 in this.t4s:            e.g., {hov[1-9]r1_sumtr1_op_hov[1-9]r1_avgr1_to_op_fdgv1r1_t4}.
            %  @return resolved in this.product:  e.g., {hov[1-9]r1_sumtr1_op_hov[1-9]r1_avgr1_op_fdgv1r1.4dfp.hdr}.            

            this.resolverStrategy_.alignCrossModal();
        end
        
        function that = clone(this)
            that = copy(this);
        end
        function            constructReferenceTracerToT1001T4(this)
            this.resolverStrategy_.collectionRB.constructReferenceTracerToT1001T4();
        end
        function            constructResamplingRestricted(this, varargin)
            this.resolverStrategy_.constructResamplingRestricted(varargin{:});
        end
        function            constructTracerRevisionToReferenceT4(this, varargin)
            this.resolverStrategy_.collectionRB.constructTracerRevisionToReferenceT4(varargin{:})
        end
        function tf       = isfinished(this)
            tf = this.resolverStrategy_.isfinished();
        end
        function            lns_json_all(this)
            import mlsystem.DirTool
            if isempty(this.subjectData)
                return
            end
            
            pwd0 = pushd(this.subjectData.subjectPath);            
            dt = DirTool('ses-*');
            for ses = dt.dns
                prjData = this.subjectData.createProjectData('sessionStr', ses{1});
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
        function t4_obj   = t4_mul(this)
            t4_obj = this.resolverStrategy_.t4_mul;
        end
        function            view(this)
            mlfourdfp.Viewer.view(this.resolverStrategy_.collectionRB.product);
        end
		  
 		function this = StudyResolveBuilder(varargin)
 			%% STUDYRESOLVEBUILDER
 			%  @param sessionData is an mlpipeline.ISessionData and must be well-defined.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'))
            addParameter(ip, 'makeClean', true, @islogical)
            parse(ip, varargin{:});            
            ipr = ip.Results;
            
            this.makeClean_ = ipr.makeClean;
            if this.makeClean_
                this.makeClean()
            end
            this.sessionData_ = ipr.sessionData;
            this.resolverStrategy_ = mlpet.ResolverToTracerStrategy.CreateResolver(this);            
            this = this.configureSubjectData__();
            this = this.configureCT__();
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        collectionRB_ % always nontrivial
        makeClean_
        resolverStrategy_
        sessionData_
        subjectsJson_
    end
    
    methods (Access = protected)
        function this = configureCalibrations__(this)
            %% explores the sessions within the subject-path and
            %  sym-links calibration FDG orphaned to separate sessions.
            
            import mlsystem.DirTool
            import mlfourdfp.CollectionResolveBuilder.*
            if isempty(this.subjectData)
                return
            end    
            pwd0 = pushd(this.subjectData.subjectPath);
            dt = DirTool('ses-*');
            for ses = dt.dns

                pwd1 = pushd(ses{1});
                srcpth = fullfile(this.sessionData.projectPath, ses{1}, '');
                dt1 = DirTool(fullfile(srcpth, '*_DT*.000000-Converted-AC'));
                if 1 == length(dt1.fqdns) && strncmp(dt1.dns{1}, 'FDG', 3)
                    lns_with_datetime(fullfile(srcpth, 'FDG_DT*.000000-Converted-AC/fdg*.4dfp.*'))
                end
                popd(pwd1)
            end
            popd(pwd0)
        end
        function this = configureCT__(this)
            %% explores the sessions within the subject-path, searches project/session and
            %  sym-links discovered ct.
            
            import mlsystem.DirTool
            if isempty(this.subjectData)
                return
            end    
            pwd0 = pushd(this.subjectData.subjectPath);
            dt = DirTool('ses-*');
            for ses = dt.dns

                pwd1 = pushd(ses{1});
                srcpth = fullfile(this.sessionData.projectPath, ses{1}, '');
                if isfile(fullfile(srcpth, 'ct.4dfp.hdr')) && ~isfile('ct.4dfp.hdr')
                    mlfourdfp.FourdfpVisitor.lns_4dfp(fullfile(srcpth, 'ct'))
                end
                popd(pwd1)
            end
            popd(pwd0)
        end
        function this = configureSubjectData__(this)
            %% iterates through this.subjectData.subjectsJson,
            %  finds the initialized this.subjectData.subjectFolder
            %  and initializes the subject path using this.subjectData.aufbauSessionPath.
            
            if isempty(this.subjectData)
                return
            end
            this.subjectsJson_ = this.subjectData.subjectsJson;
            S = this.subjectsJson_;
            for sub = fields(S)'
                d = this.subjectData.ensuredirSub(S.(sub{1}).sid);
                if this.makeClean_ && ...
                        strcmp(mybasename(d), this.subjectData.subjectFolder)
                    this.subjectData.aufbauSessionPath(d, S.(sub{1}));
                end
            end
        end
        function that = copyElement(this)
            %%  See also web(fullfile(docroot, 'matlab/ref/matlab.mixin.copyable-class.html'))
            
            that = copyElement@matlab.mixin.Copyable(this);
            % N.B.:  that.object_ = copy(this.object_);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

