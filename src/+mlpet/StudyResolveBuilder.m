classdef (Abstract) StudyResolveBuilder 
	%% STUDYRESOLVEBUILDER delegates properties and methods to mlfourdfp.CollectionResolveBuilder

	%  $Revision$
 	%  was created 19-Jun-2019 00:19:40 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
    properties (Constant)
        N_FRAMES_FOR_BOLUS = 8
    end
    
    properties (Dependent)
        product
        referenceTracer
        tracer
        workpath
    end
    
    methods (Static)       
        function dt = ensureDtFormat(dt)
            if isempty(dt)
                dt = '';
                return
            end
            if isdatetime(dt)
                dt = datestr(dt, 'yyyymmddHHMMSS');
            end
            assert(ischar(dt));
            if ~strncmp(dt, 'dt', 2)
                dt = ['dt' dt];
            end
            dt = strtok(dt, '.');
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
        function fqfp     = finalFdg(this, dt)
            fqfp = fullfile(this.collectionRB_.sessionData.sessionPath, ...
                sprintf('fdg%s_op_fdg_on_op_fdg_avgtr1', this.ensureDtFormat(dt)));
        end
        function fqfp     = finalHo(this, dt, dt0)
            fqfp = fullfile(this.collectionRB_.sessionData.sessionPath, ...
                sprintf('ho%s_op_ho%s_avgtr1_on_op_fdg_avgr1', this.ensureDtFormat(dt), this.ensureDtFormat(dt0)));
        end
        function fqfp     = finalOo(this, dt, dt0)
            fqfp = fullfile(this.collectionRB_.sessionData.sessionPath, ...
                sprintf('oo%s_op_oo%s_avgtr1_on_op_fdg_avgr1', this.ensureDtFormat(dt), this.ensureDtFormat(dt0)));
        end
        function fqfp     = finalOc(this, dt, dt0, dtfdg, varargin)
            ip = inputParser;
            addOptional(ip, 'avgstr', '', @ischar)
            parse(ip, varargin{:})
            
            fqfp = fullfile(this.collectionRB_.sessionData.sessionPath, ...
                sprintf('oc%s_op_oc%s%s_on_op_fdg%s_frames1to%i_avgtr1', ...
                this.ensureDtFormat(dt), this.ensureDtFormat(dt0), ip.Results.avgstr, this.ensureDtFormat(dtfdg), this.N_FRAMES_FOR_BOLUS));
            if ~isfile([fqfp '.4dfp.img'])
                fqfp = this.finalOc(dt, dt0, dtfdg, 'avgtr1');
            end
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
        function fqfp     = finalTracerGlob(this, tr) 
            assert(ischar(tr));
            switch lower(tr)
                case 'fdg'
                    fqfp = this.finalFdg('*');
                case 'ho'
                    fqfp = this.finalHo('*', '*');
                case 'oo'
                    fqfp = this.finalOo('*', '*');
                case 'oc'
                    fqfp = this.finalOc('*', '*', '*');
                otherwise
                    error('mlpet:RuntimeError', 'StudyResolveBuilder.finalTracer')
            end
        end
        function tf       = isfinished(this)
            import mlsystem.DirTool
            pwd0 = pushd(fullfile(this.collectionRB_.sessionData.sessionPath));
            dt_FDG = DirTool('FDG_DT*.000000-Converted-AC');
            dt_HO  = DirTool('HO_DT*.000000-Converted-AC');
            dt_OO  = DirTool('OO_DT*.000000-Converted-AC');
            dt_OC  = DirTool('OC_DT*.000000-Converted-AC');
            dt_fdg = DirTool('fdg*_op_fdg_on_op_fdg_avgtr1.4dfp.img');
            dt_ho  = DirTool('ho*_op_ho*_avgtr1_on_op_fdg_avgr1.4dfp.img');
            dt_oo  = DirTool('oo*_op_oo*_avgtr1_on_op_fdg_avgr1.4dfp.img');
            dt_oc  = DirTool(sprintf('oc*_op_oc*_on_op_fdg*_frames1to%i_avgtr1', this.N_FRAMES_FOR_BOLUS));
            popd(pwd0)
            
            tf = ~isempty(dt_FDG.fqdns) && ~isempty(dt_fdg.fqfns) && ...
                 ~isempty(dt_HO.fqdns)  && ~isempty(dt_ho.fqfns) && ...
                 ~isempty(dt_OO.fqdns)  && ~isempty(dt_oo.fqfns) && ...
                 ~isempty(dt_OC.fqdns)  && ~isempty(dt_oc.fqfns);
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
        function this     = t4imgDynamicImages(this, varargin)
            this.collectionRB_ = this.collectionRB_.t4imgDynamicImages( ...
                varargin{:}, 'staging_handle', @this.stageSessionScans);
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
            addParameter(ip, 'sessionData', [], @(x) isa(x, 'mlpipeline.ISessionData'))
            parse(ip, varargin{:});
            ipr = ip.Results;
            this.studyData_ = ipr.studyData;
            this.subjectData_ = ipr.subjectData;
            this.sessionData_ = ipr.sessionData;
            this.collectionRB_ = mlfourdfp.CollectionResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'workpath', fullfile(this.sessionData_.subjectPath, this.sessionData_.sessionFolder, ''));
            if isempty(this.studyData_) && isa(this.sessionData_.studyData, 'mlpipeline.IStudyData')
                this.studyData_ = this.sessionData_.studyData;
            end
            if isempty(this.subjectData_) && isa(this.sessionData_.subjectData, 'mlpipeline.ISubjectData')
                this.subjectData_ = this.sessionData_.subjectData;
            end
 		end
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        studyData_
        subjectData_
        sessionData_ % always nontrivial
        collectionRB_ % always nontrivial
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

