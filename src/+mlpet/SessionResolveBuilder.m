classdef SessionResolveBuilder < mlpet.StudyResolveBuilder
	%% SESSIONRESOLVEBUILDER operates on scans contained in $SUBJECTS_DIR/sub-S000000/ses-E000000

	%  $Revision$
 	%  was created 07-May-2019 01:16:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
       
	methods
        function this     = alignCommonModal(this, varargin)
            %  @param required tracer is char.
            %  @return resolution of all scans with specified tracer in the session.
            
            ip = inputParser;
            addRequired(ip, 'tracer', @ischar);
            parse(ip, varargin{:});
            this.tracer = ip.Results.tracer;
            
            prefixes = this.stageSessionScans(ip.Results.tracer, '_avgt');
            if ~isempty(prefixes)
                this = this.resolve(prefixes, varargin{2:end});
            end
        end  
        function tf       = isfinished(this)
            import mlsystem.DirTool
            pwd0 = pushd(fullfile(this.collectionRB_.sessionData.subjectPath, ...
                                  this.collectionRB_.sessionData.sessionFolder, ''));
            dt_FDG = DirTool('FDG_DT*.000000-Converted-AC');
            dt_HO  = DirTool('HO_DT*.000000-Converted-AC');
            dt_OO  = DirTool('OO_DT*.000000-Converted-AC');
            dt_OC  = DirTool('OC_DT*.000000-Converted-AC');
            dt_fdg = DirTool('fdg*_op_fdg_on_op_fdg_avgr1.4dfp.img');
            dt_ho  = DirTool('ho*_op_ho*_on_op_fdg_avgr1.4dfp.img');
            dt_oo  = DirTool('oo*_op_oo*_on_op_fdg_avgr1.4dfp.img');
            dt_oc  = DirTool(sprintf('oc*_op_oc*_on_op_fdg*_frames1to%i_avgtr1.4dfp.img', this.N_FRAMES_FOR_BOLUS));
            popd(pwd0)
            
            tf = ~isempty(dt_FDG.fqdns) && ~isempty(dt_fdg.fqfns) && ...
                 ~isempty(dt_HO.fqdns)  && ~isempty(dt_ho.fqfns) && ...
                 ~isempty(dt_OO.fqdns)  && ~isempty(dt_oo.fqfns) && ...
                 ~isempty(dt_OC.fqdns)  && ~isempty(dt_oc.fqfns);
        end        
        function prefixes = stageSessionScans(this, varargin)
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
            
            try
                files = this.collectionRB_.lns_with_DateTime( ...
                    sprintf('%s_DT*.000000-Converted-AC/%s%s.4dfp.*', ...
                            upper(ip.Results.tracer), lower(ip.Results.tracer), ip.Results.suffix));
                prefixes = this.collectionRB_.uniqueFileprefixes(files);
            catch ME
                handwarning(ME)
            end
        end    
        function this     = t4imgDynamicImages(this, varargin)
            this.collectionRB_ = this.collectionRB_.t4imgDynamicImages( ...
                varargin{:}, 'staging_handle', @this.stageSessionScans);
        end       
                
 		function this = SessionResolveBuilder(varargin)
 			%% SESSIONRESOLVEBUILDER
 			%  @param sessionData is an mlpipeline.ISessionData.
            
            this = this@mlpet.StudyResolveBuilder(varargin{:});
            this.collectionRB_ = mlfourdfp.CollectionResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'workpath', fullfile(this.sessionData_.subjectPath, this.sessionData_.sessionFolder, ''));
 		end
    end 
    
    methods (Access = private)
        function this     = stageT1001FromReferenceTracer(this)
            pwd0 = pushd(this.workpath);
            globbed = glob([this.ReferenceTracer '_DT*.000000-Converted-AC']);
            assert(~isempty(globbed))
            mlfourdfp.FourdfpVisitor.lns_4dfp(fullfile(globbed{1}, 'T1001'));
            popd(pwd0)
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

