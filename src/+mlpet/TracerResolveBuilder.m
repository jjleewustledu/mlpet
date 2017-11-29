classdef TracerResolveBuilder < mlpet.TracerBuilder
	%% TRACERRESOLVEBUILDER can create t4-resolved images hierarchically managed with cardinalities
    %  |session| >= |visit| > |tracer-monolith| >= |epoch| >= |frame|.  Construction intermediates
    %  are stored in this.product as described by the GoF.  

	%  $Revision$
 	%  was created 18-Aug-2017 13:57:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
     
    properties (Constant)
        TAUS_FDG = [30,30,30,30,30,30,30,30,30,30,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60]
        TAUS_OC = [30,30,30,30,30,30,30,30,30,30,30,30,30,30]
        TAUS_OO = [30,30,30,30,30,30,30,30,30,30]
        TAUS_HO = [30,30,30,30,30,30,30,30,30,30]
    end
    
    properties
        ctSourceFqfn % fqfilename
        f2rep
        fsrc
    end    
    
    properties (Dependent)
        ctSourceFp
        imgblurTag
        maxLengthEpoch
        nFramesAC
        tauFramesNAC
    end

	methods 
        
        %% GET
        
        function g = get.ctSourceFp(this)
            g = mybasename(this.ctSourceFqfn);
        end
        function g = get.imgblurTag(this)
            g = this.sessionData_.petPointSpread('tag_imgblur_4dfp', true);
        end
        function g = get.maxLengthEpoch(this)
            g = this.maxLengthEpoch_;
        end
        function g = get.nFramesAC(this)
            switch (upper(this.sessionData.tracer))
                case 'FDG'
                    if (strcmp(this.sessionData.sessionFolder, 'HYGLY25'))
                        g = 77;
                        return
                    end
                    g = 85;
                case 'OC'
                    g = 70;                    
                case 'OO'
                    g = 58;
                case 'HO'
                    g = 58;
                otherwise
                    error('mlpet:unsupportedSwitchCase', ...
                        'TracerResolveBuilder.get.nFramesAC does not support this.sessionData.tracer->%s', ...
                        this.sessionData.tracer);
            end
        end
        function g = get.tauFramesNAC(this)
            switch (upper(this.sessionData.tracer))
                case 'FDG'
                    % \Sigma\tau^{\text{nac}}_i = 3600 s; N(tau^{\text{nac}}_i) = 65                    
                    if (strcmp(this.sessionData.sessionFolder, 'HYGLY25'))
                        g = this.TAUS_FDG(1:57);
                        return
                    end
                    g = this.TAUS_FDG;
                case {'CO' 'OC'}
                    g = this.TAUS_OC;
                case {'HO' 'OH' 'OO'}
                    g = this.TAUS_OO;
                otherwise
                    error('mlpet:unsupportedSwitchCase', ...
                        'TracerResolveBuilder.get.tauFramesNAC does not support this.sessionData.tracer->%s', ...
                        this.sessionData.tracer);
            end
            assert(~isempty(this.product));
            sizeProd = size(this.product);
            g = g(1:sizeProd(4));
        end
        
        function this = set.maxLengthEpoch(this, s)
            assert(isnumeric(s));
            this.maxLengthEpoch_ = s;
        end
        
        %%
        
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
                tr.img(:,:,:,f) = imgsrc;
            end
            tr.save;
        end
        function [this,monolith] = partitionMonolith(this)
            %% PARTITIONMONOLITH into composite {TracerResolveBuilders}; monolithic tracerRevision is partitioned.
            %  @param  this.tracerRevision exists.
            %  @param  this.maxLengthEpoch is integer > 0.  
            %  @return with identity if rank(monolith) < 4.
            %  @return this := composite {TracerResolveBuilder} with partitioning of monolith into epochs with each 
            %          |epoch| <= this.maxLengthEpoch if rank(monolith) == 4.  
            %          Save epochs if not already on filesystem.  
            %          length(this) := ceil(this.sizeTracerRevision/this.maxLengthEpoch).
            %  @return this.epoch as determined by this.partitionEpochFrames.
            %  @return monolith := struct, fields := {sessionData, imagingContext}, with pre-partitioning state for 
            %          later use; use FilenameState to minimize memory footprint.
            %  See also:  mlpipeline.RootDataBuilder.
            
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4))
                return
            end
            
            import mlfourd.*;
            if (thisSz(4) > this.maxLengthEpoch)
                monoBldr                = this;
                monolith.sessionData    = monoBldr.sessionData;
                monolith.imagingContext = ImagingContext(monoBldr.tracerRevision); % small memory footprint
                mono                    = ImagingContext(monoBldr.tracerRevision);
                monoFfp                 = mono.fourdfp;
                this.nEpochs_           = ceil(thisSz(4)/this.maxLengthEpoch);
                for e = 1:this.nEpochs_
                    this(e) = monoBldr;
                    this(e).sessionData_.epoch = e;
                    ice = ImagingContext(this(e).tracerRevision);
                    if (~this(e).buildVisitor.lexist_4dfp(ice.fqfileprefix))
                        ensuredir(ice.filepath);
                        this(e) = this(e).saveEpoch(monoBldr, monoFfp);
                    else
                        this(e).product_ = ice;
                    end
                end
            end
        end
        function [this,multiEpochOfSummed,reconstitutedSummed] = motionCorrectFrames(this)
            %% MOTIONCORRECTFRAMES 
            %  @param  this.product        := composite multi-epoch of frames created by this.partitionMonolith.
            %  @return this                := composite multi-epoch {TracerResolveBuilder} 
            %                                 each containing motion-corrected frames.
            %                                 composite this contains all available frames.
            %  @return multiEpochOfSummed  := composite multi-epoch {TracerResolveBuilder} 
            %                                 each containing summed motion-corrected frames.
            %  @return reconstitutedSummed := singlet TracerResolveBuilder containing summed motion-corrected frames.
                
            if (length(this) > 1)    
                
                % recursion over epochs to generate composite
                for e = 1:length(this)
                    [this(e),~,multiEpochOfSummed(e)] = this(e).motionCorrectFrames; 
                    % DEBUG:  execution of t4_resolve does not complete for e > 1.
                    % This appears to be over/underflow of the t4_resolve executable as of 2017nov1.
                    % Setting mlpet.TracerDirector.MAX_LENGTH_EPOCH_AC = 24.
                end
                singleEpoch = multiEpochOfSummed(1);
                singleEpoch = singleEpoch.reconstituteComposites(multiEpochOfSummed);
                [this,reconstitutedSummed] = singleEpoch.motionCorrectEpochs;
                return
            end
            
            % base case, returns singlet
            this.product_ = mlfourd.ImagingContext(this.tracerRevision);
            multiEpochOfSummed = [];
            [this,reconstitutedSummed] = this.motionCorrectEpochs; % DEBUG:  execution of t4_resolve does not complete.
        end
        function [this,summed] = motionCorrectEpochs(this)
            %% MOTIONCORRECTEPOCHS
            %  @param  this.sessionData is well-formed for the problem.
            %  @param  this.product is well-formed tracer as mlfourd.ImagingContext;
            %          e.g., after completing this.partitionMonolith this.product := E1/fdgv1e1r1.
            %  @return identity for rank(this.sessionData.tracerRevision) < 4.
            %  @return motion-corrected frames in this.{resolveBuilder,sessionData,product}.
            %          e.g., this.product := E*/fdgv1e*r2_op_fdgv1e*r1_frame*
            %  @return summed motion-corrected frames in \Sigma_{\text{frames}} summed.
            %          e.g., summed.product := E*/fdgv1e*r2_op_fdgv1e*r1_frame*_sumt
            
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4)) % thisSz(4) == duration of this epoch
                summed = this;
                return 
            end            
            
            rB_ = mlfourdfp.T4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', this.product_.fqfileprefix, ...
                'indexOfReference', thisSz(4), ...
                'NRevisions', 2, ...
                'resolveTag', this.sessionData_.resolveTagFrame(thisSz(4), 'reset', true)); 
            
            % update this.{resolveBuilder_,sessionData_,product_}
            pwd0 = pushd(rB_.sessionData.tracerLocation);
            rB_                  = rB_.resolve; % DEBUG:  execution of t4_resolve does not complete.
            this.resolveBuilder_ = rB_;
            this.sessionData_    = rB_.sessionData; 
            this.product_        = rB_.product;            
            summed               = this.sumProduct;
            popd(pwd0);
        end
        function this = motionCorrectCTAndUmap(this)
            %% MOTIONCORRECTCTANDUMAP
            %  @param  this.sessionData is well-formed for the problem.
            %  @param  this.product is a single-epoch motion-corrected tracer.
            %          e.g., after completing this.motionCorrectFrames, 
            %          reconstitutedSummed.product := E1to9/fdgv1e1to9r2_op_fdgv1e1to9r1_frame9_sumt &&
            %          this := reconstitutedSummed.
            %  @param  this.ctSourceFqfn is the source of anatomical alignment for the motion-corrected umap.
            %  @return motion-corrections of this.ctSourceFqfn, T1, t2 onto this.product for 
            %          this.{compositeResolveBuilder,sessionData,product};
            %          e.g., this.product := umapSynth_to_op_fdgv1e1to9r1_frame9.
            
            pwd0 = pushd(this.product_.filepath);      
            this.locallyStageModalities('fourdfp', this.ctSourceFqfn);             
            this.sessionData_.rnumber = 1;
            bv = this.buildVisitor;
            
            switch (this.sessionData_.tracer)
                case {'OC' 'OO' 'HO'}
                    sessFdg = this.sessionData_;
                    sessFdg.tracer = 'FDG';
                    bv.lns_4dfp(sessFdg.tracerResolvedFinalSumt('typ','fqfp'));
                    theImages = {this.product_.fileprefix ... 
                                 this.ctSourceFp ...
                                 this.T1('typ','fp')}; % this.t2('typ','fp') sessFdg.tracerResolvedFinalSumt('typ','fp') 
                    cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                        'sessionData', this.sessionData_, ...
                        'theImages', theImages, ...
                        'NRevisions', 2);
                case 'FDG'
                    theImages = {this.product_.fileprefix ... 
                                 this.ctSourceFp ...
                                 this.T1('typ','fp') ...
                                 this.t2('typ','fp')};    
                    cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                        'sessionData', this.sessionData_, ...
                        'theImages', theImages, ...
                        'NRevisions', 2);
                otherwise
                    error('mlpet:unsupportedSwitchCase', ...
                          'TracerResolveBuilder.motionCorrectCTAndUmap....tracer->%s', ...
                          this.sessionData_.tracer);
            end
                        
            % update this.{compositeResolveBuilder_,sessionData_,product_}                      
            cRB_ = cRB_.resolve;             
            cRB_ = cRB_.t4img_4dfp( ...
                sprintf('%sr0_to_%s_t4', this.ctSourceFp, cRB_.resolveTag), ...
                cRB_.umapSynth('tracer', '', 'typ', 'fp'), ...
                'out', cRB_.umap(cRB_.resolveTag, 'typ', 'fp'), ...
                'options', sprintf('-O%s', theImages{1}));
            this.compositeResolveBuilder_ = cRB_;
            this.sessionData_             = cRB_.sessionData;
            this.product_                 = cRB_.product;            
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
            this = this.convertUmapsToE7Format;
            
        end
        function thisUncorrected = motionUncorrectToFrames(this, source, multiEpochOfSummed)
            %% MOTIONUNCORRECTTOFRAMES back-resolves a source in the space of some reference epoch to all available epochs.
            
            thisUncorrected = this.motionUncorrectToEpochs(source, multiEpochOfSummed);
                % thisUncorrected(${u}).product->E1to9/umapSynth_op_fdgv1e1to9r1_frame${u}
            for u = 1:length(thisUncorrected)
                multiEpochOfSummed(u).motionUncorrectToEpochs2( ...
                    thisUncorrected(u).product, multiEpochOfSummed(u), u == length(thisUncorrected));
            end
        end
        function thisUncorrected = motionUncorrectToEpochs(this, source, multiEpochOfSummed)
            %% MOTIONUNCORRECTTOEPOCHS back-resolves a source in the space of some reference epoch to all available epochs.
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
                thisUncorrected(idxRef) = this; %#ok<*AGROW>       
                if (idxRef == this.resolveBuilder_.indexOfReference)
                    continue
                end         
                try
                    childRB                  = this.resolveBuilder_;
                    childRB.rnumber          = 1;
                    childRB.indexOfReference = idxRef;  
                    childRB.resolveTag       = childRB.resolveTagFrame(idxRef, 'reset', true); % op_fdgv1e1to9r1_frame${idxRef};                      
                    childRB                  = childRB.updateFinished( ...
                        'tag2', sprintf('_motionUncorrectToEpochs_%s', source.fileprefix), ...
                        'neverTouch', multiEpochOfSummed(idxRef).getNeverTouch);
                    
                    childRB.skipT4imgAll = true;
                    childRB              = childRB.resolve; % childRB.product->${E}/umapSynth${e}r1_frame${idxRef}                                      
                    childRB.skipT4imgAll = false;                    
                    childRB              = childRB.t4img_4dfp( ...
                        this.parentToChildT4(childRB.resolveTag), ...
                        source.fqfileprefix, ...
                        'out', childRB.umap(childRB.resolveTag, 'typ', 'fp'), ...
                        'options', ['-O' this.sessionData.tracerResolved('typ','fp')]);
                        % t4     := E1to9/fdgv1e1to9r0_frame9_to_op_fdgv1e1to9r1_frame${idxRef}_t4; 
                        % source := E1to9/umapSynth_op_fdgv1e1to9r1_frame9;                         
                        % out    :=       umapSynth_op_fdgv1e1to9r1_frame${idxRef}, ${idxRef} != 9;                 
                    childRB.theImages    = childRB.tracerRevision('typ', 'fqfp');   
                    childRB.epoch        = idxRef;
                    
                    %% update thisMotionUncorrected(idxRef).{resolveBuilder_,sessionData_,product_}
                
                    thisUncorrected(idxRef).resolveBuilder_ = childRB; 
                    thisUncorrected(idxRef).sessionData_    = childRB.sessionData;                                    
                    thisUncorrected(idxRef).product_        = ImagingContext(this.resolveBuilder_.umap(childRB.resolveTag)); % ~ childRB.product;  
                    
                    fprintf('motionUncorrectToEpochs:\n');
                    fprintf('source.fqfileprefix->\n    %s\n', source.fqfileprefix); 
                        % E1to9/umapSynth_op_fdgv1e1to9r1_frame${e}; 
                    fprintf('this(%i).product->\n    %s\n\n', idxRef, char(thisUncorrected(idxRef).product)); 
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
        function thisUncorrected = motionUncorrectToEpochs2(this, source, multiEpochOfSummed, lastEpoch)
            %% MOTIONUNCORRECTTOEPOCHS back-resolves a source in the space of some reference epoch to all available epochs.
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
                    thisUncorrected = this;
                    return
                end
            else 
                NRef = this.maxLengthEpoch;
            end
            for idxRef = 1:NRef
                
                %% resolve source to thisMotionUncorrected(idxRef)
                
                try
                    loc = this.resolveBuilder_.sessionData.tracerLocation;
                    ensuredir(loc);
                    pwd0 = pushd(loc); % E1, ..., E8;
                    thisUncorrected(idxRef) = this; %#ok<*AGROW>
                    childRB                  = this.resolveBuilder_;
                    childRB.rnumber          = 1;
                    childRB.indexOfReference = idxRef;  
                    childRB.resolveTag       = childRB.resolveTagFrame(idxRef, 'reset', true); % op_fdgv1${e}r1_frame${idxRef};                      
                    childRB                  = childRB.updateFinished( ...
                        'tag2', sprintf('_motionUncorrectToEpochs2_%s', source.fileprefix), ...
                        'neverTouch', multiEpochOfSummed.getNeverTouch);
                    
                    childRB.skipT4imgAll = true;
                    childRB              = childRB.resolve; % childRB.product->$E1to9/fdgv1e1to9r2_op_fdgv1${e}r1_frame${idxRef}
                    childRB.skipT4imgAll = false;                    
                    childRB              = childRB.t4img_4dfp( ...
                        multiEpochOfSummed.parentToChildT4(childRB.resolveTag), ...
                        source.fqfileprefix, ...
                        'out', childRB.umap(childRB.resolveTag, 'typ', 'fp'), ...
                        'options', ['-O' this.sessionData.tracerResolved('typ','fp')]);
                        % t4     := ${E}/fdgv1${e}r0_frame8_to_op_fdgv1${e}r1_frame${idxRef}_t4; 
                        % source := E1to9/umapSynth_op_fdgv1e1to9r1_frame${e};          
                        % out    :=       umapSynth_op_fdgv1${e}r1_frame${idxRef}               
                    childRB.theImages    = childRB.tracerRevision('typ', 'fqfp');   
                    childRB.epoch        = idxRef;
                    
                    %% update thisMotionUncorrected(idxRef).{resolveBuilder_,sessionData_,product_}
                
                    thisUncorrected(idxRef).resolveBuilder_ = childRB; 
                    thisUncorrected(idxRef).sessionData_    = childRB.sessionData;                                    
                    thisUncorrected(idxRef).product_        = ImagingContext(this.resolveBuilder_.umap(childRB.resolveTag)); % ~ childRB.product;  
                    
                    fprintf('motionUncorrectToEpochs2:\n');
                    fprintf('source.fqfileprefix->\n    %s\n', source.fqfileprefix); 
                        % E1to9/umapSynth_op_fdgv1e1to9r1_frame${e}; 
                    fprintf('this(%i).product->\n    %s\n\n', idxRef, char(thisUncorrected(idxRef).product)); 
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
        function t4 = parentToChildT4(this, resolveTag)
            tracerEpochParent = this.resolveBuilder_.tracerEpoch('typ','fqfp'); % E1to9/fdgv1e1to9
            idxRefParent      = this.resolveBuilder_.indexOfReference;          % 9
            t4 = sprintf('%sr0_frame%i_to_%s_t4', tracerEpochParent, idxRefParent, resolveTag);
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
                        'tag2', sprintf('_motionUncorrectUmapToEpochs_%s', umapOpParent.fileprefix));
                    
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
        function this = createUmapSynthFull(this)
            this.product_ = this.product_.zoomed([2 2 1 1]);
            nn = this.product_.numericalNiftid;
            for f = 1:size(nn, 4)
                nnFrame = nn;
                nnFrame.img = nn.img(:,:,:,f);
                nnFrame.fileprefix = this.sessionData.umap(sprintf('full_frame%i', f));
                nnFrame.save;
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
            nFrames = this.getNFrames;
            
            if (lexist(this.sessionData_.tracerRevision, 'file'))                
                % update this.{sessionData_,product_}
                this.sessionData_.rnumber = 1; 
                this.product_ = mlfourd.ImagingContext(this.sessionData_.tracerRevision);
                return
            end  
            
            %% create this.sessionData_.tracerRevision
            
            aufbau = this.reconstituteFrame(this.sessionData_, 0);
            aufbau.fqfilename = this.sessionData_.tracerRevision;
            assert(4 == length(aufbau.size) && aufbau.size(4) > 0);
            innerf = 0;
            this.sessionData_.frame = 1;
            while (isdir(this.sessionData_.tracerConvertedLocation))

                pwd0 = pushd(this.sessionData_.tracerLocation);
                fprintf('mlpet.TracerResolveBuilder.reconstituteFramesAC.this.sessionData_.tracerConvertedLocation -> \n%s\n', ...
                    this.sessionData_.tracerConvertedLocation);
                ffp = this.reconstituteFrame(this.sessionData_, this.sessionData_.frame);
                ffp = this.t4imgFromNac(ffp, nFrames);
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
            this.product_ = mlfourd.ImagingContext(aufbau);
            this.product_.save;
        end	
        function ffp  = reconstituteFrame(this, varargin)
            %  @param named sessionData is an mlpipeline.SessionData.
            %  @param this.sessionData.tracerListmodeMhdr exists.
            %  @param named frame is numeric.
            %  @param named fqfp is the f. q. fileprefix of a frame of the tracer study.
            %  @return ffp is an mlfourdfp.Fourdfp containing the frame.
            
            fqfp0 = fullfile(this.sessionData.tracerLocation, 'TracerResolveBuilder_reconstituteFrame_fqfp0');
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
            if (~bv.lexist_4dfp(sif_))
                bv.sif_4dfp(sd.tracerListmodeMhdr, sif_);
            end
            bv.cropfrac_4dfp(0.5, sif_, fqfp0);
            deleteExisting([sif_ '.4dfp.*']);
            ffp = mlfourdfp.Fourdfp.load([fqfp0 '.4dfp.ifh']);
            popd(pwd0);
            %ffp.fqfileprefix = this.sessionData_.tracerRevision('typ', 'fqfp');
            %ffp.img = zeros(size(ffp));
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
            sessd1to11 = sessd_;
            sessd1to11.epoch = 1:supEpochs;
            sessd1to11.frame = supEpochs;
            
            pwd0 = pushd(sessd_.tracerLocation);
            ffp0 = Fourdfp.load(sessd__.tracerRevision('frame', 1));
            sz = size(ffp0.img);
            ffp0.img = zeros(sz(1), sz(2), sz(3), nFrames);
            ffp0.fqfileprefix = sessd_.tracerResolved('typ', 'fqfp');
            fv = FourdfpVisitor;
            
            for e = 1:nEpochs
                sessde = sessd_;
                sessde.epoch = e;
                sessde.resolveTag = sprintf('%s%sr1_frame%i', sessde.resolveTagPrefix, sessde.tracerEpoch('typ','fp'), this.maxLengthEpoch);                
                pwd1 = pushd(sessde.tracerLocation);
                t4 = [sessd1to11.tracerRevision('frame', e, 'typ','fqfp') '_to_' sessd1to11.resolveTag '_t4'];
                % /data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V1/FDG_V1-AC/E1to11/fdgv1e1to11r2_frame1_to_op_fdgv1e1to11r1_frame11_t4
                % /data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V2/FDG_V2-AC/E1to11/fdgv2e1to11r2_frame1_to_op_fdgv2e1to11r1_frame11_t4
                fp = sessde.tracerResolved('typ', 'fp');
                % fdgv1e1r2_op_fdgv1e1r1_frame8
                % fdgv2e1r2_op_fdgv2e1r1_frame8
                fpDest = [sessde.tracerRevision('typ','fp') '_' sessd1to11.resolveTag];
                % fdgv1e1r2_op_fdgv1e1to11r1_frame11
                % fdgv2e1r2_op_fdgv2e1to11r1_frame11
                fv.t4img_4dfp(t4, fp, 'out', fpDest, 'options', ['-O' fp]);
                ffp = Fourdfp.load([fpDest '.4dfp.ifh']);
                ffp0.img(:,:,:,(e-1)*this.maxLengthEpoch+1:e*this.maxLengthEpoch) = ffp.img;
                popd(pwd1);
            end
            
            e = supEpochs;
            sessde = sessd_;
            sessde.epoch = e;
            pwd1 = pushd(sessde.tracerLocation);        
            fp = sprintf('%s_op_%sr1_frame%i', sessde.tracerRevision('typ','fp'), sessde.tracerEpoch('typ','fp'), nFrames - nEpochs*this.maxLengthEpoch);
            % fdgv2e11r2_op_fdgv2e11r1_frame5
            ffp = Fourdfp.load([fp '.4dfp.ifh']);
            ffp0.img(:,:,:,(e-1)*this.maxLengthEpoch+1:nFrames) = ffp.img;
            popd(pwd1);
            
            ffp0.save;
            %fv.imgblur_4dfp(ffp0.fqfileprefix, 4.3);
            popd(pwd0);
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
            %  @param named 'ctSourceFqfn' is the f.-q.-filename of prepared CT.  
            %  @return instance ready for t4-resolve management of tracer data.  
            
 			this = this@mlpet.TracerBuilder(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'ctSourceFqfn', ...
                fullfile(this.vLocation, 'ctMaskedOnT1001r2_op_T1001.4dfp.ifh'), ...
                @(x) lexist(x, 'file'));
            addParameter(ip, 'maxLengthEpoch', 8, @isnumeric)
            addParameter(ip, 'f2rep', [], @isnumeric);
            addParameter(ip, 'fsrc',  [], @isnumeric);
            parse(ip, varargin{:});
            this.ctSourceFqfn    = ip.Results.ctSourceFqfn;
            this.maxLengthEpoch_ = ip.Results.maxLengthEpoch;
            this.f2rep           = ip.Results.f2rep;
            this.fsrc            = ip.Results.fsrc;
            this = this.updateFinished;            
 		end
    end 
    
    %% PROTECTED    
    
    properties (Access = protected)
        aComposite_ % cell array for simplicity
        maxLengthEpoch_
        nEpochs_
    end
    
    methods (Access = protected)
        function        assertUmap(this, obj)
            assert(lstrfind(obj.fileprefix, 'umap'));
            sz = this.size_4dfp(obj);
            assert(3 == length(sz) || 1 == sz(4));
        end
        function nf   = nFramesModMaxLengthEpoch(this)
            sz = this.sizeTracerRevision;
            nf = mod(sz(4), this.maxLengthEpoch);
        end 
        function epochFrames = partitionEpochFrames(this, monoBldr)
            %% PARTITIONFRAMES 
            %  @param this corresponds to a partitioning of an epoch from all the frames of monolith.
            %  @param monoBldr is the TracerResolveBuilder for the monolithic tracer imaging data;
            %  monoBldr.sizeTracerRevision must have rank == 4.
            %  @return epochFrames specifies the indices of frames of monolith that correspond to this.epoch.
            
            monoSz = monoBldr.sizeTracerRevision;
            e = this.sessionData_.epoch;
            if (e*this.maxLengthEpoch > monoSz(4))
                epochFrames = (e-1)*this.maxLengthEpoch+1:monoSz(4); % remaining frames
                return
            end
            epochFrames = (e-1)*this.maxLengthEpoch+1:e*this.maxLengthEpoch; % partition of frames
        end
        function this = reconstituteComposites(this, those)
            %% RECONSTITUTECOMPOSITES contracts composite TracerResolveBuilder to singlet.
            %  @param this is singlet TracerResolveBuilder.
            %  @param those is composite TracerResolveBuilder;
            %  e.g., those(1) := fdgv1e1r2_op_fdgv1e1r1_frame8_sumt.
            %  @return this is singlet TracerResolveBuilder containing reconstitution of those onto this with updating of
            %  this.{sessionData.rnumber,resolveBuilder,epoch,product}.
            
            aufbauFfp = those(1).product.fourdfp;
            %assert(3 == aufbauFfp.rank);
            
            import mlfourd.*;
            bv = this.buildVisitor;
            e  = 1;
            while (e < length(those))
                e = e + 1;
                if (bv.lexist_4dfp(      those(e).tracerResolvedSumt))
                    icE = ImagingContext(those(e).tracerResolvedSumt); % fdgv1e*r2_sumt
                elseif (bv.lexist_4dfp(  those(e).tracerRevision))
                    icE = ImagingContext(those(e).tracerRevision); % fdgv1e*r2
                else
                    error('mlpet:filesystemErr', ...
                        'TracerResolveBuilder.reconstituteComposites could not find %s', those(e).tracerRevision);
                end
                aufbauFfp.img(:,:,:,e) = icE.fourdfp.img;
            end  
            
            % update this.{resolveBuilder_,sessionData_,product_}
            this.resolveBuilder_.resolveTag = ''; % CRUFT?
            this.sessionData_.epoch         = 1:length(those);
            this.sessionData_.rnumber       = 1; 
            aufbauFfp.fqfilename            = this.sessionData_.tracerRevision; % E1to9/fdgv1e1to9r1
            this.product_                   = ImagingContext(aufbauFfp);
            ensuredir(this.product_.filepath);
            if (~lexist(this.product_.fqfilename, 'file'))
                this.product_.save;
            end
        end	
        function this = saveEpoch(this, monoBldr, monoFfp)
            %% SAVEEPOCH
            %  @param this corresponds to a partitioning of an epoch from all the frames of monolith.
            %  @param monoBldir is the TracerResolveBuilder object for the monolith.
            %  @param monoFfp is ImagingContext.fourdfp for the monolithic tracer imaging data;
            %  monolith.sizeTracerRevision must have rank == 4.
            %  @return this.product := saved partitioning of monolith at this.epoch cast as ImagingContext, 
            %  stateTypeclass mlfourd.FourdfpState.
            
            monoFfp.img = monoFfp.img(:,:,:,this.partitionEpochFrames(monoBldr));
            monoFfp.fqfileprefix = this.tracerRevision('typ', 'fqfp');
            monoFfp.save;
            this.product_ = monoFfp;
        end
        function sz   = size_4dfp(this, obj)
            %% SIZETRACERREVISION
            %  @return sz, the size of the image data specified by this.tracerRevision.
            
            assert(this.buildVisitor.lexist_4dfp( obj.fqfileprefix));
            sz = this.buildVisitor.ifhMatrixSize([obj.fqfileprefix '.4dfp.ifh']);
        end
        function sz   = sizeProduct(this)
            %% SIZEPRODUCT
            %  @return sz, the size of the image data specified by this.tracerRevision.
            
            assert(this.buildVisitor.lexist_4dfp( this.product.fqfileprefix));
            sz = this.buildVisitor.ifhMatrixSize([this.product.fqfileprefix '.4dfp.ifh']);
        end
        function sz   = sizeTracerRevision(this)
            %% SIZETRACERREVISION
            %  @return sz, the size of the image data specified by this.tracerRevision.
            
            sessd_ = this.sessionData_;
            sessd_.rnumber = 1;
            assert(this.buildVisitor.lexist_4dfp(sessd_.tracerRevision('typ','fqfp')));
            sz = this.buildVisitor.ifhMatrixSize(sessd_.tracerRevision('typ', '4dfp.ifh'));
        end
        function this = sumProduct(this)
            assert(isa(this.product_, 'mlfourd.ImagingContext'))
            if (this.buildVisitor.lexist_4dfp([this.product_.fqfp '_sumt']))
                this.product_ = mlfourd.ImagingContext([this.product_.fqfp '_sumt.4dfp.ifh']);
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
        function        touchFinishedMarker(this)
            this.finished.touchFinishedMarker;   
        end
        
        function this = convertUmapsToE7Format(this)
            sz  = this.sizeTracerRevision;
            fps = cellfun(@(x) sprintf('umapSynth_frame%i', x), num2cell(0:sz(4)-1), 'UniformOutput', false);
            cub = mlfourdfp.CarneyUmapBuilder('sessionData', this.sessionData);
            cub = cub.convertUmapsToE7Format(fps);
            this.product_ = cub.product;
        end
        function this = partitionUmaps(this)
            
            tNac = zeros(1, length(this.tauFramesNAC));
            for iNac = 1:length(this.tauFramesNAC)
                tNac(iNac) = sum(this.tauFramesNAC(1:iNac)); % end of frame
            end
            
            import mlfourd.*;
            umaps = ImagingContext(this.sessionData.umap('','typ','.4dfp.ifh'));
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
            %tracerFp = sessd.tracerRevision('typ', 'fp');
            %if (~this.buildVisitor.lexist_4dfp([tracerFp '_b43']))
            %    this.buildVisitor.imgblur_4dfp( tracerFp, 4.3);
            %end           
            
            sessd1 = sessd;
            sessd1.epoch = 1;
            sessd1.resolveTag = sessd1.resolveTagFrame(this.maxLengthEpoch, 'reset', true);
            umap = ImagingContext(sessd1.umap(sessd1.resolveTag));
            umapFfp = umap.fourdfp;
            umapFfp.fqfilename = [sessd.umap('') '.4dfp.ifh'];
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
        
        function [epoch,epochSubframe] = getEpochIndices(this, nacFrame)
            epoch = floor(nacFrame/this.maxLengthEpoch) + 1;
            epochSubframe = mod(nacFrame, this.maxLengthEpoch) + 1;  
        end
        function N    = getNFrames(this)
            sessd = this.sessionData_;
            sessd.frame = 0;
            while (isdir(sessd.tracerConvertedLocation))
                sessd.frame = sessd.frame + 1;
            end
            assert(sessd.frame > 0);
            N = sessd.frame;
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
            ffp   = mlfourdfp.Fourdfp.load([dest_ '.4dfp.ifh']);
            
            deleteExisting([dest_ '__.4dfp.*']);
            deleteExisting([dest_ '___.4dfp.*']);
        end
        function fn   = scrubbingLogFilename(~, sessd)
            dt = mlsystem.DirTool( ...
                fullfile(sessd.tracerLocation, 'Log', ...
                    sprintf('%s_T4ResolveBuilder_imageReg_D*.log', sessd.tracerRevision('typ','fp'))));
            assert(~isempty(dt.fqfns));
            fn = dt.fqfns{end};
        end
        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
    
    %% HIDDEN
    
    methods (Hidden)
        function this = reconstituteFramesAC2__(this)
            %% RECONSTITUTEFRAMESAC2__ is the rapid prototype used to develop reconstituteFramesAC2.
            
            import mlfourdfp.*;            
            nFrames = 85;
            nEpochs = floor(nFrames/this.maxLengthEpoch);
            supEpochs = ceil(nFrames/this.maxLengthEpoch);
            sessd = this.sessionData;
            sessd.epoch = [];
            sessd.frame = nan;
            sessd.rnumber = 2;
            pwd0 = pushd(sessd.tracerLocation);            
            pthMulti = fullfile(sessd.tracerLocation, sprintf('E1to%i', supEpochs), '');
            % sessd.tracerLocation->/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V2/FDG_V2-AC
            ffp0 = Fourdfp.load('E1/fdgv1e1r1_frame1.4dfp.ifh');
            ffp0.img = zeros(size(this.product_.fourdfp));
            ffp0.fqfileprefix = fullfile(sessd.tracerLocation, sprintf('fdgv1r1_op_fdgv1e1to%ir1_frame%i', supEpochs, supEpochs));
            % /data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V2/FDG_V2-AC/fdgv1r1_op_fdgv1e1to11r1_frame11
            sessd.rnumber = 2;
            fv = mlfourdfp.FourdfpVisitor;
            
            for e = 1:nEpochs
                sessd.epoch = e;
                pwd1 = pushd(sessd.tracerLocation);
                % sessd.tracerLocation->/data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V2/FDG_V2-AC/E1
                t4 = fullfile(pthMulti, sprintf('fdgv1e1to%ir2_frame%i_to_op_fdgv1e1to%ir1_frame%i_t4', supEpochs, e, supEpochs, supEpochs));
                % /data/nil-bluearc/raichle/PPGdata/jjlee2/HYGLY28/V2/FDG_V2-AC/E1to11/fdgv1e1to11r2_frame1_to_op_fdgv1e1to11r1_frame11_t4
                fp = sprintf('fdgv1e%ir2_op_fdgv1e%ir1_frame%i', e, e, this.maxLengthEpoch);  % verify
                % fdgv1e1r2_op_fdgv1e1r1_frame8
                fpDest = sprintf('fdgv1e%ir2_op_fdgv1e%ir1_frame%i', e, e, supEpochs);
                % fdgv1e1r2_op_fdgv1e1r1_frame11
                fv.t4img_4dfp(t4, fp, 'out', fpDest, 'options', ['-O' fp]);
                ffp = Fourdfp.load([fpDest '.4dfp.ifh']);
                ffp0.img(:,:,:,(e-1)*this.maxLengthEpoch+1:e*this.maxLengthEpoch) = ffp.img;
                popd(pwd1);
            end
            
            e = supEpochs;
            sessd.epoch = e;
            pwd1 = pushd(sessd.tracerLocation);            
            fpDest = sprintf('fdgv1e%ir2_op_fdgv1e1to%ir1_frame%i', ...
                e, supEpochs, nFrames - nEpochs*this.maxLengthEpoch);
            ffp = Fourdfp.load([fpDest '.4dfp.ifh']);
            ffp0.img(:,:,:,(e-1)*this.maxLengthEpoch+1:end) = ffp.img;
            popd(pwd1);
            
            ffp0.save;
            %fv.imgblur_4dfp(ffp0.fqfileprefix, 4.3);
            popd(pwd0);
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
            umapFfp.fqfilename = [sessd.umap('') '.4dfp.ifh'];
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
 end

