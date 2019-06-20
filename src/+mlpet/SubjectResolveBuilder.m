classdef SubjectResolveBuilder < mlpet.StudyResolveBuilder
	%% SUBJECTRESOLVEBUILDER  

	%  $Revision$
 	%  was created 07-May-2019 01:16:29 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	methods
        function this = alignCommonModal(this, varargin)
            %  @param required tracer is char.
            %  @return resolution of all scans with specified tracer in the session.
            
            ip = inputParser;
            addRequired(ip, 'tracer', @ischar);
            parse(ip, varargin{:});
            
            prefixes = this.stageSubjectScans(ip.Results.tracer, '_avgt');
            if ~isempty(prefixes)
                this = this.resolve(prefixes, varargin{2:end});
            end
            this.tracer = ip.Results.tracer;
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
                    files = this.collectionRB_.lns_with_datetime( ...
                        fullfile(ses{1}, ...
                        sprintf('%s.4dfp.*', this.finalTracerGlob(ip.Results.tracer))));
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
            this = this.configureSubjectPath__;
            this = this.configureSessions__;
 		end
 	end 
    
    %% PRIVATE
    
    methods (Access = private)
        function this = configureSessions__(this)
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
                dt1 = DirTool('*_DT*.000000-Converted-AC');
                if ~isempty(dt1.dns) 
                    sd = mlraichle.SessionData( ...
                        'studyData', this.studyData_, ...
                        'projectData', mlraichle.ProjectData('sessionStr', ses{1}), ...
                        'subjectData', this.subjectData_, ...
                        'sessionFolder', ses{1}, ...
                        'tracer', this.studyData_.referenceTracer, ...
                        'ac', true); % referenceTracer
                    srb = mlpet.SessionResolveBuilder('sessionData', sd);
                    if ~srb.isfinished
                        srb.align;
                    end
                    
                    % for this object
                    this.collectionRB_ = mlfourdfp.CollectionResolveBuilder( ...
                        'sessionData', sd, ...
                        'workpath', fullfile(sd.subjectPath, sd.sessionFolder, ''));
                end
                popd(pwd1)
            end
            popd(pwd0)
        end
        function this = configureSubjectPath__(this)
            %% iterates through this.subjectData_.subjectsJson
            %  and initializes the subject path using this.subjectData_.aufbauSubjectPath.
            
            if isempty(this.subjectData_)
                return
            end
            S = this.subjectData_.subjectsJson;
            for sub = fields(S)'
                d = this.subjectData_.ensuredirSub(S.(sub{1}).sid);
                this.subjectData_.aufbauSubjectPath(d, S.(sub{1}));
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

