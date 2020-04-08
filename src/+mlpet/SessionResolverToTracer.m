classdef SessionResolverToTracer < handle & mlpet.ResolverToTracerStrategy
	%% SESSIONRESOLVERTOTRACER  

	%  $Revision$
 	%  was created 09-Jan-2020 10:33:33 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.	
	
    properties (Constant)
        IS_FINISHED = false
    end
    
    properties (Dependent)
        client
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
            if strcmp(dt, '*')
                return
            end
            if ~strncmp(dt, 'dt', 2)
                dt = ['dt' dt];
            end
            dt = strtok(dt, '.');
        end
    end

	methods
        function g = get.client(this)
            g = this.client_;
        end
        
        function this     = alignCommonModal(this, varargin)
            %  @param required tracer is char.
            %  @return resolution of all scans with specified tracer in the session.
            
            ip = inputParser;
            addRequired(ip, 'tracer', @ischar);
            parse(ip, varargin{:});
            this.tracer = ip.Results.tracer;
            this.collectionRB.sessionData.referenceTracer = lower(this.tracer);
            
            prefixes = this.linkAndSimplifyScans(this.tracer);
            if ~isempty(prefixes)
                this.resolve(prefixes, varargin{2:end});
            end
        end     
        function this     = alignCrossModalSubset(this, varargin)
            %% align source to early frames (N_FRAMES_OF_BOLUS) of target
            
            ip = inputParser;
            addParameter(ip, 'source', 'OC', @ischar)
            addParameter(ip, 'target', 'FDG', @ischar)
            addParameter(ip, 'framesOfTarget', this.framesOfSubsetTarget_, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            this.framesOfSubsetTarget_ = ipr.framesOfTarget;
            
            pwd0     = pushd(this.workpath); 
            
            target   = copy(this.alignFramesSubset(ipr.target, this.framesOfSubsetTarget_));            
            source   = copy(this.alignCommonModal(ipr.source));
                       source.productAverage(ipr.source);
                       source.sqrt;
            
            prefixes = { target.product{1}.fileprefix ...
                         source.product{1}.fileprefix};            
            this = copy(target);
            this.resolve(prefixes, ...
                'compAlignMethod', 'align_crossModal', ...
                'NRevisions', 1, ...
                'maskForImages', 'none', ...
                'client', 'alignCrossModalSubset_this');
            
            that = copy(this);
            that.alignDynamicImages('commonRef', source,  'crossRef', this);
            
            popd(pwd0);
        end   
        function this     = alignDynamicImages(this, varargin)
            %% ALIGNDYNAMICIMAGES aligns common-modal source dynamic images to a cross-modal reference.
            %  @param commonRef, or common-modal reference, e.g., any of OC, OO, HO, FDG.
            %  @param crossRef,  or cross-modal reference, e.g., FDG.
            %  @return this.product := dynamic images aligned to a cross-modal reference is saved to the filesystem.
            
            %  TODO:  manage case of homo-tracer subsets
            
            ip = inputParser;
            addParameter(ip, 'commonRef', [], @(x) isa(x, 'mlpet.ResolverToTracerStrategy'));
            addParameter(ip, 'crossRef',  [], @(x) isa(x, 'mlpet.ResolverToTracerStrategy'));
            parse(ip, varargin{:});
            ipr = ip.Results;
            comm  = copy(ipr.commonRef);
            cross = copy(ipr.crossRef);
            
            pwd0 = pushd(this.workpath); 
            
            comm.t4imgDynamicImages(comm.tracer); % comm.product := dynamic aligned to time-summed comm.product{1}
            comm_to_cross_t4 = cross.selectT4s('sourceTracer', lower(comm.tracer)); % construct t4s{r} for comm.product to cross.product{1}    
            cross.t4imgc(comm_to_cross_t4, comm.product);
            cross.teardownIntermediates;
            this.packageProduct(cross.product);
            
            popd(pwd0);
        end
        function this     = alignFramesSubset(this, tracer, frames, varargin)
            assert(ischar(tracer));
            assert(isnumeric(frames));            
            pwd0 = pushd(this.workpath);            
            this.collectionRB = this.collectionRB.constructFramesSubset(tracer, frames, varargin{:});
            popd(pwd0);
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
                    switch lower(this.client_.sessionData.referenceTracer)
                        case 'fdg'
                            fqfp = this.finalOc_FDG('*', '*', '*', varargin{:});
                        case 'ho'
                            fqfp = this.finalOc_HO('*', '*', varargin{:});
                        otherwise
                            error('mlpet:ValueError', ...
                                'SessionResolveToTracer.finalTracerGlob() does not support %s', ...
                                lower(this.client_.sessionData.referenceTracer))
                    end
                otherwise
                    error('mlpet:RuntimeError', 'SessionResolverToTracer.finalTracerGlob')
            end
        end
        function prefixes = linkAndSimplifyScans(this, varargin)
            %% Creates links to tracer images distributed on the filesystem so that resolve operations may be done in the pwd.
            %  Builds *_avgt.4dfp de novo.  
            %  e.g.:  HO_DT(yyyymmddHHMMSS).000000-Converted-AC/ho_avgt.4dfp.hdr -> hodt(yyyymmddHHMMSS)_avgt.4dfp.hdr
            %  @param required tracer is char.
            %  @param optional suffix is char, e.g., _avgt.
            %  @return prefixes = cell(1, N(available images)) as unique fileprefixes in the pwd.
            
            ip = inputParser;
            addRequired(ip, 'tracer', @ischar);
            addOptional(ip, 'suffix', '', @ischar);
            parse(ip, varargin{:});         
            
            try
                files = this.collectionRB.lns_with_DateTime( ...
                    fullfile(this.collectionRB.sessionData.subjectPath, ...
                             this.collectionRB.sessionData.sessionFolder, ...
                             sprintf('%s_DT*.000000-Converted-AC/%s%s.4dfp.*', ...
                                     upper(ip.Results.tracer), lower(ip.Results.tracer), ip.Results.suffix)));
                prefixes = this.collectionRB.uniqueFileprefixes(files);
                prefixes = this.refreshTracerAvgt(prefixes);
            catch ME
                handwarning(ME)
            end
        end
        function prefixes = refreshTracerAvgt(~, prefixes)
            for p = asrow(prefixes)
                deleteExisting([p{1} '_avgt.4dfp.*'])
                ic2 = mlfourd.ImagingContext2([p{1} '.4dfp.hdr']);
                ic2 = ic2.timeAveraged;
                ic2.save;
            end
        end
		  
 		function this = SessionResolverToTracer(varargin)
 			%% SESSIONRESOLVERTOTRACER
 			%  @param .

 			this = this@mlpet.ResolverToTracerStrategy(varargin{:});
            ensuredir(fullfile(this.client_.sessionData.subjectPath, this.client_.sessionData.sessionFolder, ''))
            this.collectionRB_ = mlfourdfp.CollectionResolveBuilder( ...
                'sessionData', this.client_.sessionData, ...
                'workpath', fullfile(this.client_.sessionData.subjectPath, this.client_.sessionData.sessionFolder, ''));
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        framesOfSubsetTarget_ = 1:8
    end
    
    methods (Access = protected)
        function globbed = fdgglob(~)
            globbed = {};
            globbed0 = glob('fdgdt*_avgtr1_to_op_fdgdt*r1_t4');
            for g = asrow(globbed0)
                re = regexp(g{1}, '^fdgdt\d+_avgtr1_to_op_fdgdt\d+r1_t4$', 'once');
                if ~isempty(re)
                    globbed = [globbed g{1}]; %#ok<AGROW>
                end
            end            
        end
        function globbed = hoglob(~)
            globbed = {};
            globbed0 = glob('hodt*_avgtr1_to_op_hodt*_t4');
            for g = asrow(globbed0)
                re = regexp(g{1}, '^hodt\d+_avgtr1_to_op_hodt\d+r1_t4$', 'once');
                if ~isempty(re)
                    globbed = [globbed g{1}]; %#ok<AGROW>
                end
            end 
        end
        function globbed = ooglob(~)
            globbed = {};
            globbed0 = glob('oodt*_avgtr1_to_op_oodt*_t4');
            for g = asrow(globbed0)
                re = regexp(g{1}, '^oodt\d+_avgtr1_to_op_oodt\d+r1_t4$', 'once');
                if ~isempty(re)
                    globbed = [globbed g{1}]; %#ok<AGROW>
                end
            end 
        end
        function globbed = ocglob(~)
            globbed = {};
            globbed0 = glob('ocdt*_avgtr1_to_op_ocdt*_t4');
            for g = asrow(globbed0)
                re = regexp(g{1}, '^ocdt\d+_avgtr1_to_op_ocdt\d+r1_t4$', 'once');
                if ~isempty(re)
                    globbed = [globbed g{1}]; %#ok<AGROW>
                end
            end
        end    
        
        function fqfp = finalFdg(this, dt, varargin)
            ip = inputParser;
            addParameter(ip, 'suffix', '', @ischar)
            addParameter(ip, 'path', this.workpath, @isfolder)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            ref  = lower(this.client_.sessionData.referenceTracer);
            fqfp = fullfile(ipr.path, ...
                sprintf('fdg%s_op_fdg%s_on_op_%s_avgr1', this.ensureDtFormat(dt), ipr.suffix, ref));
        end
        function fqfp = finalHo(this, dt, dt0, varargin)
            ip = inputParser;
            addParameter(ip, 'suffix', '', @ischar)
            addParameter(ip, 'path', this.workpath, @isfolder)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            ref  = lower(this.client_.sessionData.referenceTracer);
            fqfp = fullfile(ipr.path, ...
                sprintf('ho%s_op_ho%s%s_on_op_%s_avgr1', ...
                this.ensureDtFormat(dt), this.ensureDtFormat(dt0), ipr.suffix, ref));
        end
        function fqfp = finalOo(this, dt, dt0, varargin)
            ip = inputParser;
            addParameter(ip, 'suffix', '', @ischar)
            addParameter(ip, 'path', this.workpath, @isfolder)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            ref  = lower(this.client_.sessionData.referenceTracer);
            fqfp = fullfile(ipr.path, ...
                sprintf('oo%s_op_oo%s%s_on_op_%s_avgr1', ...
                this.ensureDtFormat(dt), this.ensureDtFormat(dt0), ipr.suffix, ref));
        end
        function fqfp = finalOc_FDG(this, dt, dt0, dtfdg, varargin)
            ip = inputParser;
            addParameter(ip, 'avgstr', '', @ischar)
            addParameter(ip, 'path', this.workpath, @isfolder)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            fqfp = fullfile(ipr.path, ...
                sprintf('oc%s_op_oc%s%s_on_op_fdg%s_frames1to%i_avgtr1', ...
                this.ensureDtFormat(dt), this.ensureDtFormat(dt0), ipr.avgstr, this.ensureDtFormat(dtfdg), this.framesOfSubsetTarget_(end)));
        end
        function fqfp = finalOc_HO(this, dt, dt0, varargin)
            ip = inputParser;
            addParameter(ip, 'suffix', '', @ischar)
            addParameter(ip, 'path', this.workpath, @isfolder)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            ref  = lower(this.client_.sessionData.referenceTracer);
            fqfp = fullfile(ipr.path, ...
                sprintf('oc%s_op_oc%s%s_on_op_%s_avgr1', ...
                this.ensureDtFormat(dt), this.ensureDtFormat(dt0), ipr.suffix, ref));
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

