classdef TracerDirector < mlpet.AbstractTracerDirector
	%% TRACERDIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 19:29:04
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	

	properties (Constant)
        NUM_VISITS = 3
    end
    
	properties (Dependent)
        anatomy
        builder
        result
        sessionData
        studyData
    end
    
    methods (Static)
        
        function assertenv
            envs = {'RELEASE' 'REFDIR'};
            
            for ie = 1:length(envs)
                val = getenv(envs{ie});
                dt  = mlsystem.DirTool([val '/*']);
                assert(~isempty(dt.fqfns), ...
                    sprintf('mlpet.TracerDirector:  environment variable %s points to a empty directory', val));
            end
        end  
        function lst = prepareFreesurferData(varargin)
            %% PREPAREFREESURFERDATA prepares session & visit-specific copies of data enumerated by this.freesurferData.
            %  @param named sessionData is an mlraichle.SessionData.
            %  @return 4dfp copies of this.freesurferData in sessionData.vLocation.
            %  @return lst, a cell-array of fileprefixes for 4dfp objects created on the local filesystem.
            
            FSD = { 'aparc+aseg' 'brainmask' 'T1' }; % 'aparc.a2009s+aseg' 
            FORCE_REPLACE = false;
        
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlraichle.SessionData'));
            parse(ip, varargin{:});
            
            sessd = ip.Results.sessionData;
            try
                deleteExisting(fullfile(sessd.sessionPath,    'T1001*'));
                deleteExisting(fullfile(sessd.vLocation,      'T1001*'));
                deleteExisting(fullfile(sessd.tracerLocation, 'T1001*'));
                for f = 1:length(FSD)                
                    deleteExisting(fullfile(sessd.sessionPath,    [FSD{f} '.*']));
                    deleteExisting(fullfile(sessd.vLocation,      [FSD{f} '.*']));
                    deleteExisting(fullfile(sessd.tracerLocation, [FSD{f} '.*']));
                end
            catch ME
                dispwarning(ME);
            end
            pwd0 = pushd(sessd.vLocation);
            fv   = mlfourdfp.FourdfpVisitor;
            lst  = cell(1, length(FSD));
            for f = 1:length(FSD)
                if (~fv.lexist_4dfp(FSD{f}) || FORCE_REPLACE)
                    try
                        sessd.mri_convert( [fullfile(sessd.mriLocation, FSD{f}) '.mgz'], [FSD{f} '.nii']);
                        sessd.nifti_4dfp_4(FSD{f});
                        if (strcmp(FSD{f}, 'T1'))
                            fv.move_4dfp(FSD{f}, [FSD{f} '001']);
                        end
                        lst = [lst fullfile(pwd, FSD{f})]; %#ok<AGROW>
                    catch ME
                        dispwarning(ME);
                    end
                end
            end
            popd(pwd0);
        end    
    end
    
    methods 
        
        %% GET/SET
        
        function g = get.anatomy(this)
            g = this.anatomy_;
        end
        function g = get.builder(this)
            g = this.builder_;
        end
        function g = get.result(this)
            g = this.result_;
        end
        function g = get.sessionData(this)
            g = this.builder_.sessionData;
        end
        function g = get.studyData(this)
            g = this.builder_.sessionData.studyData;
        end
        
        function this = set.sessionData(this, s)
            assert(isa(s, 'mlpipeline.SessionData'));
            this.builder_.sessionData = s;
        end
        
        %%        
               
        function tf   = constructKineticsPassed(this, varargin)
            %% CONSTRUCTKINETICSPASSED
            %  @param named 'roisBuild' is an 'mlrois.IRoisBuilder'.
            %  @returns tf logical.
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            tf = this.builder_.constructKineticsPassed(varargin{:});
        end        
        function obj  = getResult(this)
            obj = this.builder_.product;
        end
        function tf   = isJSReconComplete(~)
            tf = true;
        end
        function this = locallyStageTracer(this)
            this.builder_.vendorSupport = mlsiemens.MMRBuilder('sessionData', this.sessionData);
            this.builder_ = this.builder_.locallyStageTracer;
        end     
        function tf   = queryKineticsPassed(this, varargin)
            %% QUERYKINETICSPASSED
            %  @param named 'roisBuild' is an 'mlrois.IRoisBuilder'.
            %  @returns tf logical.
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            tf = this.builder_.queryKineticsPassed(varargin{:});
        end         
        
 		function this = TracerDirector(varargin)
 			%% TRACERDIRECTOR
 			%  @param builder must be an mlpet.TracerBuilder
            
            ip = inputParser;
            addRequired( ip, 'builder', @(x) isa(x, 'mlpet.TracerBuilder'));
            addParameter(ip, 'anatomy', 'T1001', @ischar);
            parse(ip, varargin{:});
            
            this.builder_ = ip.Results.builder;
            this.anatomy_ = ip.Results.anatomy;
        end
 	end 

    
    %% PROTECTED
    
    properties (Access = protected)
        anatomy_
        builder_
        result_
    end
    
    methods (Access = protected)
        function         instanceCleanSymlinks(this)            
            
            suffs = {'.4dfp.hdr' '.4dfp.ifh' '.4dfp.img' '.4dfp.img.rec'};
            try
                sd = this.sessionData;
                pwd0 = pushd(sd.tracerLocation);
                for s = 1:length(suffs)
                    deleteExisting(                 [sd.T1001('typ','fp') suffs{s}]);
                    copyfile(fullfile(sd.vLocation, [sd.T1001('typ','fp') suffs{s}]));
                    deleteExisting(                              [sd.tracerListmodeSif('typ','fp') suffs{s}]);
                    copyfile(fullfile(sd.tracerListmodeLocation, [sd.tracerListmodeSif('typ','fp') suffs{s}]));
                end
                popd(pwd0);
            catch ME
                handwarning(ME);
            end
        end        
        function         instanceCleanTracerRemotely(this, varargin)
            %  @param named distcompHost is the hostname or distcomp profile.
            
            ip = inputParser;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016b', @ischar);
            parse(ip, varargin{:});
            
            try
                chpc = mlpet.CHPC4TracerDirector( ...
                    this, 'distcompHost', ip.Results.distcompHost, 'sessionData', this.sessionData);                
                chpc.cleanTracer;
            catch ME
                handwarning(ME);
            end
        end        
        function this  = instanceConstructAnatomy(this, varargin)
            %% INSTANCECONSTRUCTANATOMY
            %  @param named target is the filename of a target, recognizable by mlfourd.ImagingContext.ctor;
            %  the default target is this.tracerResolvedFinal('epoch', this.sessionData.epoch);
            %  see also TracerDirector.tracerResolvedTarget.
            %  @param this.sessionData.{T1,aparcAseg,wmparc} exist on the filesystem.
            %  @param this.anatomy is char, the sessionData function-name for anatomy in the space of
            %  this.sessionData.T1; e.g., 'T1', 'T1001', 'brainmask'.
            %  @result ready-to-use t4 transformation files named {T1001,brainmask,wmparc}r1r2_to_op_fdgv1r1_t4 
            %  aligned to this.tracerResolvedTarget.
            
            bv = this.builder_.buildVisitor;
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'target', '', @ischar);
            parse(ip, varargin{:});
            [~,ic] = this.tracerResolvedTarget('target', ip.Results.target); 
            
            this.builder_ = this.builder_.packageProduct(ic);
            pwd0 = pushd(ic.filepath);
            anatomies = {'brainmask'}; % 'aparcA2009sAseg' 'aparcAseg' 'wmparc' 'T1001'
            for a = 1:length(anatomies)
                bv.ensureLocalFourdfp(this.sessionData.(anatomies{a}));
            end
            bv.ensureLocalFourdfp(this.sessionData.(this.anatomy));            
            this.builder_ = this.builder_.resolveModalitiesToProduct( ...
                {this.sessionData.(this.anatomy)('typ','fp')}, 'tag2', this.anatomy, varargin{:});
            
            %  TODO:  refactor with localTracerResolvedFinal[Sumt]
            esf = @mlfourdfp.FourdfpVisitor.ensureSafeFileprefix;
            cRB = this.builder_.compositeResolveBuilder;
            t4  = sprintf('%sr0_to_%s_t4', this.sessionData.(this.anatomy)('typ','fp'), cRB.resolveTag);
            for a = 1:length(anatomies)
                outfile = esf([this.sessionData.(anatomies{a})('typ','fp') '_' cRB.resolveTag]);
                cRB.t4img_4dfp( ...
                    t4, ...
                    esf(this.sessionData.(anatomies{a})('typ','fp')), ...
                    'out', outfile, ...
                    'options', sprintf('-n -O%s', ic.fileprefix));                
                if (lstrfind('brainmask', anatomies{a}))
                    ic = mlfourd.ImagingContext([outfile '.4dfp.ifh']);
                    ic.numericalNiftid;
                    ic = ic.binarizeBlended;
                    ic.saveas(this.sessionData.brainmaskBinarizeBlended);
                end
            end
            %this.builder_.compositeResolveBuilder = cRB;
            deleteExisting('*_b15.4dfp.*');
            popd(pwd0);
        end
        function this  = instanceConstructCompositeResolved(this, varargin)
            %% INSTANCECONSTRUCTCOMPOSITERESOLVED
            %  @param named target is the filename of a target, recognizable by mlfourd.ImagingContext.ctor;
            %  the default target is this.tracerResolvedFinal('epoch', this.sessionData.epoch) for FDG;
            %  see also TracerDirector.tracerResolvedTarget.
            %  @param this.anatomy is char; it is the sessionData function-name for anatomy in the space of
            %  this.sessionData.T1; e.g., 'T1', 'T1001', 'brainmask'.
            %  @result ready-to-use t4 transformation files aligned to this.tracerResolvedTarget.
            
            bv = this.builder_.buildVisitor;
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'target', '', @ischar);
            parse(ip, varargin{:});
            [~,icTarg] = this.tracerResolvedTarget('target', ip.Results.target, 'tracer', 'FDG');   
            
            pwd0 = pushd(this.sessionData.vLocation);         
            bv.lns_4dfp(icTarg.fqfileprefix);
            icTarg.filepath = pwd;
            this.builder_ = this.builder_.packageProduct(icTarg); % build everything resolved to FDG
            bv.ensureLocalFourdfp(this.sessionData.T1001);
            bv.ensureLocalFourdfp(this.sessionData.(this.anatomy));  
            this.builder_ = this.builder_.resolveModalitiesToProduct( ...
                this.localTracerResolvedFinalSumt, varargin{:});            
            
            cRB = this.builder_.compositeResolveBuilder;
            this.localTracerResolvedFinal(cRB, icTarg);            
            deleteExisting('*_b15.4dfp.*');
            popd(pwd0);            
        end
        function this  = instanceConstructExports(this, varargin)
            %% INSTANCECONSTRUCTEXPORTS creates symbolic links of useful results in directory named export.
            %  @return fullfile(sessionData.vLocation, export) with aligned tracer results and aligned anatomical results.
            
            sessd = this.sessionData;
            exportDir = fullfile(sessd.vLocation, 'export');
            if (isdir(exportDir))
                rmdir(exportDir, 's');
            end
            mkdir(exportDir);
            pwd0 = pushd(exportDir);
            bv = this.builder_.buildVisitor;
            bv.lns_4dfp(sessd.tracerResolvedFinal('typ','fqfp'));
            %bv.lns_4dfp(fullfile(sessd.tracerLocation, [sessd.brainmask('typ','fp') 'r2_' sessd.resolveTag]));
            deleteExisting(fullfile(sessd.tracerLocation, [sessd.T1001('typ','fp') 'r2_' sessd.resolveTag '.4dfp.*']));
            bv.lns_4dfp(fullfile(sessd.tracerLocation, ['T1001_' sessd.resolveTag]));
            bv.lns_4dfp(fullfile(sessd.tracerLocation, ['wmparc_' sessd.resolveTag]));
            bv.lns_4dfp(fullfile(sessd.tracerLocation, ['aparc+aseg_' sessd.resolveTag]));
            bv.lns(     fullfile(sessd.tracerLocation, sprintf('brainmaskr1r2_to_%s_t4', sessd.resolveTag)));
            popd(pwd0);
        end
        function this  = instanceConstructNiftyPETy(this)
            this = this.stageRawdata4NiftyPETy;
            dtumaps = this.stageUmaps4NiftyPETy;
            this.sessionData.frame = 0;
            for u = 1:length(dtumaps.fqfns)
                
                [t0, t1] = this.times4UmapIdx(this.str2umapIdx(dtumaps.fn{u}));
                this.builder.godo(t0, t1, this.sessionData.frame, umapIdx);
                this.sessionData.frame = this.sessionData.frame + 1;
            end
        end
        function this  = instanceConstructResolved(this)
            this = this.instanceReconstructResolved;
        end
        function this  = instanceConstructResolveReports(this)
            this.builder_.sessionData.attenuationCorrected = true; % KLUDGE
            this.builder_.sessionData.rnumber = 2;
            this.builder_ = this.builder_.reportResolved;
        end
        function [this,aab] = instanceConstructResolvedRois(this, varargin)
            %% INSTANCERESOLVEROISTOTRACER
            %  @param named 'roisBuilder' is an 'mlrois.IRoisBuilder'
            %  @returns aab, an mlfourd.ImagingContext from mlpet.BrainmaskBuilder.aparcAsegBinarized.
            
            ip = inputParser;
            addParameter(ip, 'roisBuilder', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});            
            sessd = this.sessionData;
            
            % actions
            
            pwd0 = sessd.tracerLocation;
            ensuredir(pwd0);
            pushd(pwd0);
            bmb = mlpet.BrainmaskBuilder('sessionData', sessd);
            [~,ct4rb] = bmb.brainmaskBinarized( ...
                'tracer', this.sessionData.tracerRevisionSumt('typ', 'mlfourd.ImagingContext'));
            aab = bmb.aparcAsegBinarized(ct4rb);
            popd(pwd0);
        end      
        function this  = instanceConstructResolvedTof(this, varargin)
            [~,ic] = this.tracerResolvedTarget(varargin{:});
            this.builder_ = this.builder_.packageProduct(ic);
            pwd0 = pushd(ic.filepath);
            this.builder_.buildVisitor.lns_4dfp(this.sessionData.tof('typ','fqfp'));
            this.builder_.buildVisitor.lns_4dfp(fullfile(this.sessionData.vLocation, 'ctMaskedOnT1001r2_op_T1001'));
            this.builder_.buildVisitor.lns_4dfp(this.sessionData.T1('typ','fqfp'));
            this.builder_.buildVisitor.lns_4dfp(this.sessionData.t2('typ','fqfp'));
            tof = this.builder_.resolveTofToT1;
            this.builder_ = this.builder_.resolveModalitiesToProduct( ...
                {tof ...
                 'ctMaskedOnT1001r2_op_T1001' ...
                 this.sessionData.T1('typ','fp') ...
                 this.sessionData.t2('typ','fp')});
            popd(pwd0);
        end
        function this  = instanceConstructUmapSynthForDynamicFrames(this)
            
            this.builder_ = this.builder_.packageProduct(this.sessionData.umap);
            this.builder_ = this.builder_.createUmapSynthForDynamicFrames;
        end  
        function list  = instanceListTracersConverted(this)
            if (this.sessionData.attenuationCorrected)
                this.sessionData.frame = 0;
            end
            dt = mlsystem.DirTool([this.sessionData.tracerListmodeMhdr '*']);
            list = dt.fqfns;            
        end
        function list  = instanceListTracersResolved(this)
            dt = mlsystem.DirTool([this.sessionData.tracerResolvedFinal('tracer', this.sessionData.tracer, 'typ', '.4dfp.ifh') '*']);
            list = dt.fqfns;              
        end
        function rpts  = instanceMakeReports(this)
            
        end
        function that  = instancePullFromRemote(this, varargin)
            %  INSTANCEPULLFROMREMOTE pulls everything in the remote sessionData.vLocation.
            %  @param named distcompHost is the hostname or distcomp profile.
            %  @return that, an instance of mlpet.TracerDirector.
            
            ip = inputParser;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016b', @ischar);
            parse(ip, varargin{:});
            
            try
                chpc = mlpet.CHPC4TracerDirector( ...
                    this, 'distcompHost', ip.Results.distcompHost, 'sessionData', this.sessionData);                
                chpc = chpc.pullData;
                that = chpc.theDeployedDirector; % TracerDirector instance deployed by factoryMethod
                assert(strcmp(class(that), class(this)));
            catch ME
                handwarning(ME);
            end
        end
        function this  = instancePullPattern(this, varargin)
            %  @param named 'pattern' specified remoate location fullfile(tracerLocation, pattern).
            %  @return rsync results on fullfile(tracerLocation, pattern).
            
            ip = inputParser;
            addParameter(ip, 'pattern', '', @ischar);
            parse(ip, varargin{:});
            
            import mldistcomp.*;
            sessd  = this.sessionData;
            csessd = sessd;
            csessd.sessionPath = CHPC.repSubjectsDir(sessd.sessionPath);            
            try
                s = []; r = '';
                [s,r] = CHPC.rsync( ...
                    fullfile(csessd.vLocation, ip.Results.pattern), ...
                    [sessd.vLocation '/'], ...
                    'chpcIsSource', true);
            catch ME
                fprintf('s->%i, r->%s\n', s, r);
                handwarning(ME);
            end
            try
                [s,r] = CHPC.rsync( ...
                    fullfile(csessd.tracerLocation, ip.Results.pattern), ...
                    sessd.tracerLocation, ...
                    'chpcIsSource', true);
            catch ME
                fprintf('s->%i, r->%s\n', s, r);
                handwarning(ME);
            end
            for e = 1:this.sessionData.supEpoch
                try
                    Efolder = sprintf('E%i', e);
                    [s,r] = CHPC.rsync( ...
                        fullfile(csessd.tracerLocation, Efolder, ip.Results.pattern), ...
                        fullfile( sessd.tracerLocation, Efolder), ...
                        'chpcIsSource', true);
                catch ME
                    fprintf('s->%i, r->%s\n', s, r);
                    handwarning(ME);
                end
            end
            try
                Efolder = sprintf('E1to%i', this.sessionData.supEpoch);
                [s,r] = CHPC.rsync( ...
                    fullfile(csessd.tracerLocation, Efolder, ip.Results.pattern), ...
                    fullfile( sessd.tracerLocation, Efolder), ...
                    'chpcIsSource', true); %#ok<ASGLU>
            catch ME
                fprintf('s->%i, r->%s\n', s, r);
                handwarning(ME);
            end
        end        
        function that  = instancePushMinimalToRemote(this, varargin)
            %  INSTANCEPUSHTOREMOTE pushes everything to the remote sessionData.vLocation.
            %  @param named distcompHost is the hostname or distcomp profile.
            
            ip = inputParser;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016b', @ischar);
            parse(ip, varargin{:});
            
            try
                chpc = mlpet.CHPC4TracerDirector( ...
                    this, 'distcompHost', ip.Results.distcompHost, 'sessionData', this.sessionData);                
                chpc.pushMinimalData;
                that = [];
            catch ME
                handwarning(ME);
            end
        end
        function that  = instancePushToRemote(this, varargin)
            %  INSTANCEPUSHTOREMOTE pushes everything to the remote sessionData.vLocation.
            %  @param named distcompHost is the hostname or distcomp profile.
            
            ip = inputParser;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016b', @ischar);
            parse(ip, varargin{:});
            
            try
                chpc = mlpet.CHPC4TracerDirector( ...
                    this, 'distcompHost', ip.Results.distcompHost, 'sessionData', this.sessionData);                
                chpc.pushData;
                that = [];
            catch ME
                handwarning(ME);
            end
        end
        function this  = instanceReconstructResolved(this)
            if (~this.sessionData.attenuationCorrected)
                this = this.instanceConstructResolvedNAC;
                return
            end
            this = this.instanceConstructResolvedAC;
        end
        function this  = instanceReconstructUnresolved(this)
            if (~this.sessionData.attenuationCorrected)
                this = this.instanceConstructUnresolvedNAC;
                return
            end
            this = this.instanceConstructUnresolvedAC;
        end
        function this  = instanceTestLaunching(this, varargin)
            ls(this.sessionData.tracerLocation)
            this.result_ = ls(this.sessionData.tracerLocation);
        end
        function obj   = tracerResolvedFinal(this, varargin)
            sessd = this.sessionData;
            sessd.attenuationCorrected = true;
            sessd.rnumber = 2;
            obj = sessd.tracerResolvedFinal(varargin{:});
        end
        function [obj,ic] = tracerResolvedTarget(this, varargin)
            %  @param named target is the filename of a target, recognizable by mlfourd.ImagingContext.ctor;
            %  the default target is this.tracerResolvedFinal('epoch', this.sessionData.epoch).
            %  @param named tracer is an alternative tracer for the target
            
            ip = inputParser;
            ip.KeepUnmatched;
            addParameter(ip, 'target', '', @ischar);
            addParameter(ip, 'tracer', this.sessionData.tracer, @ischar);
            parse(ip, varargin{:});
            import mlfourd.*;
            
            if (~isempty(ip.Results.target))
                obj = ip.Results.target;
                ic  = ImagingContext(obj);
                return
            end
            
            sessd = this.sessionData;
            sessd.tracer = ip.Results.tracer;
            sessd.attenuationCorrected = true;
            sessd.rnumber = 2;
            obj = sessd.tracerResolvedFinalSumt;   
            if (lexist(obj, 'file'))
                ic  = ImagingContext(obj);
                return
            end

            obj_ = this.tracerResolvedFinal('epoch', this.sessionData.epoch);
            assert(lexist(obj_, 'file'))
            ic = ImagingContext(obj_);
            ic.numericalNiftid;
            ic = ic.timeSummed;
            ic.fourdfp;
            ic.save;
        end          
    end
    
    %% PRIVATE
    
    methods (Access = private)
        function this  = instanceConstructResolvedAC(this)
            this.builder_ = this.builder_.reconstituteFramesAC;
            this.sessionData.frame = nan;
            this.builder_.sessionData.frame = nan;
            this.builder_ = this.builder_.partitionMonolith;
            this.builder_ = this.builder_.motionCorrectFrames;            
            this.builder_ = this.builder_.reconstituteFramesAC2;
            this.builder_ = this.builder_.sumProduct;
        end
        function this  = instanceConstructResolvedNAC(this)     
            mlraichle.UmapDirector.constructUmaps('sessionData', this.sessionData);       
            this.builder_       = this.builder_.locallyStageTracer;
            this.builder_       = this.builder_.replaceMonolithFrames; % as requested of this.builder_ in its ctor.
            this.builder_       = this.builder_.partitionMonolith; 
            [this.builder_,multiEpochOfSummed,reconstitutedSummed] = this.builder_.motionCorrectFrames;
            reconstitutedSummed = reconstitutedSummed.motionCorrectCTAndUmap;             
            this.builder_       = reconstitutedSummed.motionUncorrectUmap(multiEpochOfSummed);
            %this.builder_       = this.builder_.createUmapSynthForDynamicFrames;
        end
        function this  = instanceConstructUnresolvedAC(this)
            this.builder_ = this.builder_.reconstituteFramesAC;
            this.sessionData.frame = nan;
            this.builder_.sessionData.frame = nan;
            this.builder_ = this.builder_.partitionMonolith;
            this.builder_ = this.builder_.motionCorrectFrames;            
            this.builder_ = this.builder_.reconstituteFramesAC2;
            this.builder_ = this.builder_.sumProduct;
        end
        function this  = instanceConstructUnresolvedNAC(this)     
            this.builder_ = this.builder_.locallyStageTracer;
            this          = this.sumRevisionAndCopyToFinalSumt;
            this.builder_ = this.builder_.packageProduct(this.sessionData.tracerResolvedFinalSumt);
            this.builder_ = this.builder_.motionCorrectCTAndUmap;             
            this.builder_ = this.builder_.repUmapToE7Format;
        end
        function this  = sumRevisionAndCopyToFinalSumt(this)
            ic  = mlfourd.ImagingContext(this.sessionData.tracerRevision);
            ic  = ic.timeSummed;
            nii = ic.niftid;
            nii.fqfilename = this.sessionData.tracerResolvedFinalSumt;
            ensuredir(nii.filepath);
            nii.save;
        end
        function c     = localTracerResolvedFinalSumt(this)  
            %  TODO:  refactor with localTracerResolvedFinal
            
            fv = mlfourdfp.FourdfpVisitor;
            sd = this.sessionData;
            tr = {'OC' 'OO' 'HO'};
            sc = 1:3;
            
            c = {};
            for it = 1:length(tr)
                for is = sc
                    sd.tracer = tr{it};
                    sd.snumber = is;
                    if (lexist(sd.tracerResolvedFinal, 'file'))
                        if (lexist(sd.tracerResolvedFinalSumt, 'file'))
                            try
                                fv.copyfile_4dfp(sd.tracerResolvedFinalSumt('typ','fqfp'));
                            catch ME
                                dispwarning(ME);
                            end
                        else
                            nn = mlfourd.NumericalNIfTId.load(sd.tracerResolvedFinal);
                            nn = nn.timeSummed;
                            nn.filesuffix = '.4dfp.ifh';
                            nn.filepath = pwd;
                            nn.save;
                        end
                        c = [c      {sd.tracerResolvedFinalSumt('typ','fp')}]; %#ok<AGROW>
                    end
                end
            end
            assert(~isempty(c));
        end
        function c     = localTracerResolvedFinal(this, cRB, icTarg)
            %  TODO:  refactor with localTracerResolvedFinalSumt
            
            assert(isa(cRB, 'mlfourdfp.CompositeT4ResolveBuilder'));
            assert(lexist_4dfp(icTarg.fileprefix));
            sd = this.sessionData;
            tr = {'OC' 'OO' 'HO'};
            sc = 1:3;     
            
            c = {};
            for it = 1:length(tr)
                for is = sc
                    sd.tracer = tr{it};
                    sd.snumber = is;
                    t4 = sprintf('%sr0_to_%s_t4', sd.tracerResolvedFinalSumt('typ','fp'), cRB.resolveTag);
                    outfile = sd.tracerResolvedFinalOpFdg('typ','fp');
                    if (lexist(strrep(t4,'r0','r2'), 'file') && ~lexist_4dfp(outfile))
                        try
                            cRB.t4img_4dfp( ...
                                t4, ...
                                sd.tracerResolvedFinal('typ','fqfp'), ...
                                'out', outfile, ...
                                'options', sprintf('-n -O%s', icTarg.fileprefix));
                            c = [c outfile]; %#ok<AGROW>
                        catch ME
                            dispwarning(ME);
                        end
                    end
                end
            end
        end
    end
    
    %% DEPRECATED
    
    methods (Hidden)        
        function this  = instanceConstructKinetics(this, varargin)
            %% INSTANCECONSTRUCTKINETICS requests that the builder prepare filesystems, coregistrations and 
            %  resolve-projections of ancillary data to tracer data.  
            %  Subsequently, it requests that the builder construct kinetics.
            %  @param named 'roisBuild' is an 'mlrois.IRoisBuilder'.
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'roisBuilder', ...
                mlpet.BrainmaskBuilder('sessionData', this.sessionData), ...
                @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            this.result_ = mlraichle.HyperglycemiaResults(varargin{:});
            %this.builder_ = this.builder_.resolveRoisOnTracer(varargin{:});
            %this.builder_ = this.builder_.instanceConstructKinetics(varargin{:});
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end 

