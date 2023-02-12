classdef TracerResolveBuilder < mlpet.TracerBuilder
	%% TRACERRESOLVEBUILDER can create t4-resolved images hierarchically ordered using cardinalities
    %  |session| >= |visit| >  |tracer-monolith|;
    %  |frame|   >= |epoch| >= |tracer-monolith|.  
    %  Construction intermediates are stored in this.product as specified by the builder design pattern.  
    %  TO DO:  refactor to extract classes for variable NRevision; then use strategy pattern.

	%  $Revision$
 	%  was created 18-Aug-2017 13:57:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
    
    properties (Constant)
        FULL_FOV = [344 344 127]
    end
    
    properties
        f2rep % use to exclude early frames of OC, OO that have breathing tube in FOV
        fsrc  %
    end    
    
    properties (Dependent)
        imgblurTag
        maskForImagesForT4RB
        nFramesAC
        tauFramesNAC
    end

	methods 
        
        %% GET
        
        function g = get.imgblurTag(this)
            g = this.sessionData_.petPointSpread('tag_imgblur_4dfp', true);
        end
        function g = get.maskForImagesForT4RB(this)
            if (~this.sessionData.attenuationCorrected)
                g = 'wholehead2';
            else
                g = 'Msktgen';
            end
        end
        function g = get.nFramesAC(this)
            g = length(this.sessionData.taus);
        end
        function g = get.tauFramesNAC(this)
            g = this.sessionData.taus;
            assert(~isempty(this.product));
            sizeProd = size(this.product);
            g = g(1:sizeProd(4));
        end
        
        %% Common sequential building behaviors
        
        function [this,mono] = partitionMonolith(this)
            %% PARTITIONMONOLITH partitions monolithic tracerRevision into a composite of TracerResolveBuilders.
            %  @param  this.tracerRevision exists.
            %  @param  this.maxLengthEpoch is integer > 0.  
            %  @return this unchanged and mono := this if rank(monolith) < 4.
            %  @return this := composite of TracerResolveBuilder with partitioning of monolith into epochs with  
            %          |epoch| <= this.maxLengthEpoch.  It saves epochs if they are not already on the filesystem.  
            %          |this| := ceil(this.sizeTracerRevision/this.maxLengthEpoch).
            %  @return this(...) as determined by this.nEpochs_ and this.saveEpoch(this.partitionEpochFrames).
            %  @return mono := struct('sessionData',,'imagingContext',}, which contains the pre-partitioning state  
            %          for later use.
            %  See also:  mlpipeline.CompositeBuilder.
            
            sz = this.sizeTracerRevision;
            if (length(sz) < 4 || 1 == sz(4))
                mono = this;
                return
            end
            
            import mlfourd.*;
            if (sz(4) > this.maxLengthEpoch)
                this_               = this;
                mono.sessionData    = this_.sessionData;
                mono.imagingContext = ImagingContext2(this_.tracerRevision); 
                this_.nEpochs_      = ceil(sz(4)/this_.maxLengthEpoch);
                for e = 1:this_.nEpochs_
                    this(e) = this_;
                    this(e).sessionData_.epoch = e;
                    ice = ImagingContext2(this(e).tracerRevision);
                    if (~lexist_4dfp(ice.fqfileprefix))
                        ensuredir(ice.filepath);
                        this(e) = this(e).saveEpoch(this_, mono.imagingContext.fourdfp);
                    else
                        this(e).product_ = ice;
                    end
                end
            end
        end
        function [this,epochs,reconstituted] = motionCorrectFrames(this)
            %% MOTIONCORRECTFRAMES performs spatial normalization of time-resolved images using divide-and-conquer.  
            %  Recurrences have form T(n) = e T(n/e) + f(n), for n frames and e epochs, an epoch being a subset of 
            %  frames determined by partitionMonolith; f(n) is the time for divide and conquer steps.  
            %  See also TracerResolveBuilder.partitionMonolith, TracerResolveBuilder.motionCorrectEpochs.
            %
            %  @param  this := composite of TracerResolveBuilder, each element containing an epoch of frame subsets
            %          typically provided by partitionMonolith.
            %  @param  this.product := composite multi-epoch of frames created by partitionMonolith.
            %  @return this := composite epochs of TracerResolveBuilder, each epoch containing motion-corrected frames.            %          
            %  @return epochs := composite epochs of TracerResolveBuilder, each containing summed motion-corrected frames.         
            %  @return reconstituted := singlet ImagingFormatContext2 containing time sum of motion-corrected frames.
                
            % recursion over epochs to generate composite
            if (length(this) > 1)
                for e = 1:length(this)
                    this(e) = this(e).setLogPath( ...
                        fullfile(myfileparts(this(e).tracerRevision), 'Log', ''));
                    [this(e),~,epochs(e)] = this(e).motionCorrectFrames; 
                end
                epoch1 = epochs(1);
                epoch1 = epoch1.reconstituteComposites(epochs);
                [this,reconstituted] = epoch1.motionCorrectEpochs;
                return
            end
            
            % base case; returns singlet
            this.product_ = mlfourd.ImagingContext2(this.tracerRevision);
            epochs = [];
            [this,reconstituted] = this.motionCorrectEpochs; 
        end
        function this = motionCorrectCTAndUmap(this)
            %% MOTIONCORRECTCTANDUMAP
            %  @param  this.sessionData is well-formed for the problem.
            %  @param  this.product is a single-epoch motion-corrected tracer.
            %          e.g., after completing this.motionCorrectFrames, 
            %          reconstitutedSummed.product := E1to9/fdgv1e1to9r2_op_fdgv1e1to9r1_frame9_sumt &&
            %          this := reconstitutedSummed.
            %  @return motion-corrections of umapSynth, T1, t2 onto this.product for 
            %          this.{compositeResolveBuilder,sessionData,product};
            %          e.g., this.product := umapSynth_to_op_fdgv1e1to9r1_frame9.
            
            pwd0 = pushd(this.product_.filepath);      
            this.locallyStageModalities( ...
                'fourdfp', this.sessionData.umapSynthOpT1001('typ', 'fqfp'));
            this.sessionData_.rnumber = 1;
            prodfp = this.product_.fileprefix;
            try
                switch (this.sessionData_.tracer)
                    case  'OO'
                        %sessHo  = this.recallOtherTracerResolvedFinalAvgt('HO');
                        %sessFdg = this.recallOtherTracerResolvedFinalAvgt('FDG');                               
                        %sessHo.tracerResolvedFinalAvgt('typ','fp') ...
                        %sessFdg.tracerResolvedFinalAvgt('typ','fp') ...
                        %'Msktgen' 'Msktgen'
                        imgs = {prodfp ... 
                                this.T1('typ', 'fp') ...
                                this.sessionData.umapSynthOpT1001('typ', 'fp')};  
                        msks = {'Msktgen' 'T1001' 'none'}; 
                        cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                              'sessionData', this.sessionData_, ...
                              'theImages', imgs, ...
                              'blurArg', 6.5, ...
                              'maskForImages', msks, ...
                              'NRevisions', 1);
                        cRB_ = cRB_.resolve;
                    case {'HO' 'OC'}
                        %sessFdg = this.recallOtherTracerResolvedFinalAvgt('FDG');
                        %sessFdg.tracerResolvedFinalAvgt('typ','fp') ...
                        imgs = {prodfp ... 
                                this.T1('typ', 'fp') ...
                                this.sessionData.umapSynthOpT1001('typ', 'fp')};
                        msks = {'Msktgen' 'T1001' 'none'};
                        cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                              'sessionData', this.sessionData_, ...
                              'theImages', imgs, ...
                              'blurArg', 6.5, ...
                              'maskForImages', msks, ...
                              'NRevisions', 1);
                        cRB_ = cRB_.resolve;
                    case 'FDG'
                        imgs = {prodfp ... 
                                     this.T1('typ', 'fp') ...
                                     this.sessionData.umapSynthOpT1001('typ', 'fp')};
                        cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                            'sessionData', this.sessionData_, ...
                            'theImages', imgs, ...
                            'blurArg', 4.3, ...
                            'maskForImages', {'Msktgen' 'T1001' 'none'}, ...
                            'NRevisions', 1);                    
                        cRB_ = cRB_.resolve;
                    otherwise
                        error('mlpet:IndexError', ...
                              'TracerResolveBuilder.motionCorrectCTAndUmap has no switch case for tracer->%s', ...
                              this.sessionData_.tracer);
                end
            catch ME
                if (strcmp(ME.identifier, 'mlfourdfp:abnormalExit'))
                    imgs = {prodfp this.sessionData.umapSynthOpT1001('typ', 'fp')};
                    msks = {'none' 'none'};
                    cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                        'sessionData', this.sessionData_, ...
                        'theImages', imgs, ...
                        'blurArg', 8.6, ...
                        'maskForImages', msks, ...
                        'NRevisions', 1); 
                    cRB_ = cRB_.resolve;
                else
                    rethrow(ME)
                end
            end
                        
            % update this.{compositeResolveBuilder_,sessionData_,product_}   
            cRB_ = this.reconcileUmapFilenames(cRB_);
            this.compositeResolveBuilder_ = cRB_;
            this.sessionData_             = cRB_.sessionData;
            this.product_                 = cRB_.product;      
            this.product_.fourdfp;
            popd(pwd0);
        end
        function this = motionUncorrectUmap(this, multiEpochOfSummed)
            %% MOTIONUNCORRECTUMAP
            %  @param this.motionCorrectCTAndUmap has completed successfully with motion-corrected umap 
            %  contained in this.product; e.g., umapSynth_to_op_fdgv1e1to9r1_frame9
            %  @param parent ~fdgv1e1to9r2_op_fdgv1e1to9r1_frame9
            %  @return this.product := this.umapSynth back-resolved to all original frames of tracer monolith.
            
            umapOnFrameEnd = this.product; % e.g., E1to9/umapSynth_op_fdgv1e1to9r1.4dfp.hdr
            this.assertUmap(umapOnFrameEnd);
            this.motionUncorrectToFrames(umapOnFrameEnd, multiEpochOfSummed);
            
        end
        function this = aufbauUmaps(this)
            %% AUFBAUUMAPS collects individual umaps resolved back to original NAC frames.
            
            this.sessionData.epoch = [];
            loc = this.sessionData.tracerLocation;
            ensuredir(loc);
            cd(loc);
            this = this.aufbauUmap;
            this = this.expandFovOfUmap;
            this = this.loadReconHistIntoUmap;
        end        
        function this = reconstituteFramesAC(this)
            %% RECONSTITUTEACFRAMES uses e7 results referenced by this.sessionData.tracerListmodeMhdr.
            %  It crops frames and concatenates frames.  Since some of the tracerListmodeMhdr may be multiframed,
            %  the resulting reconstituted frames may have more frames than the number of instances of
            %  tracerListmodeMhdr.  
            %  @param this.sessionData.tracerConvertedLocation has form ~FDG_V1-Converted-Frame${i}-AC.
            %  @param this.sessionData.tracerListmodeFrameV has form ~FDG_V1-LM-00/FDG_V1-OM-00-OP-00${j}-000.v.
            %         i and j have C-indexing.
            %  @param this.sessionData.tracerListmodeMhdr has form ~FDG_V1-LM-00/FDG_V1-OM-00-OP.mhdr.
            %  @return in this.product all frames and sub-frames reconstituted into file this.sessionData.tracerRevision
            %          ~FDG_V1-AC/fdgv1r1.
            %  @return this.sessionData.rnumber := 1.
                   
            assert(this.sessionData_.attenuationCorrected);  
            ensuredir(this.sessionData_.tracerLocation);
            
            if (lexist(this.sessionData_.tracerRevision, 'file'))
                % update this.{sessionData_,product_}
                this.sessionData_.rnumber = 1; 
                this.product_ = mlfourd.ImagingContext2(this.sessionData_.tracerRevision);
                return
            end  
            
            %% create this.sessionData_.tracerRevision
            
            this.sessionData_.frame = 0;
            aufbau = this.reconstituteFrame(this.sessionData_, 0);
            aufbau.fqfilename = this.sessionData_.tracerRevision;
            assert(4 == length(aufbau.size) && aufbau.size(4) > 0);
            innerf = size(aufbau, 4);
            this.sessionData_.frame = 1;
            while (isfolder(this.sessionData_.tracerConvertedLocation))

                pwd0 = pushd(this.sessionData_.tracerLocation);
                fprintf('mlpet.TracerResolveBuilder.reconstituteFramesAC.this.sessionData_.tracerConvertedLocation -> \n%s\n', ...
                    this.sessionData_.tracerConvertedLocation);
                ffp = this.reconstituteFrame( ...
                    this.sessionData_, ...
                    this.sessionData_.frame, ...
                    'fqfp', this.sessionData_.tracerRevision('frame', this.sessionData_.frame, 'typ', 'fqfp'));
                ffp = this.t4imgFromNac(ffp, this.nFramesAC);
                if (ffp.rank < 4)
                    innerf = innerf + 1;
                    aufbau.img(:,:,:,innerf) = ffp.img;
                else
                    for t = 1:ffp.size(4)   
                        innerf = innerf + 1;
                        aufbau.img(:,:,:,innerf) = ffp.img(:,:,:,t);
                    end
                end                
                this.sessionData_.frame = this.sessionData_.frame + 1; 
                popd(pwd0);
            end    
            
            % update this.{sessionData_,product_}
            this.sessionData_.rnumber = 1;
            aufbau.img = double(aufbau.img);
            aufbau = this.applyTauMultiplier(aufbau);
            aufbau.save;
            this = this.packageProduct(aufbau);
        end	
        function this = reconstituteFramesAC2(this)
            %% uses previously resampled frames, applied additional t4 as needed
            
            import mlfourdfp.* mlfourd.*;            
            nFrames = this.nFramesAC;
            nEpochs = floor(nFrames/this.maxLengthEpoch);
            supEpochs = ceil(nFrames/this.maxLengthEpoch);
            
            assert(1 == this.sessionData.rnumber);            
            sessdr2e1toN = this.sessionData;
            sessdr2e1toN.epoch = 1:supEpochs;
            sessdr2e1toN.frame = supEpochs;
            sessdr2e1toN.resolveTag = sprintf('%s_frame%i', sessdr2e1toN.resolveTag, supEpochs);
            sessdr2e1toN.rnumber = 2;
            sessdr2 = this.sessionData;
            sessdr2.resolveTag = sessdr2e1toN.resolveTag;
            sessdr2.rnumber = 2;
            sessdr1 = this.sessionData;
            sessdr1.resolveTag = sessdr2e1toN.resolveTag;
            
            pwd0 = pushd(sessdr2.tracerLocation);
            ffp0 = ImagingFormatContext2(sessdr1.tracerRevision('typ', 'fqfn'));
            ffp0.img = zeros(size(ffp0));
            ffp0.fqfileprefix = sessdr2.tracerResolved('typ', 'fqfp'); % fdgv1r2_op_fdgv1e1to4r1_frame4
            
            %% only epochs of length this.maxLengthEpoch
            
            inz = this.indicesNonzero;
            for e = 1:nEpochs  
                if (0 == sum(inz((e-1)*this.maxLengthEpoch+1:e*this.maxLengthEpoch))) % skip empty epoch
                    continue
                end
                sessde = sessdr2;
                sessde.epoch = e;
                sessde.resolveTag = sprintf('op_%sr1_frame%i', sessde.tracerEpoch('typ','fp'), this.maxLengthEpoch);                
                pwd1 = pushd(sessde.tracerLocation);              
                t4 = this.t4ForReconstituteFramesAC2(e, sessdr2e1toN); % /data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V2/FDG_V2-AC/E1to4/fdgv1e1to4r1r2_frame1_to_op_fdgv1e1to4r1_frame4_t4
                fp = sessde.tracerResolved('typ', 'fp'); % fdgv1e1r2_op_fdgv1e1r1_frame24, previously RESAMPLED
                fpDest = [sessde.tracerRevision('typ','fp') '_' sessdr2e1toN.resolveTag]; % fdgv1e1r2_op_fdgv1e1to4r1_frame4
                if (lexist(t4, 'file'))
                    this.buildVisitor.t4img_4dfp(t4, fp, 'out', fpDest, 'options', ['-O' fp]);
                    ffp = ImagingFormatContext2([fpDest '.4dfp.hdr']);
                else
                    % e.g., for case in which most of epoch 1 is empty because of late
                    % dose administration
                    ffp = ImagingFormatContext2([fp '.4dfp.hdr']);
                end
                ffp0.img(:,:,:,(e-1)*this.maxLengthEpoch+1:e*this.maxLengthEpoch) = ffp.img; % FDG_V1-AC/fdgv1r2_op_fdgv1e1to4r1_frame4.4dfp.hdr
                popd(pwd1);
            end
            
            %% last epoch, length <= this.maxLengthEpoch
            
            e = supEpochs;
            sessde = sessdr2;
            sessde.epoch = e;
            pwd1 = pushd(sessde.tracerLocation);      
            remainingFrames = (e-1)*this.maxLengthEpoch+1:nFrames; % vector
            if (1 == length(remainingFrames)) 
                
                % single frame remaining
                fp = sprintf('%sr1', sessde.tracerEpoch('typ','fp')); % fdgv1e4r1
                ffp = ImagingFormatContext2([fp '.4dfp.hdr']);
                ffp0.img(:,:,:,remainingFrames) = ffp.img;
                popd(pwd1);                
                ffp0.save;
                popd(pwd0);
                this = this.packageProduct(ffp0);
                return
            end
            
            % multi-frames remaining, already in space of E1toN last frame
            fp = sprintf('%s_op_%sr1_frame%i', ...
                sessde.tracerRevision('typ','fp'), ...
                sessde.tracerEpoch('typ','fp'), ...
                nFrames - nEpochs*this.maxLengthEpoch); % fdgv1e4r2_op_fdgv1e4r1_frame1, previously RESAMPLED
            ffp = ImagingFormatContext2([fp '.4dfp.hdr']);
            ffp0.img(:,:,:,remainingFrames) = ffp.img;
            popd(pwd1);            
            ffp0.save;
            popd(pwd0);
            this = this.packageProduct(ffp0);
        end
        function this = reconstituteFramesAC3(this)
            %% prefers composition of t4 files generated by t4_resolve; restricts resampling
            
            resamplingRestricted = mlpet.ResamplingRestrictedResolveBuilder('sessionData', this.sessionData);
            resamplingRestricted.reconstituteFramesAC3
        end
        function        markAsFinished(this, varargin)
            this.finished.markAsFinished(varargin{:});   
        end    
        
        %% Utilities
        
        function this = avgtProduct(this)
            assert(isa(this.product_, 'mlfourd.ImagingContext2'));
            assert(isfile(this.product_.fqfilename))
            AVGT = mlfourd.DynamicsTool.AVGT_SUFFIX;
            if (this.buildVisitor.lexist_4dfp([this.product_.fqfp AVGT]))
                this.product_ = mlfourd.ImagingContext2([this.product_.fqfp AVGT '.4dfp.hdr']);
                return
            end
            sz = this.size_4dfp(this.product_);
            if (length(sz) < 4 || sz(4) == 1)
                return
            end
            this.product_ = this.product_.timeAveraged;
            this.product_.fourdfp;
            this.product_.save; % _avgt
        end
        function this = convertUmapsToE7Format(this)
            sz  = this.sizeTracerRevision;
            fps = cellfun(@(x) sprintf('umapSynth_frame%i', x), num2cell(0:sz(4)-1), 'UniformOutput', false);
            cub = mlfourdfp.CarneyUmapBuilder('sessionData', this.sessionData);
            cub = cub.convertUmapsToE7Format(fps);
            this.product_ = cub.product;
        end
        function this = deleteLastEpoch(this)
            %% is intended for revision of final reconstitution of frames, such as minimizing resampling.
            %  It deletes from this.sessionData.tracerLocation:  
            %  EN, E1toN, <tracer>*, output/PET/<tracer>.*, output/PET/<TRACER>.*
            %  See also constructor parameters.
            
            sessd = this.sessionData;
            EN = sprintf('E%i', sessd.supEpoch);
            E1toN = sprintf('E1to%i', sessd.supEpoch);
            
            pwd0 = pushd(sessd.tracerLocation);
            deleteExisting([lower(sessd.tracer) '*'])
            if isfolder(EN)
                mlbash(sprintf('rm -rf %s', EN))
            end
            if isfolder(E1toN)
                mlbash(sprintf('rm -rf %s', E1toN))
            end
            movefileExisting('*.mat0', 'Log')
            movefileExisting('*.sub', 'Log')
            popd(pwd0)
            
            pwd0 = pushd(fullfile(sessd.tracerLocation, 'output', 'PET', ''));
            if this.singleFrameFolderIsReady('FDG')
                deleteExisting([lower(sessd.tracer) '.*'])
                deleteExisting([upper(sessd.tracer) '.*'])
            end
            popd(pwd0)
        end
        function tf   = singleFrameFolderIsReady(this, tra)
            if strcmpi(this.sessionData.tracer, tra) && ...
                    ~isempty(glob([tra '_DT*.json'])) && ...
                    ~isempty(ls('single-frame'))
                tf = true;
                return
            end
            tf = false;
        end
        function this = deleteWorkFiles(this)
            pwd0 = pushd(this.sessionData.tracerLocation);
            dt = mlsystem.DirTool('E*');
            for idt = 1:length(dt.dns)
                pwd1 = pushd(dt.dns{idt});
                deleteExisting('*.4dfp.ifh');
                deleteExisting('*.4dfp.hdr');
                deleteExisting('*.4dfp.img');
                deleteExisting('*.4dfp.img.rec');
                popd(pwd1);
            end
            ensuredir('Log')
            movefileExisting('*.sub', 'Log')
            movefileExisting('*.mat0', 'Log')
            popd(pwd0);
        end
        function idx  = indicesNonzero(this)
            p = this.product_;
            if (~isa(p, 'mlfourd.ImagingContext2'))
                p = mlfourd.ImagingContext2(p);
            end
            p = p.volumeSummed;
            img = p.fourdfp.img;
            idx = this.indicesNum2bool(img);
            idx = ensureRowVector(idx) & ...
                  ensureRowVector(this.sessionData.indicesLogical);
            this.logger.add('indicesNonzero.img->%s\n', mat2str(img));
            this.logger.add('indicesNonzero.idx->%s\n', mat2str(idx));
        end
        function idx  = indicesNum2bool(this, img)
            assert(isnumeric(img));
            idx = img > this.sessionData.fractionalImageFrameThresh * median(img) + ...
                        mlnipet.NipetRegistry.instance().noiseFloorOfActivity;
        end      
        function [this,averaged] = motionCorrectEpochs(this)
            %% MOTIONCORRECTEPOCHS accepts time-resolved image and returns them with motion-correction.
            %  It also returns the time-sum ofthe motion-corrected frames.
            %
            %  @param  this.product contains a set of frames to motion-correct.
            %  @return this.{resolveBuilder,sessionData,product} := updated motion-correction objects.
            %  @return this.product := ImagingContext of time-resolved motion-corrected frames;
            %          E.g., this.product := files E*/fdgv1e*r2_op_fdgv1e*r1_frame*.
            %  @return averaged := ImagingFormatContext2 with time-average of motion-corrected frames.
            %          E.g., averaged.product := files E*/fdgv1e*r2_op_fdgv1e*r1_frame*_avgt.
            %  @return this unchanged and averaged := this for ndims(sessionData.tracerRevision) < 4.
            
            sz = this.sizeTracerRevision;
            if (length(sz) < 4 || 1 == sz(4)) % Consider:  thisSz(4) == duration of this epoch
                averaged = this;
                return 
            end            
            
            pwd0 = pushd(this.sessionData_.tracerLocation);
            this.logger.add('motionCorrectEpochs will run T4ResolveBuilder on %s', this.product_.fileprefix);
            t4rB_ = mlfourdfp.T4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', this.product_.fqfileprefix, ...
                'indicesLogical', this.indicesNonzero, ...
                'indexOfReference', sz(4), ...
                'maskForImages', this.maskForImagesForT4RB, ...
                'NRevisions', 2, ...
                'resolveTag', this.sessionData_.resolveTagFrame(sz(4), 'reset', true)); 
            
            % update this.{resolveBuilder_,sessionData_,product_}
            t4rB_                = t4rB_.resolve;
            this.resolveBuilder_ = t4rB_;
            this.sessionData_    = t4rB_.sessionData; 
            if isfile(t4rB_.product.fqfilename)
                this.product_ = t4rB_.product;
            else
                error('mlpet:RuntimeError', ...
                    'TracerResolvedBuilder.motionCorrectEpochs:  product %s not found', ...
                    t4rB_.product.fqfilename)
            end
            averaged = this.avgtProduct;
            popd(pwd0);
        end
        function unco = motionUncorrectEpoch(this, source, multiEpochOfSummed, lastEpoch)
            %% MOTIONUNCORRECTEPOCH back-resolves a source in the space of some reference epoch to all available epochs.
            %  Its necessity arises from avoiding use of t4inv operations.  
            %  @param this.resolveBulder.product is the motion-corrected-summed singlet object to which source will align.
            %  @param source is an ImagingContext.
            %  @param lastEpoch is logical.
            %  @return thisUncorrected, a collection of TracerResolveBuilders, each conveying back-resolving
            %  to one of the available epochs.
            
            assert(isa(source, 'mlfourd.ImagingContext2'));
            assert(isa(multiEpochOfSummed, 'mlpet.TracerResolveBuilder'));
            import mlfourd.*;
            
            if ~lastEpoch
                NRef = this.maxLengthEpoch;
            else
                switch this.nFramesModMaxLengthEpoch
                    case 0
                        NRef = this.maxLengthEpoch;
                    case 1
                        unco = this;
                        return
                    otherwise
                        NRef = this.nFramesModMaxLengthEpoch;
                end
            end
            for idxRef = 1:NRef % uncorrect source to each frame as a separate reference frame
                
                %% resolve source to thisMotionUncorrected(idxRef)
                
                try
                    E_idxRef = this.resolveBuilder_.sessionData.tracerLocation;
                    ensuredir(E_idxRef);
                    pwd0 = pushd(E_idxRef); % E1, ..., E8;
                    unco(idxRef) = this; %#ok<*AGROW>
                    childT4RB                  = this.resolveBuilder_;
                    childT4RB.rnumber          = 1;
                    childT4RB.indexOfReference = idxRef;  
                    childT4RB.resolveTag       = childT4RB.resolveTagFrame(idxRef, 'reset', true); % op_fdgv1${e}r1_frame${idxRef};                      
                    childT4RB                  = childT4RB.updateFinished( ...
                        'tag', sprintf('_motionUncorrectEpoch_%s_idxRef%i', source.fileprefix, idxRef));
                    
                    childT4RB.skipT4imgAll = true;
                    childT4RB              = childT4RB.resolve; % childRB.product->${E}/fdgv1${e}r2_op_fdgv1${e}r1_frame${idxRef}
                    childT4RB.skipT4imgAll = false;                    
                    parentToChildT4_       = multiEpochOfSummed.parentToChildT4(childT4RB.resolveTag);
                    if (childT4RB.indicesLogical(idxRef))
                        childT4RB          = childT4RB.t4img_4dfp( ...
                            parentToChildT4_, ...
                            source.fqfileprefix, ...
                            'out', childT4RB.umapTagged(childT4RB.resolveTag, 'typ', 'fp'), ...
                            'options', ['-O' this.sessionData.tracerResolved('typ','fp')]);
                            % t4     := ${E}/fdgv1${e}r0_frame8_to_op_fdgv1${e}r1_frame${idxRef}_t4; 
                            % source := E1to9/umapSynth_op_fdgv1e1to9r1_frame${e};          
                            % out    :=       umapSynth_op_fdgv1${e}r1_frame${idxRef}  
                            
                        childT4RB.theImages = childT4RB.tracerRevision('typ', 'fqfp');
                    else
                        childT4RB.buildVisitor.copyfile_4dfp( ...
                            source.fqfileprefix, ...
                            childT4RB.umapTagged(childT4RB.resolveTag, 'typ', 'fp'));
                        childT4RB.rnumber = 1;
                        childT4RB.theImages = childT4RB.tracerRevision('typ', 'fqfp');
                    end  
                    childT4RB.epoch = idxRef;
                    
                    %% update thisMotionUncorrected(idxRef).{resolveBuilder_,sessionData_,product_}
                
                    unco(idxRef).resolveBuilder_ = childT4RB; 
                    unco(idxRef).sessionData_    = childT4RB.sessionData;                                    
                    unco(idxRef).product_        = ImagingContext2(this.resolveBuilder_.umapTagged(childT4RB.resolveTag)); % ~ childRB.product;  
                    
                    fprintf('motionUncorrectEpoch:\n');
                    fprintf('source.fqfileprefix->\n    %s\n', source.fqfileprefix); 
                        % E1to9/umapSynth_op_fdgv1e1to9r1_frame${e}; 
                    fprintf('this(%i).product->\n    %s\n\n', idxRef, unco(idxRef).product.fqfileprefix); 
                        % E${idxRef}/umapSynth_op_fdgv1e1to9r1_frame${idxRef};                 
                    popd(pwd0);
                    
                catch ME
                    if (strcmp('mlfourdfp:IOErr:fileNotFound', ME.identifier))
                        % e.g., all frames of epoch are empty except for last so no t4_resolve was done for the epoch
                        childT4RB.buildVisitor.copyfile_4dfp( ...
                            source.fqfileprefix, ...
                            childT4RB.umapTagged(childT4RB.resolveTag, 'typ', 'fp'));
                    else
                        dispexcept(ME, 'mlpet:RuntimeError', ...
                            'TracerResolveBuilder.motionUncorrectEpoch failed resolve or t4img_4dfp on %s', ...
                            source.fqfilename);
                    end
                    % E1to9 && idxRef->9 will fail with 
                    % Warning: The value of 'tracerSif' is invalid. It must satisfy the function: lexist_4dfp.
                    % Cf. mlfourdfp.ImageFrames lines 154, 173.  TODO.
                    % file: /home/usr/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp/ImageFrames.m; name: ImageFrames.readLength; line: 155; 
                    % file: /home/usr/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp/ImageFrames.m; name: ImageFrames.set.theImages; line: 54; 
                    % file: /home/usr/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp/AbstractT4ResolveBuilder.m; name: AbstractT4ResolveBuilder.set.theImages; line: 164; 
                    % file: /home/usr/jjlee/Local/src/mlcvl/mlpet/src/+mlpet/TracerResolveBuilder.m; name: TracerResolveBuilder.motionUncorrectUmapToEpochs; line: 235; 
                    % file: /home/usr/jjlee/Local/src/mlcvl/mlpet/src/+mlpet/TracerResolveBuilder.m; name: TracerResolveBuilder.motionUncorrectUmapToFrames; line: 184; 
                end
            end
        end     
        function unco = motionUncorrectEpoch1ToN(this, source, multiEpochOfSummed)
            %% MOTIONUNCORRECTEPOCH1TON back-resolves a source in the space of some reference epoch to all available epochs.
            %  Its necessity arises from avoiding use of t4inv operations.  
            %  @param this.resolveBulder.product is the motion-corrected-summed singlet object to which source will align.
            %  @param source is an ImagingContext.
            %  @return thisUncorrected, a collection of TracerResolveBuilders for E1to9, each conveying back-resolving
            %  to one of the other available epochs.  thisUncorrected is never back-resolved to itself so
            %  length(thisUncorrected) = length(multiEpochOfSummed) - 1.
            
            assert(isa(source, 'mlfourd.ImagingContext2'));
            assert(isa(multiEpochOfSummed, 'mlpet.TracerResolveBuilder'));
            import mlfourd.*;
            
            for idxRef = 1:length(multiEpochOfSummed)
                
                %% resolve source to thisUncorrected(idxRef)
                loc = this.resolveBuilder_.sessionData.tracerLocation;
                ensuredir(loc);
                pwd0 = pushd(loc); % E1to9;    
                unco(idxRef) = this; %#ok<*AGROW>       
