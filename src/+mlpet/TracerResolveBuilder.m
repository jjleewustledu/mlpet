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
     
    properties
        f2rep % use to exclude early frames of OC, OO that have breathing tube in FOV
        fsrc  %
    end    
    
    properties (Dependent)
        imgblurTag
        maskForImagesForT4RB
        nFramesAC
        noiseFloorOfActivity
        tauFramesNAC
        umapSynthFp
        umapSynthFqfn 
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
        function g = get.noiseFloorOfActivity(~)
            g = mlpet.Resources.instance.noiseFloorOfActivity;
        end
        function g = get.tauFramesNAC(this)
            g = this.sessionData.taus;
            assert(~isempty(this.product));
            sizeProd = size(this.product);
            g = g(1:sizeProd(4));
        end
        function g = get.umapSynthFp(this)
            g = mybasename(this.umapSynthFqfn);
        end
        function g = get.umapSynthFqfn(this)
            g = this.umapSynthFqfn_;
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
            %  See also:  mlpipeline.RootBuilder.
            
            sz = this.sizeTracerRevision;
            if (length(sz) < 4 || 1 == sz(4))
                mono = this;
                return
            end
            
            import mlfourd.*;
            if (sz(4) > this.maxLengthEpoch)
                this_               = this;
                mono.sessionData    = this_.sessionData;
                mono.imagingContext = ImagingContext(this_.tracerRevision); 
                this_.nEpochs_       = ceil(sz(4)/this_.maxLengthEpoch);
                for e = 1:this_.nEpochs_
                    this(e) = this_;
                    this(e).sessionData_.epoch = e;
                    ice = ImagingContext(this(e).tracerRevision);
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
            %  @return reconstituted := singlet ImagingFormatContext containing time sum of motion-corrected frames.
                
            % recursion over epochs to generate composite
            if (length(this) > 1)                
                for e = 1:length(this)
                    this(e) = this(e).setLogPath( ...
                        fullfile(this(e).tracerRevision, 'Log', ''));
                    [this(e),~,epochs(e)] = this(e).motionCorrectFrames; 
                end
                epoch1 = epochs(1);
                epoch1 = epoch1.reconstituteComposites(epochs);
                [this,reconstituted] = epoch1.motionCorrectEpochs;
                return
            end
            
            % base case; returns singlet
            this.product_ = mlfourd.ImagingContext(this.tracerRevision);
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
            %  @param  this.umapSynthFqfn is the source of anatomical alignment for the motion-corrected umap.
            %  @return motion-corrections of this.umapSynthFqfn, T1, t2 onto this.product for 
            %          this.{compositeResolveBuilder,sessionData,product};
            %          e.g., this.product := umapSynth_to_op_fdgv1e1to9r1_frame9.
            
            pwd0 = pushd(this.product_.filepath);      
            this.locallyStageModalities('fourdfp', myfileprefix(this.umapSynthFqfn));             
            this.sessionData_.rnumber = 1;
            sessFdg = this.sessionData_;
            sessFdg.rnumber = 2;
            sessFdg.tracer = 'FDG';
            sessHo  = this.sessionData_;
            sessHo.rnumber = 2;
            sessHo.tracer = 'HO';
            product = this.product_.fileprefix;
            switch (this.sessionData_.tracer)
                case  'OO'
                    sessFdg = this.refreshTracerResolvedFinalSumt(sessFdg);
                    sessHo  = this.refreshTracerResolvedFinalSumt(sessHo);
                    theImages = {product ... 
                                 sessHo.tracerResolvedFinalSumt('typ','fp') ...
                                 sessFdg.tracerResolvedFinalSumt('typ','fp') ...
                                 this.T1('typ', 'fp') ...
                                 this.umapSynthFp}; % sessHo.tracerResolvedFinalSumt('typ','fp') ...
                                                    % sessFdg.tracerResolvedFinalSumt('typ','fp') ...
                    cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                        'sessionData', this.sessionData_, ...
                        'theImages', theImages, ...
                        'maskForImages', {'Msktgen' 'Msktgen' 'Msktgen' 'T1001' 'none'}, ...
                        'NRevisions', 1); % 'Msktgen' 
                case {'HO' 'OC'}
                    sessFdg = this.refreshTracerResolvedFinalSumt(sessFdg);
                    theImages = {product ... 
                                 sessFdg.tracerResolvedFinalSumt('typ','fp') ...
                                 this.T1('typ', 'fp') ...
                                 this.umapSynthFp};
                    cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                        'sessionData', this.sessionData_, ...
                        'theImages', theImages, ...
                        'maskForImages', {'Msktgen' 'Msktgen' 'T1001' 'none'}, ...
                        'NRevisions', 1);
                case 'FDG'
                    theImages = {product ... 
                                 this.T1('typ', 'fp') ...
                                 this.umapSynthFp};
                    cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                        'sessionData', this.sessionData_, ...
                        'theImages', theImages, ...
                        'maskForImages', {'Msktgen' 'T1001' 'none'}, ...
                        'NRevisions', 1);
                otherwise
                    error('mlpet:unsupportedSwitchCase', ...
                          'TracerResolveBuilder.motionCorrectCTAndUmap....tracer->%s', ...
                          this.sessionData_.tracer);
            end
                        
            % update this.{compositeResolveBuilder_,sessionData_,product_}                      
            cRB_ = cRB_.resolve;                      
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
            
            umapOnFrameEnd = this.product;
            this.assertUmap(umapOnFrameEnd);
            this.motionUncorrectToFrames(umapOnFrameEnd, multiEpochOfSummed);
            
            this.sessionData.epoch = [];
            loc = this.sessionData.tracerLocation;
            ensuredir(loc);
            cd(loc);
            this = this.umapAufbau;
            this = this.partitionUmaps;
            
        end
        function        markAsFinished(this, varargin)
            this.finished.markAsFinished(varargin{:});   
        end    
        
        %% Utilities
        
        function this = convertUmapsToE7Format(this)
            sz  = this.sizeTracerRevision;
            fps = cellfun(@(x) sprintf('umapSynth_frame%i', x), num2cell(0:sz(4)-1), 'UniformOutput', false);
            cub = mlfourdfp.CarneyUmapBuilder('sessionData', this.sessionData);
            cub = cub.convertUmapsToE7Format(fps);
            this.product_ = cub.product;
        end
        function idx  = indicesNonzero(this)
            p = this.product_;
            if (isa(p, 'mlfourd.ImagingContext'))
                p = p.numericalNiftid;
            end
            if (isa(p, 'mlfourd.NIfTId'))
                p = mlfourd.NumericalNIfTId(p);
            end
            p   = p.volumeSummed;
            idx = p.img > this.sessionData.fractionalImageFrameThresh * median(p.img) + this.noiseFloorOfActivity;
            idx = ensureRowVector(idx) & ensureRowVector(this.sessionData.indicesLogical);
            this.logger.add('indicesNonzero.p.img->%s\n', mat2str(p.img));
            this.logger.add('indicesNonzero.idx->%s\n', mat2str(idx));
        end
        function [this,summed] = motionCorrectEpochs(this)
            %% MOTIONCORRECTEPOCHS accepts time-resolved image and returns them with motion-correction.
            %  It also returns the time-sum ofthe motion-corrected frames.
            %
            %  @param  this.product contains a set of frames to motion-correct.
            %  @return this.{resolveBuilder,sessionData,product} := updated motion-correction objects.
            %  @return this.product := ImagingContext of time-resolved motion-corrected frames;
            %          E.g., this.product := files E*/fdgv1e*r2_op_fdgv1e*r1_frame*.
            %  @return summed := ImagingFormatContext with time-sum of motion-corrected frames.
            %          E.g., summed.product := files E*/fdgv1e*r2_op_fdgv1e*r1_frame*_sumt.
            %  @return this unchanged and summed := this for ndims(sessionData.tracerRevision) < 4.
            
            sz = this.sizeTracerRevision;
            if (length(sz) < 4 || 1 == sz(4)) % Consider:  thisSz(4) == duration of this epoch
                summed = this;
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
            this.product_        = t4rB_.product;
            summed               = this.sumProduct;
            popd(pwd0);
        end
        function unco = motionUncorrectEpoch(this, source, multiEpochOfSummed, lastEpoch)
            %% MOTIONUNCORRECTEPOCH back-resolves a source in the space of some reference epoch to all available epochs.
            %  @param this.resolveBulder.product is the motion-corrected-summed singlet object to which source will align.
            %  @param source is an ImagingContext.
            %  @param lastEpoch is logical.
            %  @return thisUncorrected, a collection of TracerResolveBuilders, each conveying back-resolving
            %  to one of the available epochs.
            
            assert(isa(source, 'mlfourd.ImagingContext'));
            assert(isa(multiEpochOfSummed, 'mlpet.TracerResolveBuilder'));
            import mlfourd.*;
            
            if (lastEpoch)
                NRef = this.nFramesModMaxLengthEpoch;
                if (NRef <= 1)
                    unco = this;
                    return
                end
            else 
                NRef = this.maxLengthEpoch;
            end
            for idxRef = 1:NRef % uncorrect source to each frame as a separate reference frame
                
                %% resolve source to thisMotionUncorrected(idxRef)
                
                try
                    loc = this.resolveBuilder_.sessionData.tracerLocation;
                    ensuredir(loc);
                    pwd0 = pushd(loc); % E1, ..., E8;
                    res = mlpet.Resources.instance;
                    unco(idxRef) = this; %#ok<*AGROW>
                    childT4RB                  = this.resolveBuilder_;
                    childT4RB.rnumber          = 1;
                    childT4RB.indexOfReference = idxRef;  
                    childT4RB.resolveTag       = childT4RB.resolveTagFrame(idxRef, 'reset', true); % op_fdgv1${e}r1_frame${idxRef};                      
                    childT4RB                  = childT4RB.updateFinished( ...
                        'tag', sprintf('_motionUncorrectToEpochs2_%s', source.fileprefix), ...
                        'neverMarkFinished', res.neverMarkFinished);
                    
                    childT4RB.skipT4imgAll = true;
                    childT4RB              = childT4RB.resolve; % childRB.product->${E}/fdgv1${e}r2_op_fdgv1${e}r1_frame${idxRef}
                    childT4RB.skipT4imgAll = false;                    
                    parentToChildT4_     = multiEpochOfSummed.parentToChildT4(childT4RB.resolveTag);
                    if (childT4RB.indicesLogical(idxRef) && ...
                        lexist(parentToChildT4_, 'file'))
                        childT4RB          = childT4RB.t4img_4dfp( ...
                            parentToChildT4_, ...
                            source.fqfileprefix, ...
                            'out', childT4RB.umap(childT4RB.resolveTag, 'typ', 'fp'), ...
                            'options', ['-O' this.sessionData.tracerResolved('typ','fp')]);
                            % t4     := ${E}/fdgv1${e}r0_frame8_to_op_fdgv1${e}r1_frame${idxRef}_t4; 
                            % source := E1to9/umapSynth_op_fdgv1e1to9r1_frame${e};          
                            % out    :=       umapSynth_op_fdgv1${e}r1_frame${idxRef}  
                    else
                        childT4RB.buildVisitor.copyfile_4dfp( ...
                            source.fqfileprefix, ...
                            childT4RB.umap(childT4RB.resolveTag, 'typ', 'fp'));
                    end 
                    childT4RB.theImages    = childT4RB.tracerRevision('typ', 'fqfp');   
                    childT4RB.epoch        = idxRef;
                    
                    %% update thisMotionUncorrected(idxRef).{resolveBuilder_,sessionData_,product_}
                
                    unco(idxRef).resolveBuilder_ = childT4RB; 
                    unco(idxRef).sessionData_    = childT4RB.sessionData;                                    
                    unco(idxRef).product_        = ImagingContext(this.resolveBuilder_.umap(childT4RB.resolveTag)); % ~ childRB.product;  
                    
                    fprintf('motionUncorrectEpoch:\n');
                    fprintf('source.fqfileprefix->\n    %s\n', source.fqfileprefix); 
                        % E1to9/umapSynth_op_fdgv1e1to9r1_frame${e}; 
                    fprintf('this(%i).product->\n    %s\n\n', idxRef, char(unco(idxRef).product)); 
                        % E${idxRef}/umapSynth_op_fdgv1e1to9r1_frame${idxRef};                 
                    popd(pwd0);
                    
                catch ME
                    handwarning(ME); 
                    break
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
            %  @param this.resolveBulder.product is the motion-corrected-summed singlet object to which source will align.
            %  @param source is an ImagingContext.
            %  @return thisUncorrected, a collection of TracerResolveBuilders for E1to9, each conveying back-resolving
            %  to one of the other available epochs.  thisUncorrected is never back-resolved to itself so
            %  length(thisUncorrected) = length(multiEpochOfSummed) - 1.
            
            assert(isa(source, 'mlfourd.ImagingContext'));
            assert(isa(multiEpochOfSummed, 'mlpet.TracerResolveBuilder'));
            import mlfourd.*;
            
            for idxRef = 1:length(multiEpochOfSummed)
                
                %% resolve source to thisUncorrected(idxRef)
                loc = this.resolveBuilder_.sessionData.tracerLocation;
                ensuredir(loc);
                pwd0 = pushd(loc); % E1to9;    
                unco(idxRef) = this; %#ok<*AGROW>       
                if (idxRef == this.resolveBuilder_.indexOfReference)
                    continue
                end  
                res = mlpet.Resources.instance;
                try
                    childT4RB                  = this.resolveBuilder_;
                    childT4RB.rnumber          = 1;
                    childT4RB.indexOfReference = idxRef;  
                    childT4RB.resolveTag       = childT4RB.resolveTagFrame(idxRef, 'reset', true); % op_fdgv1e1to9r1_frame${idxRef};                      
                    childT4RB                  = childT4RB.updateFinished( ...
                        'tag', sprintf('_motionUncorrectToEpochs_%s', source.fileprefix), ...
                        'neverMarkFinished', res.neverMarkFinished);
                    
                    childT4RB.skipT4imgAll = true;
                    childT4RB              = childT4RB.resolve; % childRB.product->${E}/fdgv2${e}r2_op_fdgv2${e}r1_frame${idxRef}
                    childT4RB.skipT4imgAll = false;                    
                    childT4RB              = childT4RB.t4img_4dfp( ...
                        this.parentToChildT4(childT4RB.resolveTag), ...
                        source.fqfileprefix, ...
                        'out', childT4RB.umap(childT4RB.resolveTag, 'typ', 'fp'), ...
                        'options', ['-O' this.sessionData.tracerResolved('typ','fp')]);
                        % t4     := E1to9/fdgv1e1to9r0_frame9_to_op_fdgv1e1to9r1_frame${idxRef}_t4; 
                        % source := E1to9/umapSynth_op_fdgv1e1to9r1_frame9;                         
                        % out    :=       umapSynth_op_fdgv1e1to9r1_frame${idxRef}, ${idxRef} != 9;                 
                    childT4RB.theImages    = childT4RB.tracerRevision('typ', 'fqfp');   
                    childT4RB.epoch        = idxRef;
                    
                    %% update thisMotionUncorrected(idxRef).{resolveBuilder_,sessionData_,product_}
                
                    unco(idxRef).resolveBuilder_ = childT4RB; 
                    unco(idxRef).sessionData_    = childT4RB.sessionData;                                    
                    unco(idxRef).product_        = ImagingContext(this.resolveBuilder_.umap(childT4RB.resolveTag)); % ~ childRB.product;  
                    
                    fprintf('motionUncorrectEpoch1ToN:\n');
                    fprintf('source.fqfileprefix->\n    %s\n', source.fqfileprefix); 
                        % E1to9/umapSynth_op_fdgv1e1to9r1_frame${e}; 
                    fprintf('this(%i).product->\n    %s\n\n', idxRef, char(unco(idxRef).product)); 
                        %  E${idxRef}/umapSynth_op_fdgv1e1to9r1_frame${idxRef}; 
                catch ME
                    handwarning(ME); 
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
        function unco = motionUncorrectToFrames(this, source, multiEpochOfSummed)
            %% MOTIONUNCORRECTTOFRAMES back-resolves a source in the space of some reference epoch to all available epochs.
            
            unco = this.motionUncorrectEpoch1ToN(source, multiEpochOfSummed);
                % thisUncorrected(${u}).product->E1to9/umapSynth_op_fdgv1e1to9r1_frame${u}
            for u = 1:length(unco)
                multiEpochOfSummed(u).motionUncorrectEpoch( ...
                    unco(u).product, multiEpochOfSummed(u), u == length(unco));
            end
        end    
        function this = motionUncorrectUmapToEpochs(this, umapOpParent)
            %% MOTIONUNCORRECTUMAPTOEPOCHS back-resolves a umap aligned to a single frame onto all frames.
            %  @param this is multiframe
            %  @param this.motionCorrectFrames has run successfully, generating this.resolveBuilder.
            %  @param umapOpParent is the ImagingContext aligned to a single frame to be back-resolved to all frames.
            %  @return this := [] but no other mutations for rank(this.sizeTracerRevision) < 3.
            %  @return umapOpParent back-resolved to all available frames, 1:this.sizeTracerRevision(4).  
            %  @return this := this(1:this.sizeTracerRevision(4)), a composite.
            
            this.assertUmap(umapOpParent);
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4))
                this = [];
                return
            end            
            
            %% N.B.:  this, this(idxRef), this(idxRef).compositeResolveBuilder_, this(idxRef).resolveBuilder_, this(idxRef).resolveBuilder_.sessionData
            
            parent            = this;
            parentTracerEpoch = parent.resolveBuilder_.tracerEpoch('typ','fqfp'); % E1to9/fdgv1e1to9; E1to9/fdgv1e1to9
            parentIdxRef      = parent.resolveBuilder_.indexOfReference;          % 9; ${e}                                                                                  
            for idxRef = 1:thisSz(4) % thisSz(4)->1:9; thisSz(4)->1:9

                %% resolve umapOpParent to idxOfRef
                
                this(idxRef) = parent;                
                pwd0 = pushd(this(idxRef).resolveBuilder_.product.filepath); % E1to9;                    
                try
                    rB_                   = this(idxRef).resolveBuilder_;
                    rB_.rnumber           = 1;
                    rB_.indexOfReference  = idxRef;  
                    rB_.resolveTag        = rB_.resolveTagFrame(idxRef, 'reset', true); % op_fdgv1e1to9r1_frame${idxRef};                      
                    rB_                   = rB_.updateFinished( ...
                        'tag', sprintf('_motionUncorrectUmapToEpochs_%s', umapOpParent.fileprefix));
                    
                    rB_.skipT4imgAll = true;
                    rB_              = rB_.resolve; % rB_.product->${E}/umapSynth${e}r1_frame${idxRef}                                      
                    rB_.skipT4imgAll = false;                    
                    rB_              = rB_.t4img_4dfp( ...
                        sprintf('%sr0_frame%i_to_%s_t4', parentTracerEpoch, parentIdxRef, rB_.resolveTag), ...
                        umapOpParent.fqfileprefix, ...
                        'out', this(idxRef).umap(rB_.resolveTag, 'typ', 'fp'));
                        % t4     := E1to9/fdgv1e1to9r0_frame9_to_op_fdgv1e1to9r1_frame${idxRef}_t4; 
                        % source := E1to9/umapSynth_op_fdgv1e1to9r1_frame9;                         
                        % out    :=       umapSynth_op_fdgv1e1to9r1_frame${idxRef};                 
                    rB_.theImages    = rB_.tracerRevision('typ', 'fqfp');   
                    rB_.epoch        = idxRef;
                    
                    %% update this(idxRef).{resolveBuilder_,sessionData_,product_}
                
                    this(idxRef).resolveBuilder_ = rB_;
                    this(idxRef).sessionData_    = rB_.sessionData;                                    
                    this(idxRef).product_        = mlfourd.ImagingContext(this(idxRef).umap(rB_.resolveTag)); % ~ rB_.product;  
                    
                    fprintf('motionUncorrectUmapToEpochs:\n');
                    fprintf('umapOpParentFqfp->\n    %s\n', umapOpParent);                   
                        % E1to9/umapSynth_op_fdgv1e1to9r1_frame${e}; 
                    fprintf('this(%i).product->\n    %s\n\n', idxRef, this(idxRef).product); 
                        %  E${idxRef}/umapSynth_op_fdgv1e1to9r1_frame${idxRef}; 
                catch ME
                    handwarning(ME); 
                    deleteExisting();
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
        function this = motionUncorrectUmapToFrames(this, umapOpParent) %, monolith)
            %% MOTIONUNCORRECTUMAPTOFRAMES uses previously split and motion-corrected monolithic image with 
            %  partitioned tree of epochs or frames. 
            %  @param this.product contains singlet-frame created by this.motionCorrectCTAndUmap; 
            %  focus moves to this.resolveBuilder.
            %  @param umapOpParent is an externally generated umap; e.g., from CarneyUmapBuilder.
            %  @return singlet-frame umapOpParent back-resolved onto the children of motion-correction hierarchy.
            %  @return this 
            
            assert(~isempty(this.resolveBuilder_), 'ensure motionCorrectFrames has completed successfully');            
            this.sessionData_ = this.resolveBuilder_.sessionData;
            this.product_     = this.resolveBuilder_.product; % this.product->umapSynth_to_op_fdgv1e1to9r1_frame9 replaced by
                                                              % this.product->fdgv1e1to9r2_to_op_fdgv1e1to9r1_frame9
            parent            = this; % parent->E1to9/fdgv1e1to9r2_op_fdgv1e1to9r1_frame9
                
            this = this.motionUncorrectUmapToEpochs(umapOpParent); % umapOpParent->E1to9/umapSynth_op_fdgv1e1to9r1_frame9
                % return this(E1) ... this(E9)
                % with this(E8).product->umapSynth_op_fdgv1e1to9r1_frame8
                % and  this(E9).product->fdgv1e1to9r2_op_fdgv1e1to9r1_frame9.
                %      this(E9)issues Warning: The value of 'tracerSif' is invalid. It must satisfy the function: lexist_4dfp.
            
            if (length(this) > 1)
                for e = 1:length(this)
                    % this(${e}).product->E1to9/umapSynth_op_fdgv1e1to9r1_frame${e}
                    this(e).motionUncorrectUmapToEpochs2(e, this(e).product); 
                end
