classdef TracerDirector < mlpet.AbstractTracerDirector
	%% TRACERDIRECTOR  

	%  $Revision$
 	%  was created 01-Jan-2017 19:29:04
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John J. Lee.
 	

	properties (Constant)
        MAX_LENGTH_EPOCH_AC = 32
        NUM_VISITS = 3
    end
    
	properties (Dependent)
        anatomy
        builder
        sessionData
        studyData
    end
    
    methods (Static)
        %% factory methods 
        
        function this  = constructRemotely(varargin)
            %% CONSTRUCTREMOTELY is a creator/producer:  TracerDirector factoryMethod -> TracerDirector.
            %  @param chpc is an mldistcomp.CHPC object.
            %  @param factoryMethod is from some TracerDirector.
            %  @param factorArgs is cell array for factoryMethod.
            %  @return invokes chpc.pushData.
            %  @return this is the TracerDirector instance deployed which can continue management of its assigned
            %  builders.
            
            ip = inputParser;
            addRequired( ip, 'chpc',            @(x) isa(x, 'mldistcomp.CHPC'));
            addParameter(ip, 'factoryMethod',   @(x) isa(x, 'function_handle'));
            addParameter(ip, 'factoryArgs', {}, @iscell);
            addParameter(ip, 'nArgout', 0,      @isnumeric);
            parse(ip, varargin{:});
            chpc = ip.Results.chpc;
            
            chpc = chpc.pushData;
            chpc = chpc.runSerialProgram(ip.Results.factoryMethod, ip.Results.factoryArgs, ip.Results.nArgout);
            %chpc = chpc.pullData;
            this = chpc.theDeployedDirector; % TracerDirector instance deployed by factoryMethod
            assert(isa(this, 'mlpet.TracerDirector'));
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
        
 		function this = TracerDirector(varargin)
 			%% TRACERDIRECTOR
 			%  @param builder must be an mlpet.TracerBuilder
            
            ip = inputParser;
            addRequired(ip, 'builder', @(x) isa(x, 'mlpet.TracerBuilder'));
            addParamter(ip, 'anatomy', 'T1', @ischar);
            parse(ip, varargin{:});
            
            this.builder_ = ip.Results.builder;
            this.anatomy_ = ip.Results.anatomy;
        end
 	end 

    
    %% PROTECTED
    
    properties (Access = protected)
        anatomy_
        builder_
    end
    
    methods (Access = protected)
        function         instanceCleanTracerRemotely(this, varargin)
            %  @param named distcompHost is the hostname or distcomp profile.
            
            ip = inputParser;
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            parse(ip, varargin{:});
            
            try
                chpc = mlpet.CHPC4TracerDirector( ...
                    this, 'distcompHost', ip.Results.distcompHost, 'sessionData', this.sessionData);                
                chpc.cleanTracer;
            catch ME
                handwarning(ME);
            end
        end        
        
        function this  = instanceConstructResolved(this)
            if (~this.sessionData.attenuationCorrected)
                this = this.instanceConstructResolvedNAC;
                return
            end
            this = this.instanceConstructResolvedAC;
        end
        function that  = instanceConstructResolvedRemotely(this, varargin)
            %  @param sessionData   is a function_handle to an mlpipeline.SessionData ctor.
            %  @param construct     is a function_handle to some implemented factory method.  
            %  @param named dirTool is an mlsystem.DirTool.
            %  @param named distcompHost is the hostname or distcomp profile.
            %  @return this, a cell-array of TracerDirector instances of size N{sessions} x NUM_VISITS.
            
            ip = inputParser;
            addRequired( ip, 'sessionData',  @(x) isa(x, 'function_handle'));
            addRequired( ip, 'construct',    @(x) isa(x, 'function_handle'));
            addParameter(ip, 'nArgout', 1,   @isnumeric);
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
            parse(ip, varargin{:});
            
            import mlpet.*;
            try
                sessd = ip.Results.sessionData( ...
                    'studyData',   this.studyData, ...
                    'sessionPath', this.sessionData.sessionPath, ...
                    'vnumber',     this.sessionData.vnumber, ...
                    'tracer',      this.sessionData.tracer, ...
                    'ac',          this.sessionData.attenuationCorrected, ...
                    'frame',       this.sessionData.frame);
                this.sessionData = sessd;
                %this = this.locallyStageTracer;
                csessd = ip.Results.sessionData( ...
                    'studyData',   this.studyData, ...
                    'sessionPath', mldistcomp.CHPC.repSubjectsDir(this.sessionData.sessionPath), ...
                    'vnumber',     this.sessionData.vnumber, ...
                    'tracer',      this.sessionData.tracer, ...
                    'ac',          this.sessionData.attenuationCorrected, ...
                    'frame',       this.sessionData.frame);
                chpc = CHPC4TracerDirector(this, 'distcompHost', ip.Results.distcompHost, 'sessionData', sessd);
                that = TracerDirector.constructRemotely( ...
                    chpc, ...
                    'factoryMethod', ip.Results.construct, ...
                    'factoryArgs', {'sessionData', csessd}, ...
                    'nArgout', ip.Results.nArgout);
            catch ME
                handwarning(ME);
            end
        end
        function this  = instanceConstructResolveReports(this)   
            this.builder_.maxLengthEpoch = this.MAX_LENGTH_EPOCH_AC;
            this.builder_.sessionData.attenuationCorrected = true; % KLUDGE
            this.builder_.sessionData.rnumber = 2;
            this.builder_ = this.builder_.reportResolved;
        end
        function this  = instanceConstructAnatomy(this, varargin)
            %% INSTANCECONSTRUCTANATOMY
            %  @param valid alignment results this.tracerResolvedFinalSumt.
            %  @param this.sessionData.{T1,aparcAseg,wmparc}.
            %  @param this.anatomy is char for image space equal-sized to T1.
            %  @result ready-to-use t4 transformation files named {T1001,brainmask}r1r2_to_op_fdgv1r1_t4 and 
            %  anatomical files aligned to this.tracerResolvedFinalSumt for FDG.
            
            [~,ic] = this.tracerResolvedFinalSumt(varargin{:});
            this.builder_ = this.builder_.prepareProduct(ic);
            pwd0 = pushd(ic.filepath);
            this.builder_.buildVisitor.lns_4dfp(this.sessionData.(this.anatomy)('typ','fqfp'));
            this.builder_.locallyStageParcs;
            this.builder_ = this.builder_.resolveModalitiesToTracer({this.sessionData.(this.anatomy)('typ','fp')});
            cRB = this.builder_.compositeResolveBuilder;
            cRB = cRB.t4img_4dfp( ...
               sprintf('%sr0_to_%s_t4', this.sessionData.(this.anatomy)('typ','fp'), cRB.resolveTag), ...
               this.sessionData.aparcAseg('typ','fp'), ...
               'out', [this.sessionData.aparcAseg('typ','fp') '_' cRB.resolveTag], ...
               'options', sprintf('-n -O%s', ic.fileprefix));
            cRB.t4img_4dfp( ...
               sprintf('%sr0_to_%s_t4', this.sessionData.(this.anatomy)('typ','fp'), cRB.resolveTag), ...
               this.sessionData.wmparc('typ','fp'), ...
               'out', [this.sessionData.wmparc('typ','fp') '_' cRB.resolveTag], ...
               'options', sprintf('-n -O%s', ic.fileprefix));
            %this.builder_.compositeResolveBuilder = cRB;
            popd(pwd0);
            try 
                deleteExisting('*_b15.4dfp.*');
            catch ME
                handwarning(ME);
            end
        end
        function this  = instanceConstructExports(this, varargin)
            %% INSTANCECONSTRUCTEXPORTS creates symbolic links of useful results in directory named export.
            %  @return fullfile(sessionData.vLocation, export) with aligned tracer results and aligned anatomical results.
            
            sessd = this.sessionData;
            exportDir = fullfile(sessd.vLocation, 'export');
            if (isdir(exportDir))
                return
            end
            mkdir(exportDir);
            pwd0 = pushd(exportDir);
            bv = this.builder_.buildVisitor;
            bv.lns_4dfp(sessd.tracerResolvedFinal('typ','fqfp'));
            bv.lns_4dfp(fullfile(sessd.tracerLocation, [sessd.(this.anatomy)('typ','fp') 'r2_' sessd.resolveTag]));
            bv.lns_4dfp(fullfile(sessd.tracerLocation, ['wmparc_' sessd.resolveTag]));
            bv.lns_4dfp(fullfile(sessd.tracerLocation, ['aparc+aseg_' sessd.resolveTag]));
            bv.lns(     fullfile(sessd.tracerLocation, sprintf('T1001r1r2_to_%s_t4', sessd.resolveTag)));
            popd(pwd0);
        end
        function this  = instanceConstructResolvedTof(this, varargin)
            [~,ic] = this.tracerResolvedFinalSumt(varargin{:});
            this.builder_ = this.builder_.prepareProduct(ic);
            pwd0 = pushd(ic.filepath);
            this.builder_.buildVisitor.lns_4dfp(this.sessionData.tof('typ','fqfp'));
            this.builder_.buildVisitor.lns_4dfp(fullfile(this.sessionData.vLocation, 'ctMaskedOnT1001r2_op_T1001'));
            this.builder_.buildVisitor.lns_4dfp(this.sessionData.T1('typ','fqfp'));
            this.builder_.buildVisitor.lns_4dfp(this.sessionData.t2('typ','fqfp'));
            tof = this.builder_.resolveTofToT1;
            this.builder_ = this.builder_.resolveModalitiesToTracer( ...
                {tof ...
                 'ctMaskedOnT1001r2_op_T1001' ...
                 this.sessionData.T1('typ','fp') ...
                 this.sessionData.t2('typ','fp')});
            popd(pwd0);
        end
        function obj   = tracerResolvedFinal(this, varargin)
            sessd = this.sessionData;
            sessd.attenuationCorrected = true;
            sessd.rnumber = 2;
            obj = sessd.tracerResolvedFinal(varargin{:});
        end
        function [obj,ic] = tracerResolvedFinalSumt(this, varargin)  
            %  @param named resolvedFrame is numeric, corresponding to frame of reconstituted epochs, e.g., e1to3;
            %  consider alternative values when final registrations are poor.
            
            sessd = this.sessionData;
            sessd.attenuationCorrected = true;
            sessd.rnumber = 2;
            obj = sessd.tracerResolvedFinalSumt(varargin{:});            
            if (lexist(sessd.tracerResolvedFinalSumt, 'file'))
                ic  = sessd.tracerResolvedFinalSumt(varargin{:}, 'typ', 'mlfourd.ImagingContext');
            else
                ic  = this.tracerResolvedFinal('epoch', this.sessionData.epoch, varargin{:}, 'typ', 'mlfourd.ImagingContext');
                ic.numericalNiftid;
                ic  = ic.timeSummed;
                ic.fourdfp;
                ic.save;
            end
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
            
            pwd0 = sessd.petLocation;
            ensuredir(pwd0);
            pushd(pwd0);
            bmb = mlpet.BrainmaskBuilder('sessionData', sessd);
            [~,ct4rb] = bmb.brainmaskBinarized( ...
                'tracer', this.sessionData.tracerRevisionSumt('typ', 'mlfourd.ImagingContext'));
            aab = bmb.aparcAsegBinarized(ct4rb);
            popd(pwd0);
        end        
        function this = instanceConstructKinetics(this, varargin)   
            %% INSTANCECONSTRUCTKINETICS requests that the builder prepare filesystems, coregistrations and 
            %  resolve-projections of ancillary data to tracer data.  
            %  Subsequently, it requests that the builder construct kinetics.
            %  @param named 'roisBuild' is an 'mlrois.IRoisBuilder'.
            
            ip = inputParser;
            ip.KeepUnmatched;
            addParameter(ip, 'roisBuild', ...
                mlpet.BrainmaskBuilder('sessionData', this.sessionData), ...
                @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            this.builder_ = this.builder_.resolveRoisOnTracer(varargin{:});
            this.builder_ = this.builder_.instanceConstructKinetics(varargin{:});
        end
        function tf   = constructKineticsPassed(this, varargin)
            %% CONSTRUCTKINETICSPASSED
            %  @param named 'roisBuild' is an 'mlrois.IRoisBuilder'.
            %  @returns tf logical.
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            tf = this.builder_.constructKineticsPassed(varargin{:});
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
        
        function list  = instanceListUmaps(this)
            dt = mlsystem.DirTool([this.sessionData.umapSynth('tracer', '', 'typ', '.4dfp.ifh') '*']);
            list = dt.fqfns;
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
            addParameter(ip, 'distcompHost', 'chpc_remote_r2016a', @ischar);
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
                    fullfile(csessd.tracerLocation, ip.Results.pattern), ...
                    sessd.tracerLocation, ...
                    'chpcIsSource', true); %#ok<ASGLU>
            catch ME
                fprintf('s->%i, r->%s\n', s, r);
                handwarning(ME);
            end
        end
    end
    
    %% PRIVATE
    
    methods (Access = private)        
        function this  = instanceConstructResolvedAC(this)
            this.builder_ = this.builder_.reconstituteFramesAC;
            this.sessionData.frame = nan;
            this.builder_.sessionData.frame = nan;
            this.builder_.maxLengthEpoch = this.MAX_LENGTH_EPOCH_AC; % must run after this.builder_.reconstituteFramesAC
            this.builder_ = this.builder_.partitionMonolith;
            this.builder_ = this.builder_.motionCorrectFrames;            
            this.builder_ = this.builder_.reconstituteFramesAC2;
        end
        function this  = instanceConstructResolvedNAC(this)
            this.builder_       = this.builder_.locallyStageTracer;            
            this.builder_       = this.builder_.partitionMonolith; 
            [this.builder_,multiEpochOfSummed,reconstitutedSummed] = this.builder_.motionCorrectFrames;
            reconstitutedSummed = reconstitutedSummed.motionCorrectCTAndUmap;             
            this.builder_       = reconstitutedSummed.motionUncorrectUmap(multiEpochOfSummed);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end 