%                if (idxRef == this.resolveBuilder_.indexOfReference)
%                    continue
%                end  
                try
                    childT4RB                  = this.resolveBuilder_;
                    childT4RB.rnumber          = 1;
                    childT4RB.indexOfReference = idxRef;  
                    childT4RB.resolveTag       = childT4RB.resolveTagFrame(idxRef, 'reset', true); % op_fdgv1e1to9r1_frame${idxRef};                      
                    childT4RB                  = childT4RB.updateFinished( ...
                        'tag', sprintf('_motionUncorrectEpoch1ToN_%s_idxRef%i', source.fileprefix, idxRef));
                    
                    childT4RB.skipT4imgAll = true;
                    childT4RB              = childT4RB.resolve; % childRB.product->${E}/fdgv2${e}r2_op_fdgv2${e}r1_frame${idxRef}
                    childT4RB.skipT4imgAll = false;                    
                    childT4RB              = childT4RB.t4img_4dfp( ...
                        this.parentToChildT4(childT4RB.resolveTag), ...
                        source.fqfileprefix, ...
                        'out', childT4RB.umapTagged(childT4RB.resolveTag, 'typ', 'fp'), ...
                        'options', ['-O' this.sessionData.tracerResolved('typ','fp')]);
                        % t4     := E1to9/fdgv1e1to9r0_frame9_to_op_fdgv1e1to9r1_frame${idxRef}_t4; 
                        % source := E1to9/umapSynth_op_fdgv1e1to9r1_frame9;                         
                        % out    :=       umapSynth_op_fdgv1e1to9r1_frame${idxRef}, ${idxRef} != 9;                 
                    childT4RB.theImages    = childT4RB.tracerRevision('typ', 'fqfp');   
                    childT4RB.epoch        = idxRef;
                    
                    %% update thisMotionUncorrected(idxRef).{resolveBuilder_,sessionData_,product_}
                
                    unco(idxRef).resolveBuilder_ = childT4RB; 
                    unco(idxRef).sessionData_    = childT4RB.sessionData;                                    
                    unco(idxRef).product_        = ImagingContext2(this.resolveBuilder_.umapTagged(childT4RB.resolveTag)); % ~ childRB.product;  
                    
                    fprintf('motionUncorrectEpoch1ToN:\n');
                    fprintf('source.fqfileprefix->\n    %s\n', source.fqfileprefix); 
                        % E1to9/umapSynth_op_fdgv1e1to9r1_frame${e}; 
                    fprintf('this(%i).product->\n    %s\n\n', idxRef, char(unco(idxRef).product)); 
                        %  E${idxRef}/umapSynth_op_fdgv1e1to9r1_frame${idxRef}; 
                catch ME
                    dispwarning(ME, 'mlpet:RuntimeWarning', ...
                        'TracerResolveBuilder.motionUncorrectEpoch1ToN failed resolve or t4img_4dfp on %s; using %s', ...
                        source.fqfilename, this.product.fqfilename); 
                    % E1to9 && idxRef->9 will fail with 
                    % Warning: The value of 'tracerSif' is invalid. It must satisfy the function: lexist_4dfp.
                    % Cf. mlfourdfp.ImageFrames lines 154, 173.  TODO.
                    % file: /home/usr/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp/ImageFrames.m; name: ImageFrames.readLength; line: 155; 
                    % file: /home/usr/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp/ImageFrames.m; name: ImageFrames.set.theImages; line: 54; 
                    % file: /home/usr/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp/AbstractT4ResolveBuilder.m; name: AbstractT4ResolveBuilder.set.theImages; line: 164; 
                    % file: /home/usr/jjlee/Local/src/mlcvl/mlpet/src/+mlpet/TracerResolveBuilder.m; name: TracerResolveBuilder.motionUncorrectUmapToEpochs; line: 235; 
                    % file: /home/usr/jjlee/Local/src/mlcvl/mlpet/src/+mlpet/TracerResolveBuilder.m; name: TracerResolveBuilder.motionUncorrectUmapToFrames; line: 184; 
                end                
                popd(pwd0); 
            end
        end     
        function unco1 = motionUncorrectToFrames(this, source, multiEpochOfSummed)
            %% MOTIONUNCORRECTTOFRAMES back-resolves a source in the space of some reference epoch to all available epochs.
            
            unco = this.motionUncorrectEpoch1ToN(source, multiEpochOfSummed);
                % thisUncorrected(${u}).product->E1to9/umapSynth_op_fdgv1e1to9r1_frame${u}
            for u = 1:length(unco)
                multi = multiEpochOfSummed(u).motionUncorrectEpoch( ...
                    unco(u).product, multiEpochOfSummed(u), u == length(unco));
                unco1{u} = multi;
            end
        end  
        function cRB  = reconcileUmapFilenames(~, cRB, varargin)
            %  @param  cRB has preferred umap packaged as its product{ele}. 
            %  @param  ele is the preferred element location in product; default := length(product)-1.
            %  @return cRB with legacy umap on the filesystem and packaged as its product.
            
            ip = inputParser;
            addOptional(ip, 'ele', length(cRB.product), @isnumeric);
            parse(ip, varargin{:});
            
            ic = mlfourd.ImagingContext2(cRB.product{ip.Results.ele});
            ic.saveas(cRB.sessionData.umapSynth);
            cRB = cRB.packageProduct(ic);
        end   
        function this = replaceMonolithFrames(this)
            %% REPLACEMONOLITHFRAMES manages pathological frames by replacing them with a reasonable substitute.
            %  @param this.f2rep, the frames to replace, is not empty and numeric.
            %  @param this.fsrc, the frame providing replacement, is not empty and is a numeric scalar.
            %  @return on the filesystem [this.sessionData.tracerRevision('typ','fqfp') '_beforeReplaceMonolithFrames.4dfp.*'].
            %  @return on the filesystem  this.sessionData.tracerRevision with new frames.
            
            if (isempty(this.f2rep) || isempty(this.fsrc))
                return
            end
            
            bv = this.buildVisitor;
            backup_4dfp = [this.sessionData.tracerRevision('typ','fqfp') '_beforeReplaceMonolithFrames'];
            bv.copy_4dfp(this.sessionData.tracerRevision('typ','fqfp'), backup_4dfp);
            tr = mlfourd.ImagingFormatContext2(this.sessionData.tracerRevision('typ', '.4dfp.hdr'));
            imgsrc = tr.img(:,:,:,this.fsrc);
            for f = 1:length(this.f2rep)
                tr.img(:,:,:,this.f2rep(f)) = imgsrc;
            end
            tr.save;
        end
        function this = reportResolved(this)
            %  @return this.product_ := {mlfourdfp.T4ResolveReport objects}
            
            report = [];
            nEpochs = ceil(this.nFramesAC/this.maxLengthEpoch);
            sessd = this.sessionData;
            
            for e = 1:nEpochs
                sessd.epoch = e;
                if (e < nEpochs)
                    flen = this.maxLengthEpoch;
                else
                    flen = this.nFramesAC - (e-1)*this.maxLengthEpoch;
                end
                parser = mlfourdfp.T4ResolveParser( ...
                    'sessionData', sessd, ...
                    'imagingFilename', '', ...
                    'loggingFilename', this.scrubbingLogFilename(sessd),...
                    'frameLength', flen);
                report = [report mlfourdfp.T4ResolveReport(parser)]; 
            end            
            this.product_ = report;
        end
		  
        %%
        
 		function this = TracerResolveBuilder(varargin)
            %% TRACERRESOLVEBUILDER
            %  @param named 'logger' is an mlpipeline.ILogger.
            %  @param named 'product' is the initial state of the product to build; default := [].
            %  @param named 'sessionData' is an mlpipeline.ISessionData; default := [].
 			%  @param named 'buildVisitor' is an mlfourdfp.FourdfpVisitor.
            %  @param named 'roisBuilder' is an mlrois.IRoisBuilder.
            %  @param named 'resolveBuilder' is an mlfourdfp.T4ResolveBuilder.
            %  @param named 'compositeResolveBuilder' is an mlfourdp.CompositeT4ResolveBuilder.
            %  @param named 'vendorSupport' is, e.g., mlsiemens.MMRBuilder.
            %  @param named 'reconstructLastEpoch' induces a call to deleteLastEpoch() if attenuation corrected; is logical.
            %  @return instance ready for t4-resolve management of tracer data.  
            
 			this = this@mlpet.TracerBuilder(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'f2rep', [], @isnumeric);
            addParameter(ip, 'fsrc',  [], @isnumeric);
            addParameter(ip, 'reconstructLastEpoch', false, @islogical)
            parse(ip, varargin{:});
            this.f2rep = ip.Results.f2rep;
            this.fsrc = ip.Results.fsrc;
            this = this.updateFinished; 
            %assert(isfile(this.sessionData.jsonFilename), ...
            %    'mlnipet:AssertionError', 'TracerResolveBuilder.ctor cannot find %s', this.sessionData.jsonFilename);
            if ip.Results.reconstructLastEpoch && this.sessionData.attenuationCorrected
                this.deleteLastEpoch()
            end
        end
    end 
    
    %% PROTECTED    
    
    properties (Access = protected)
        aComposite_ % cell array for simplicity
        nEpochs_
    end
    
    methods (Access = protected)
        function this = aufbauUmap(this)
            %  @return this:  this.product is the multi-frame umap as mlfourdfp.Fourdfp.
               
            import mlfourd.* mlfourdfp.*;
            fprintf('TracerResolveBuilder.umapAufbau:  working in %s\n', pwd);            
            sessd = this.sessionData;
            sessd.rnumber = 1;    
            tracerSz = this.size_4dfp(ImagingContext2(sessd.tracerRevision)); 
            nEpoch = ceil(tracerSz(4)/this.maxLengthEpoch);     
            
            sessd1 = sessd;
            sessd1.epoch = 1;
            sessd1.resolveTag = sessd1.resolveTagFrame(this.maxLengthEpoch, 'reset', true);
            umap = ImagingContext2(sessd1.umapTagged(sessd1.resolveTag));
            umapFfp = umap.fourdfp;
            umapFfp.fqfilename = sessd.umapTagged('');
            umapSz = umapFfp.size;
            umapFfp.img = zeros(umapSz(1),umapSz(2),umapSz(3),tracerSz(4));
            for ep = 1:nEpoch
                if ep ~= nEpoch
                    for fr = 1:this.maxLengthEpoch
                        sessd_ = sessd;
                        sessd_.epoch = ep;
                        sessd_.resolveTag = sessd_.resolveTagFrame(fr, 'reset', true);
                        frame_ = ImagingFormatContext2(sessd_.umapTagged(sessd_.resolveTag));
                        umapFfp.img(:,:,:,this.maxLengthEpoch*(ep-1)+fr) = frame_.img;
                    end
                else                    
                    % final epoch with variable number of frames
                    switch this.nFramesModMaxLengthEpoch 
                        case 0
                            for fr = 1:this.maxLengthEpoch
                                sessd_ = sessd;
                                sessd_.epoch = ep;
                                sessd_.resolveTag = sessd_.resolveTagFrame(fr, 'reset', true);
                                frame_ = ImagingFormatContext2(sessd_.umapTagged(sessd_.resolveTag));
                                umapFfp.img(:,:,:,this.maxLengthEpoch*(ep-1)+fr) = frame_.img;
                            end                    
                        case 1
                            sessd_ = sessd;
                            sessd_.epoch = 1:ep; % E1to9
                            sessd_.resolveTag = sessd_.resolveTagFrame(ep, 'reset', true);
                            fn = sessd_.umapTagged(['op_T1001_b43r1_' sessd_.resolveTag]);
                            fn1 = sessd_.umapTagged(['on_T1001_b43r1_' sessd_.resolveTag]);
                            if ~isfile(fn) && isfile(fn1)
                                fn = fn1;
                            end
                            frame_ = ImagingFormatContext2(fn);
                            umapFfp.img(:,:,:,this.maxLengthEpoch*(ep-1)+1) = frame_.img;  
                            % e.g., umapSynth_op_T1001_b43r1_op_fdgv1e1to9r1_frame9.4dfp.hdr                      
                        otherwise
                            for fr = 1:this.nFramesModMaxLengthEpoch
                                sessd_ = sessd;
                                sessd_.epoch = ep;
                                sessd_.resolveTag = sessd_.resolveTagFrame(fr, 'reset', true);
                                frame_ = ImagingFormatContext2(sessd_.umapTagged(sessd_.resolveTag));
                                umapFfp.img(:,:,:,this.maxLengthEpoch*(ep-1)+fr) = frame_.img;
                            end
                    end
                end
            end
            this = this.packageProduct(umapFfp);
        end
        function this = expandFovOfUmap(this)
            nii  = this.product_.nifti;
            %nii.datatype = 'single';
            umap = mlfourd.ImagingContext2(nii);
            fov  = this.FULL_FOV;
            umap = umap.zoomed(-fov(1)/4, fov(1), -fov(2)/4, fov(2), 0, -1, 0, -1); 
            this = this.packageProduct(umap);
        end
        function this = loadReconHistIntoUmap(this)
            import mlfourd.*;
            sess = this.sessionData;
            sess.attenuationCorrected = true;
            info = NIfTIInfo(this.sessionData.tracerNipet('nativeFov', true));
            nii = this.product_.nifti;
            nii.filepath = sess.scanPath;
            nii.fileprefix = mybasename(sess.umapTagged);
            nii.filesuffix = '.nii.gz';
            nii.ensureSingle();
            this = this.packageProduct( ...
                ImagingContext2(nii, 'hist', info.hdr.hist));
        end
        function nf   = nFramesModMaxLengthEpoch(this)
            sz = this.sizeTracerRevision;
            nf = mod(sz(4), this.maxLengthEpoch);
        end 
        function t4   = parentToChildT4(this, resolveTag)
            tracerEpochParent = this.resolveBuilder_.tracerEpoch('typ','fqfp'); % E1to9/fdgv1e1to9
            idxRefParent      = this.resolveBuilder_.indexOfReference;          % 9
            t4 = sprintf('%sr0_frame%i_to_%s_t4', tracerEpochParent, idxRefParent, resolveTag);
        end
        function efr  = partitionEpochFrames(this, monoBldr)
            %% PARTITIONFRAMES 
            %  @param this corresponds to a partitioning of an epoch from all the frames of monolith.
            %  @param monoBldr is the TracerResolveBuilder for the monolithic tracer imaging data;
            %  monoBldr.sizeTracerRevision must have rank == 4.
            %  @return epfr is numeric, specifying the indices of frames of monolith that correspond to this.epoch.
            
            monosz = monoBldr.sizeTracerRevision;
            e = this.sessionData_.epoch;
            if (e*this.maxLengthEpoch > monosz(4))
                efr = (e-1)*this.maxLengthEpoch+1:monosz(4); % modulo frames
                return
            end
            efr = (e-1)*this.maxLengthEpoch+1:e*this.maxLengthEpoch; % partition of frames
        end  
        function this = reconstituteComposites(this, those)
            %% RECONSTITUTECOMPOSITES contracts a composite of TracerResolveBuilder to a singlet.  It reconstitutes
            %  time resolution for this by union with time-dependent objects in those.
            %  @param this is singlet TracerResolveBuilder.
            %  @param those is composite TracerResolveBuilder;
            %         e.g., those(1) := fdgv1e1r2_op_fdgv1e1r1_frame8_sumt.
            %  @return this is singlet TracerResolveBuilder with time-dependence built up from a ordered union 
            %  of this with the composite those.  Motion-correction objects in 
            %  this.{sessionData.rnumber,resolveBuilder,epoch,product} get updating.
            %  See also mlpet.TracerResolveBuilder.motionCorrectFrames.
            
            import mlfourd.*;
            aufbau4dfp = ImagingFormatContext2(those(1).product.fqfilename);
            for e = 2:length(those)
                if (e < length(those))                
                    assert(isfile(those(e).tracerResolvedAvgt()), ...
                        '%s: file %s not found', clientname(false, 2), those(e).tracerResolvedAvgt());
                    ffp = ImagingFormatContext2(those(e).tracerResolvedAvgt()); % fdgv1e*r2_avgt
                     
                    %% KLUDGE: work with the best available
                    % 
                    % warning('mlpet:Kludge', ...
                    %     'TracerResolveBuilder.reconstituteComposites could not find %s.  Trying alternatives.', ...
                    %     those(e).tracerResolvedAvgt());
                    % ffps_ = glob(those(e).tracerRevisionAvgt('rLabel', 'r*')); % fdgv1e*r*_avgt
                    % assert(~isempty(ffps_));
                    % ffp = ImagingFormatContext2(ffps_{end});
                else
                    % append last remaining frames, which may be singleton without time-sum, to aufbau4dfp
                    this_r1 = those(e);
                    this_r1.rnumber = 1;
                    if (lexist_4dfp(               those(e).tracerResolvedAvgt()))
                        ffp = ImagingFormatContext2(those(e).tracerResolvedAvgt()); % fdgv1e*r2_avgt
                    elseif (lexist_4dfp(            this_r1.tracerResolvedAvgt()))
                        ffp = ImagingFormatContext2(those(e).tracerResolvedAvgt()); % fdgv1e*r1_avgt
                    elseif (lexist_4dfp(           those(e).tracerRevision()))
                        ffp = ImagingFormatContext2(those(e).tracerRevision()); % fdgv1e*r2
                    elseif (lexist_4dfp(            this_r1.tracerRevision()))
                        ffp = ImagingFormatContext2( this_r1.tracerRevision()); % fdgv1e*r1
                    else
                        error('mlpet:runtimeError', ...
                            ['TracerResolveBuilder.reconstituteComposites failed to reconstitute %s;\n' ...
                            'if indicesNonzero have been all false, the imaging frames may be empty'], ffp.fqfilename)
                    end                    
                end
                aufbau4dfp.img(:,:,:,e) = ffp.img;
            end
            
            % update this.{resolveBuilder_,sessionData_,product_}
            this.resolveBuilder_.resolveTag = ''; % CRUFT?
            this.sessionData_.epoch         = 1:length(those);
            this.sessionData_.rnumber       = 1; 
            aufbau4dfp.fqfilename           = this.sessionData_.tracerRevision('typ', '.4dfp.hdr'); % E1to9/fdgv1e1to9r1
            this.product_                   = ImagingContext2(aufbau4dfp);
            ensuredir(this.product_.filepath);
            if (~lexist(this.product_.fqfilename, 'file'))
                this.product_.save;
            end
        end	
        function ffp  = reconstituteFrame(this, varargin) %#ok<STOUT,INUSD>
            error('mlpet:NotImplementedError', 'TracerResolveBuilder.reconstituteFrame');
            ffp = this.reconstituteFrame_nipet(varargin{:}); %#ok<UNRCH>
            %ffp = this.reconstituteFrame_e7(varargin{:});
        end
        function this = repUmapToE7Format(this)
            sz  = length(this.sessionData.taus);
            fps = cellfun(@(x) sprintf('umapSynth_frame%i', x), num2cell(0:sz(4)-1), 'UniformOutput', false);
            cub = mlfourdfp.CarneyUmapBuilder('sessionData', this.sessionData);
            cub = cub.repUmapToE7Format(fps);
            this.product_ = cub.product;
        end
        function this = saveEpoch(this, monoBldr, mono4dfp)
            %% SAVEEPOCH
            %  @param this is bound to a partitioning of an epoch from all the frames of monolith.
            %  @param monoBldr is the TracerResolveBuilder object for the monolith or partition of the monolith.
            %  @param mono4dfp is ImagingContext.fourdfp for the monolithic tracer imaging data;
            %         ndims(monolith.sizeTracerRevision) == 4 is required.
            %  @return product := saved partitioning of monolith at this.epoch, cast as ImagingContext.fourdfp.
            
            monocopy = copy(mono4dfp);
            monocopy.img = mono4dfp.img(:,:,:,this.partitionEpochFrames(monoBldr));
            monocopy.fqfileprefix = this.tracerRevision('typ', 'fqfp');
            monocopy.save;
            this.product_ = monocopy;
        end
        function fn   = scrubbingLogFilename(~, sessd)
            dt = mlsystem.DirTool( ...
                fullfile(sessd.tracerLocation, 'Log', ...
                    sprintf('%s_T4ResolveBuilder_imageReg_D*.log', sessd.tracerRevision('typ','fp'))));
            assert(~isempty(dt.fqfns));
            fn = dt.fqfns{end};
        end
        function sz   = size_4dfp(this, obj)
            sz = this.buildVisitor.size_4dfp(obj);
        end
        function sz   = sizeProduct(this)
            %% SIZEPRODUCT
            %  @return sz, the size of the image data specified by this.tracerRevision.
            
            assert(this.buildVisitor.lexist_4dfp(this.product.fqfileprefix));
            sz = this.buildVisitor.ifhMatrixSize(this.product.fqfileprefix);
        end
        function sz   = sizeTracerRevision(this)
            %% SIZETRACERREVISION
            %  @return sz, the size of the image data specified by this.tracerRevision.
            
            sessd_ = this.sessionData_;
            sessd_.rnumber = 1;
            assert(this.buildVisitor.lexist_4dfp(sessd_.tracerRevision('typ', 'fqfp')));
            sz = this.buildVisitor.ifhMatrixSize(sessd_.tracerRevision('typ', '4dfp.ifh'));
        end
        function ffp  = t4imgFromNac(this, ffp, nFrames)
            %% t4imgFromNac uses t4s from NAC resolving products to place the AC reconstructions from e7tools in
            %  initial alignment.
            
            bv = this.buildVisitor;
            [epoch,epochSubframe] = this.getEpochIndices(this.sessionData_.frame);
            nEpochs = ceil(nFrames/this.maxLengthEpoch);            
            this.sessionData_.epoch = epoch;
            this.sessionData_.frame = epochSubframe;
            fprintf('mlpet.TracerResolveBuilder.t4imgFromNac.pwd -> %s\n', pwd);
            fprintf('mlpet.TracerResolveBuilder.t4imgFromNac.ffp.fqfileprefix -> %s\n', ffp.fqfileprefix);
            this.buildVisitor.move_4dfp(ffp.fileprefix, [ffp.fileprefix '__']);
            ffp.fileprefix = [ffp.fileprefix  '__'];
            t4rb = mlfourdfp.T4ResolveBuilder( ...
                'maskForImages', this.maskForImagesForT4RB, ...
                'sessionData', this.sessionData_, ...
                'theImages', ffp.fqfileprefix, ...
                'resolveTag', this.sessionData_.resolveTagFrame(epochSubframe, 'reset', true));
            
            sessDNac = this.sessionData_;
            sessDNac.attenuationCorrected = false;
            sessDNac.rnumber = 1;
            t4   = fullfile( ...
                sessDNac.tracerLocation, ...
                sprintf('%sr0_frame%i_to_%s_frame%i_t4', ...
                    sessDNac.tracerEpoch('typ', 'fp'), epochSubframe, sessDNac.resolveTag, this.maxLengthEpoch));
            dest = strrep(ffp.fileprefix, '__', '___');
            if (~lexist(strrep(t4, 'r0', 'r1'), 'file'))
                bv.move_4dfp(ffp.fileprefix, strrep(ffp.fileprefix, '__', ''));
                return
            end
            if (~bv.lexist_4dfp(dest))
                t4rb.t4img_4dfp(t4, ffp.fileprefix, 'out', dest, 'options', ['-O' ffp.fqfileprefix]);
            end
            
            sessDNac_ = sessDNac;
            sessDNac_.epoch = 1:nEpochs;
            t4_   = fullfile( ...
                sessDNac_.tracerLocation, ...
                sprintf('%sr0_frame%i_to_%s_frame%i_t4', ...
                    sessDNac_.tracerEpoch('typ', 'fp'), epoch, sessDNac_.resolveTag, nEpochs));
            dest_ = strrep(ffp.fileprefix, '__', '');
            if (~lexist(strrep(t4_, 'r0', 'r1'), 'file'))
                error('mlpet:unexpectedDataState', 'TracerResolveBuilder.t4imgFromNac');
            end
            if (~bv.lexist_4dfp(dest_))
                t4rb.t4img_4dfp(t4_, ffp.fileprefix, 'out', dest_, 'options', ['-O' ffp.fqfileprefix]);
            end
            ffp   = mlfourd.ImagingFormatContext2([dest_ '.4dfp.hdr']);
            
            deleteExisting([dest_ '__.4dfp.*']);
            deleteExisting([dest_ '___.4dfp.*']);
        end    
    end
    
    %% PRIVATE
    
    methods (Access = private)
        function          assertUmap(this, obj)
            assert(lstrfind(obj.fileprefix, 'umap'));
            sz = this.size_4dfp(obj);
            assert(3 == length(sz) || 1 == sz(4));
        end
        function [e,e1] = getEpochIndices(this, nacFrame)
            e  = floor(nacFrame/this.maxLengthEpoch) + 1;
            e1 = mod(  nacFrame,this.maxLengthEpoch) + 1;  
        end
        function ffp    = reconstituteFrame_e7(this, varargin)
            %  @param named sessionData is an mlpipeline.ISessionData.
            %  @param this.sessionData.tracerListmodeMhdr exists.
            %  @param named frame is numeric.
            %  @param named fqfp is the f. q. fileprefix of a frame of the tracer study.
            %  @return ffp is an mlfourdfp.Fourdfp containing the frame.
            
            fqfp0 = this.sessionData_.tracerRevision('frame', this.sessionData_.frame, 'typ', 'fqfp');
            ip = inputParser;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'));
            addOptional(ip, 'frame', nan, @isnumeric);
            addParameter(ip, 'fqfp', fqfp0, @ischar);
            parse(ip, varargin{:});       
            
            sd = ip.Results.sessionData;
            sd.frame = ip.Results.frame;
            sd.epoch = [];
            fqfp0 = ip.Results.fqfp;
            
            bv = this.buildVisitor;
            pwd0 = pushd(sd.tracerListmodeLocation);
            sif_ = sd.tracerListmodeSif('frame', sd.frame, 'typ', 'fp');
            %if (~bv.lexist_4dfp(sif_))
                bv.sif_4dfp(sd.tracerListmodeMhdr, sif_);
            %end
            bv.cropfrac_4dfp(0.5, sif_, fqfp0);
            %deleteExisting([sif_ '.4dfp.*']);
            ffp = mlfourd.ImagingFormatContext2([fqfp0 '.4dfp.hdr']);
            popd(pwd0);
            %ffp.fqfileprefix = this.sessionData_.tracerRevision('typ', 'fqfp');
            %ffp.img = zeros(size(ffp));
        end
        function ffp    = reconstituteFrame_nipet(this, varargin)
            %  @param named sessionData is an mlpipeline.ISessionData.
            %  @param this.sessionData.tracerNipet exists.
            %  @param named fqfp is the f. q. fileprefix of the tracer scan.
            %  @return ffp is an mlfourd.ImagingFormatContext2 containing the tracers scan.
            
            fqfp0 = this.sessionData_.tracerNipet('typ', 'fqfp');
            ip = inputParser;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.ISessionData'));
            addOptional(ip, 'frame', nan, @isnumeric);
            addParameter(ip, 'fqfp', fqfp0, @ischar);
            parse(ip, varargin{:});       
            
            sd = ip.Results.sessionData;
            sd.epoch = [];
            fqfp0 = ip.Results.fqfp;
            ffp = mlfourd.ImagingFormatContext2([fqfp0 '.4dfp.hdr']);
        end
        function sess   = recallOtherTracerResolvedFinalAvgt(this, varargin)
            ip = inputParser;
            addRequired(ip, 'tracer', @ischar);
            parse(ip, varargin{:})
            
            % assemble the other
            sess = this.sessionData;
            sess.attenuationCorrected = true;
            sess.tracer = ip.Results.tracer;
            sess.rnumber = 2;
            sess.snumber = 1;
            sess.epoch = 1:sess.supEpoch;
            while (~lexist(sess.tracerResolvedFinalAvgt) && sess.supEpoch > 0)
                sess.supEpoch = sess.supEpoch - 1;
            end
            
            % use the other if possible
            if (~lexist_4dfp(sess.tracerResolvedFinalAvgt('typ','fqfp')))  
                error('mlpet:AssertionError', ...
                      '%s may be missing; ensure completion of construct_resolved(''tracer'', ''%s'') and retry', ...
                      sess.tracerResolvedFinalAvgt('typ','fqfp'), sess.tracer);
            end              
            deleteExisting([sess.tracerResolvedFinalAvgt('typ','fp') '.4dfp.*']);
            this.buildVisitor.copyfile_4dfp( ...
                            sess.tracerResolvedFinalAvgt('typ','fqfp'), ...
                            sess.tracerResolvedFinalAvgt('typ','fp'));
        end
        function t4     = t4ForReconstituteFramesAC2(this, epoch, sessde1toN)
            switch (sessde1toN.rnumber)
                case 1
                    t4 = [sessde1toN.tracerRevision('frame', epoch, 'typ','fqfp') '_to_' sessde1toN.resolveTag '_t4'];
                case 2
                    sdr1 = sessde1toN; sdr1.rnumber = 1;
                    sdr2 = sessde1toN; sdr2.rnumber = 2;
                    t4   = [sdr1.tracerRevision('rLabel', 'r1r2', 'frame', epoch, 'typ','fqfp'), ...
                            '_to_' sdr1.resolveTag '_t4'];
                    this.buildVisitor_.t4_mul( ...
                        [sdr1.tracerRevision('frame', epoch, 'typ','fqfp') '_to_' sdr1.resolveTag '_t4'], ...
                        [sdr2.tracerRevision('frame', epoch, 'typ','fqfp') '_to_' sdr1.resolveTag '_t4'], ...
                        t4);
                        % [/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V1/FDG_V1-AC/E1to11/fdgv1e1to11r1_frame1_to_op_fdgv1e1to11r1_frame11_t4] x
                        % [/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V1/FDG_V1-AC/E1to11/fdgv1e1to11r2_frame1_to_op_fdgv1e1to11r1_frame11_t4] = 
                        % [/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V1/FDG_V1-AC/E1to11/fdgv1e1to11r1r2_frame1_to_op_fdgv1e1to11r1_frame11_t4]
                otherwise
                    error('mlpet:unsupportedSwitchcase', ...
                          'TracerResolveBuilder.t4ForReconstituteFramesAC2.this.NRevisions->%i', this.NRevisions);
            end
        end
    end

    %% HIDDEN
    
    methods (Hidden)
        function nii  = applyTauMultiplier(this, nii)
            %% Experimental methods to combine frames to increase SNR.
            
            switch (this.sessionData.tauMultiplier)
                case 1
                case 2
                    assert(isa(nii, 'mlfourd.INIfTI'));
                    sz   = size(nii);
                    M    = floor(sz(4)/2);                    
                    N    = ceil( sz(4)/2);
                    img_ = zeros(sz(1),sz(2),sz(3),N);
                    u    = 1;
                    for t = 1:M
                        img_(:,:,:,t) = (nii.img(:,:,:,u) + nii.img(:,:,:,u+1))/2;
                        u = u + 2;
                    end
                    if (0 ~= mod(sz(4), 2))
                        img_(:,:,:,end) = nii.img(:,:,:,end);
                    end
                    nii.img = img_;
                case 4
                    nii = this.applyTauMultiplier( ...
                          this.applyTauMultiplier(nii));
                case 8
                    nii = this.applyTauMultiplier( ...
                          this.applyTauMultiplier( ...
                          this.applyTauMultiplier(nii)));
                case 16
                    nii = this.applyTauMultiplier( ...
                          this.applyTauMultiplier( ...
                          this.applyTauMultiplier( ...
                          this.applyTauMultiplier(nii))));
                otherwise
                    error('mlpet:unsupportedSwitchCase', 'TracerResolveBuilder.applyTauMultiplier');
            end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
    
 end