%                singlet = this(1); % E1to9/umapSynth_op_fdgv1e1to9r1_frame1
%                singlet = singlet.reconstituteUmaps(this, monolith);  % this   := [this(E1) ... this(E9)];
%                                                                      % parent := this(E1to9).fdgv1e1to9r2_op_fdgv1e1to9r1_frame9
%                this    = singlet;
            end           
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
                this.product_ = mlfourd.ImagingContext(this.sessionData_.tracerRevision);
                return
            end  
            
            %% create this.sessionData_.tracerRevision
            
            this.sessionData_.frame = 0;
            aufbau = this.reconstituteFrame(this.sessionData_, 0);
            aufbau.fqfilename = this.sessionData_.tracerRevision;
            assert(4 == length(aufbau.size) && aufbau.size(4) > 0);
            innerf = size(aufbau, 4);
            this.sessionData_.frame = 1;
            while (isdir(this.sessionData_.tracerConvertedLocation))

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
            
            import mlfourdfp.*;            
            nFrames = this.nFramesAC;
            nEpochs = floor(nFrames/this.maxLengthEpoch);
            supEpochs = ceil(nFrames/this.maxLengthEpoch);
            sessd_ = this.sessionData;
            sessd_.epoch = [];
            sessd_.frame = nan;
            sessd_.rnumber = 2;
            sessd__ = sessd_;
            sessd__.rnumber = 1;
            sessd1 = sessd_;
            sessd1.epoch = 1;
            sessd1toN = sessd_;
            sessd1toN.epoch = 1:supEpochs;
            sessd1toN.frame = supEpochs;
            
            pwd0 = pushd(sessd_.tracerLocation);
            ffp0 = Fourdfp.load(sessd__.tracerRevision('frame', 1));
            sz = size(ffp0.img);
            ffp0.img = zeros(sz(1), sz(2), sz(3), nFrames);
            ffp0.fqfileprefix = sessd_.tracerResolved('typ', 'fqfp'); % fdgv1r2_op_fdgv1e1to4r1_frame4
            fv = FourdfpVisitor;
            
            inz = this.indicesNonzero;
            for e = 1:nEpochs  
                if (~inz(e))
                    continue
                end
                sessde = sessd_;
                sessde.epoch = e;
                sessde.resolveTag = sprintf('op_%sr1_frame%i', sessde.tracerEpoch('typ','fp'), this.maxLengthEpoch);                
                pwd1 = pushd(sessde.tracerLocation);              
                t4 = this.t4ForReconstituteFramesAC2(e, sessd1toN); % /data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V2/FDG_V2-AC/E1to4/fdgv1e1to4r1r2_frame1_to_op_fdgv1e1to4r1_frame4_t4
                fp = sessde.tracerResolved('typ', 'fp'); % fdgv1e1r2_op_fdgv1e1r1_frame24
                fpDest = [sessde.tracerRevision('typ','fp') '_' sessd1toN.resolveTag]; % fdgv1e1r2_op_fdgv1e1to4r1_frame4
                if (lexist(t4, 'file'))
                    fv.t4img_4dfp(t4, fp, 'out', fpDest, 'options', ['-O' fp]);
                    ffp = Fourdfp.load([fpDest '.4dfp.hdr']);
                else
                    % e.g., for case in which most of epoch 1 is empty because of late
                    % dose administration
                    ffp = Fourdfp.load([fp '.4dfp.hdr']);
                end
                ffp0.img(:,:,:,(e-1)*this.maxLengthEpoch+1:e*this.maxLengthEpoch) = ffp.img; % FDG_V1-AC/fdgv1r2_op_fdgv1e1to4r1_frame4.4dfp.hdr
                popd(pwd1);
            end
            
            e = supEpochs;
            sessde = sessd_;
            sessde.epoch = e;
            pwd1 = pushd(sessde.tracerLocation);      
            remainingFrames = (e-1)*this.maxLengthEpoch+1:nFrames; % vector
            if (1 == length(remainingFrames)) 
                
                % single frame remaining
                fp = sprintf('%sr1', sessde.tracerEpoch('typ','fp')); % fdgv1e4r1
                ffp = Fourdfp.load([fp '.4dfp.hdr']);
                ffp0.img(:,:,:,remainingFrames) = ffp.img;
                popd(pwd1);                
                ffp0.save;
                popd(pwd0);
                this = this.packageProduct(ffp0);
                return
            end
            
            % multi-frames remaining
            fp = sprintf('%s_op_%sr1_frame%i', ...
                sessde.tracerRevision('typ','fp'), ...
                sessde.tracerEpoch('typ','fp'), ...
                nFrames - nEpochs*this.maxLengthEpoch); % fdgv1e4r2_op_fdgv1e4r1_frame1
            ffp = Fourdfp.load([fp '.4dfp.hdr']);
            ffp0.img(:,:,:,remainingFrames) = ffp.img;
            popd(pwd1);            
            ffp0.save;
            popd(pwd0);
            this = this.packageProduct(ffp0);
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
            tr = mlfourdfp.Fourdfp.load(this.sessionData.tracerRevision);
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
        function this = sumProduct(this)
            assert(isa(this.product_, 'mlfourd.ImagingContext'))
            if (this.buildVisitor.lexist_4dfp([this.product_.fqfp '_sumt']))
                this.product_ = mlfourd.ImagingContext([this.product_.fqfp '_sumt.4dfp.hdr']);
                return
            end
            sz = this.size_4dfp(this.product_);
            if (length(sz) < 4 || sz(4) == 1)
                return
            end
            this.product_ = this.product_.timeSummed;
            this.product_.fourdfp;
            this.product_.save; % _sumt
        end
		  
        %%
        
 		function this = TracerResolveBuilder(varargin)
            %% TRACERRESOLVEBUILDER
            %  @param named 'logger' is an mlpipeline.AbstractLogger.
            %  @param named 'product' is the initial state of the product to build; default := [].
            %  @param named 'sessionData' is an mlpipeline.ISessionData; default := [].
 			%  @param named 'buildVisitor' is an mlfourdfp.FourdfpVisitor.
            %  @param named 'roisBuilder' is an mlrois.IRoisBuilder.
            %  @param named 'resolveBuilder' is an mlfourdfp.T4ResolveBuilder.
            %  @param named 'compositeResolveBuilder' is an mlfourdp.CompositeT4ResolveBuilder.
            %  @param named 'vendorSupport' is, e.g., mlsiemens.MMRBuilder.
            %  @param named 'umapSynthFqfn' is the f.-q.-filename of prepared CT.  
            %  @return instance ready for t4-resolve management of tracer data.  
            
 			this = this@mlpet.TracerBuilder(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'umapSynthFqfn', this.sessionData.umapSynthOpT1001, ...
                @(x) lexist(x, 'file'));
            addParameter(ip, 'f2rep', [], @isnumeric);
            addParameter(ip, 'fsrc',  [], @isnumeric);
            parse(ip, varargin{:});
            this.umapSynthFqfn_ = ip.Results.umapSynthFqfn;
            this.f2rep          = ip.Results.f2rep;
            this.fsrc           = ip.Results.fsrc;
            this                = this.updateFinished;            
        end
    end 
    
    %% PROTECTED    
    
    properties (Access = protected)
        aComposite_ % cell array for simplicity
        nEpochs_
        umapSynthFqfn_
    end
    
    methods (Access = protected)
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
        function this = partitionUmaps(this)
            %  saves umap frames to the filesystem.
            
            tNac = zeros(1, length(this.tauFramesNAC));
            for iNac = 1:length(this.tauFramesNAC)
                tNac(iNac) = sum(this.tauFramesNAC(1:iNac)); % end of frame
            end
            
            import mlfourd.*;
            umaps = ImagingContext(this.sessionData.umap('','typ','.4dfp.hdr'));
            umap0 = umaps.fourdfp;
            umap0.img = umap0.img(:,:,:,1);
            assert(length(tNac) == umaps.fourdfp.size(4));
            
            iNac = 0;
            while (iNac < length(tNac))
                umap = umap0;
                umap.img = umaps.fourdfp.img(:,:,:,iNac+1);
                umap.fqfileprefix = this.sessionData.umap('', 'frame', iNac); 
                umap.save;
                umapComposite(iNac+1) = umap;
                iNac = iNac + 1;
            end
            this.product_ = ImagingContext(umapComposite);
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
            import mlfourdfp.Fourdfp;
            aufbau4dfp = Fourdfp.load(those(1).product.fqfilename);
            e = 1;
            while (e < length(those))
                e = e + 1;
                if (lexist_4dfp(       those(e).tracerResolvedSumt))
                    ffp = Fourdfp.load(those(e).tracerResolvedSumt); % fdgv1e*r2_sumt
                elseif (lexist_4dfp(   those(e).tracerRevision))
                    ffp = Fourdfp.load(those(e).tracerRevision); % fdgv1e*r2
                else
                    error('mlpet:filesystemErr', ...
                        'TracerResolveBuilder.reconstituteComposites could not find %s', those(e).tracerRevision);
                end
                aufbau4dfp.img(:,:,:,e) = ffp.img;
            end  
            
            % update this.{resolveBuilder_,sessionData_,product_}
            this.resolveBuilder_.resolveTag = ''; % CRUFT?
            this.sessionData_.epoch         = 1:length(those);
            this.sessionData_.rnumber       = 1; 
            aufbau4dfp.fqfilename           = this.sessionData_.tracerRevision; % E1to9/fdgv1e1to9r1
            this.product_                   = ImagingContext(aufbau4dfp);
            ensuredir(this.product_.filepath);
            if (~lexist(this.product_.fqfilename, 'file'))
                this.product_.save;
            end
        end	
        function ffp  = reconstituteFrame(this, varargin)
            %  @param named sessionData is an mlpipeline.SessionData.
            %  @param this.sessionData.tracerListmodeMhdr exists.
            %  @param named frame is numeric.
            %  @param named fqfp is the f. q. fileprefix of a frame of the tracer study.
            %  @return ffp is an mlfourdfp.Fourdfp containing the frame.
            
            fqfp0 = this.sessionData_.tracerRevision('frame', this.sessionData_.frame, 'typ', 'fqfp');
            ip = inputParser;
            addRequired(ip, 'sessionData', @(x) isa(x, 'mlpipeline.SessionData'));
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
            ffp = mlfourdfp.Fourdfp.load([fqfp0 '.4dfp.hdr']);
            popd(pwd0);
            %ffp.fqfileprefix = this.sessionData_.tracerRevision('typ', 'fqfp');
            %ffp.img = zeros(size(ffp));
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
            
            mono4dfp.img = mono4dfp.img(:,:,:,this.partitionEpochFrames(monoBldr));
            mono4dfp.fqfileprefix = this.tracerRevision('typ', 'fqfp');
            mono4dfp.save;
            this.product_ = mono4dfp;
        end
        function fn   = scrubbingLogFilename(~, sessd)
            dt = mlsystem.DirTool( ...
                fullfile(sessd.tracerLocation, 'Log', ...
                    sprintf('%s_T4ResolveBuilder_imageReg_D*.log', sessd.tracerRevision('typ','fp'))));
            assert(~isempty(dt.fqfns));
            fn = dt.fqfns{end};
        end
        function sz   = size_4dfp(this, obj)
            %% SIZETRACERREVISION
            %  @return sz, the size of the image data specified by this.tracerRevision.
            
            assert(this.buildVisitor.lexist_4dfp(obj.fqfileprefix));
            sz = this.buildVisitor.ifhMatrixSize(obj.fqfileprefix);
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
            ffp   = mlfourdfp.Fourdfp.load([dest_ '.4dfp.hdr']);
            
            deleteExisting([dest_ '__.4dfp.*']);
            deleteExisting([dest_ '___.4dfp.*']);
        end    
    end
    
    %% PRIVATE
    
    methods (Access = private)
        function        assertUmap(this, obj)
            assert(lstrfind(obj.fileprefix, 'umap'));
            sz = this.size_4dfp(obj);
            assert(3 == length(sz) || 1 == sz(4));
        end
        function [e,e1] = getEpochIndices(this, nacFrame)
            e  = floor(nacFrame/this.maxLengthEpoch) + 1;
            e1 = mod(  nacFrame,this.maxLengthEpoch) + 1;  
        end
        function ffp  = confirmAufbau4dfp(~, ffp)
            %% avoids empty ffp.img when rerunning this builder on previously built intermediate products.
            
            assert(isa(ffp, 'mlfourdfp.Fourdfp'));
            if (isempty(ffp.img))
                warning('mlpet:ValueWarning', ...
                    'TracerResolveBuilder.confirmAufbau4dfp received %s; attempting to reconstruct', ...
                    evalc('disp(ffp)'));
                ffp = mlfourdfp.Fourdfp.load([ffp.fqfileprefix '.4dfp.hdr']);
            end
        end
        function cRB  = reconcileUmapFilenames(~, cRB, varargin)
            %  @param  cRB has preferred umap packaged as its product{ele}. 
            %  @param  ele is the preferred element location in product; default := length(product)-1.
            %  @return cRB with legacy umap on the filesystem and packaged as its product.
            
            ip = inputParser;
            addOptional(ip, 'ele', length(cRB.product), @isnumeric);
            parse(ip, varargin{:});
            
            fqfp = cRB.product{ip.Results.ele}.fqfileprefix;
            fp1  = cRB.umap(cRB.resolveTag, 'typ', 'fp');
            assert(lstrfind(fqfp, 'umap'));
            assert(lexist_4dfp(fqfp));
            xs = {'.4dfp.ifh' '.4dfp.hdr' '.4dfp.img' '.4dfp.img.rec'};
            cellfun(@(x) copyfile([fqfp x], [fp1 x], 'f'), xs, 'UniformOutput', false);
            cRB = cRB.packageProduct(fp1);
        end
        function t4   = t4ForReconstituteFramesAC2(this, epoch, sessd1toN)
            switch (this.resolveBuilder.NRevisions)
                case 1
                    t4 = [sessd1toN.tracerRevision('frame', epoch, 'typ','fqfp') '_to_' sessd1toN.resolveTag '_t4'];
                case 2
                    sdr1 = sessd1toN; sdr1.rnumber = 1;
                    sdr2 = sessd1toN; sdr2.rnumber = 2;
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
        function this = umapAufbau(this)
            %  @return this:  this.product is the multi-frame umap as mlfourdfp.Fourdfp.
                   
            if (1 == this.nFramesModMaxLengthEpoch) % KLUDGE preservation of what was working with FDG, 2017oct11
                this = this.umapAufbau0;
                return
            end
            
            import mlfourd.* mlfourdfp.*;
            fprintf('TracerResolveBuilder.umapAufbau:  working in %s\n', pwd);            
            sessd = this.sessionData;
            sessd.rnumber = 1;    
            tracerSz = this.size_4dfp(ImagingContext(sessd.tracerRevision)); 
            nEpoch = ceil(tracerSz(4)/this.maxLengthEpoch);     
            
            sessd1 = sessd;
            sessd1.epoch = 1;
            sessd1.resolveTag = sessd1.resolveTagFrame(this.maxLengthEpoch, 'reset', true);
            umap = ImagingContext(sessd1.umap(sessd1.resolveTag));
            umapFfp = umap.fourdfp;
            umapFfp.fqfilename = [sessd.umap('') '.4dfp.hdr'];
            umapSz = umapFfp.size;
            umapFfp.img = zeros(umapSz(1),umapSz(2),umapSz(3),tracerSz(4));
            for ep = 1:nEpoch
                if (ep == nEpoch)
                    Nfr = this.nFramesModMaxLengthEpoch;
                else
                    Nfr = this.maxLengthEpoch;
                end
                for fr = 1:Nfr
                    sessd_ = sessd;
                    sessd_.epoch = ep;
                    sessd_.resolveTag = sessd_.resolveTagFrame(fr, 'reset', true);
                    frame_ = NIfTId.load(sessd_.umap(sessd_.resolveTag));
                    umapFfp.img(:,:,:,this.maxLengthEpoch*(ep-1)+fr) = frame_.img;
                end
            end
            umapFfp.save;
            this.product_ = umapFfp;
        end
        function this = umapAufbau0(this)
            %  @return this:  this.product is the multi-frame umap as mlfourdfp.Fourdfp.
            
            import mlfourd.* mlfourdfp.*;
            fprintf('TracerResolveBuilder.umapAufbau0:  working in %s\n', pwd);            
            sessd = this.sessionData;
            sessd.rnumber = 1;    
            tracerSz = this.size_4dfp(ImagingContext(sessd.tracerRevision)); 
            nEpoch = floor(tracerSz(4)/this.maxLengthEpoch); 
            %tracerFp = sessd.tracerRevision('typ', 'fp');
            %if (~this.buildVisitor.lexist_4dfp([tracerFp '_b43']))
            %    this.buildVisitor.imgblur_4dfp( tracerFp, 4.3);
            %end           
            
            sessd1 = sessd;
            sessd1.epoch = 1;
            sessd1.resolveTag = sessd1.resolveTagFrame(this.maxLengthEpoch, 'reset', true);
            umap = ImagingContext(sessd1.umap(sessd1.resolveTag));
            umapFfp = umap.fourdfp;
            umapFfp.fqfilename = [sessd.umap('') '.4dfp.hdr'];
            umapSz = umapFfp.size;
            umapFfp.img = zeros(umapSz(1),umapSz(2),umapSz(3),tracerSz(4));
            for ep = 1:nEpoch
                for fr = 1:this.maxLengthEpoch
                    sessd_ = sessd;
                    sessd_.epoch = ep;
                    sessd_.resolveTag = sessd_.resolveTagFrame(fr, 'reset', true);
                    frame_ = NIfTId.load(sessd_.umap(sessd_.resolveTag));
                    umapFfp.img(:,:,:,this.maxLengthEpoch*(ep-1)+fr) = frame_.img;
                end
            end
            tLast = nEpoch*this.maxLengthEpoch;
            frame_ = NIfTId.load(this.product.fqfilename);
            frameSz_ = frame_.size;
            if (length(frameSz_) < 4)
               umapFfp.img(:,:,:,tracerSz(4))  = frame_.img;
            else
                for frameT = 1:frameSz_(4)
                    umapFfp.img(:,:,:,tLast+frameT) = frame_.img(:,:,:,frameT);
                end
            end
            umapFfp.save;
            this.product_ = umapFfp;
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

