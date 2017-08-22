classdef TracerResolveBuilder < mlpet.TracerBuilder
	%% TRACERRESOLVEBUILDER can create t4-resolved images hierarchically managed with cardinalities
    %  |session| >= |visit| > |tracer-monolith| >= |epoch| >= |frame|.  Construction intermediates
    %  are stored in this.product as described by the GoF.  

	%  $Revision$
 	%  was created 18-Aug-2017 13:57:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
     
    properties (Constant)
        MAX_LENGTH_EPOCH = 8
    end
    
    properties
        ctSourceForUmap % fqfilename
    end
    
    properties (Dependent)
              % frame_f; frame_1:frame_end
        epoch % |session| >= |visit| > |tracer-monolith| >= |epoch| >= |frame|
        epochLabel
        indexOfReference
        resolveTag
    end      

	methods 
        
        %% GET/SET
        
        function g = get.epoch(this)
            g = this.sessionData_.epoch;
        end
        function g = get.epochLabel(this)
            g = this.sessionData_.epochLabel;
        end
        function g = get.indexOfReference(this)
            g = this.sessionData.indexOfReference;
        end
        function g = get.resolveTag(this)
            g = this.sessionData.resolveTag;
        end
              
        function this = set.epoch(this, s)
            assert(isnumeric(s));
            this.sessionData.epoch = s;
        end
        function this = set.indexOfReference(this, s)
            assert(isnumeric(s));
            this.sessionData.indexOfReference = s;
        end
        function this = set.resolveTag(this, s)
            assert(ischar(s));
            this.sessionData.resolveTag = s;
        end  
        
        %%	
        
        function this = partitionMonolith(this)
            %% PARTITIONMONOLITH embedded in this monolith into composite of TracerResolveBuilders; 
            %  monolithic tracerRevision will be partitioned.
            %  @param this.tracerRevision exists.
            %  @param this.MAX_LENGTH_EPOCH is integer > 0.  
            %  @return without mutations if rank(monolith) < 4.
            %  @return composite TracerResolveBuilder with partitioning of tracer-monolith into epochs
            %  with each |epoch| <= this.MAX_LENGTH_EPOCH if rank(monolith) == 4.  
            %  Epochs are saved if not already on filesystem.
            %  @return this.epoch as determined by this.partitionFrames.
            %  See also:  mlpipeline.RootDataBuilder.
            
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4))
                return
            end
            
            if (thisSz(4) > this.MAX_LENGTH_EPOCH)
                monolith = this;
                monoIc   = ImagingContext(monolith.tracerRevision);
                monoFfp  = monoIc.fourdfp;
                import mlfourd.*;
                nEpochs = ceil(thisSz(4)/this.MAX_LENGTH_EPOCH);
                for e = 1:nEpochs
                    this(e) = monolith;
                    this(e).epoch = e;
                    ice  = ImagingContext(this(e).tracerRevision);
                    if (~this(e).buildVisitor.lexist_4dfp(ice.fqfileprefix))
                        this(e).epoch = this(e).partitionFrames(monolith);
                        this(e) = this(e).saveEpoch(monoFfp);
                    else
                        this(e).product_ = ice;
                    end
                end
            end
        end
        function this = motionCorrectFrames(this)
            %% MOTIONCORRECTNACFRAMES may split the monolith image into partitioned epochs 
            %  using hierarchically organized data and filesystems.
            %  @return single motion-corrected epoch.
            %  @return creation of multiple, composite, motion-corrected epochs; a single parent epoch is the 
            %  the motion-correction of summed images of its children.
                
            % recursion over epochs
            if (length(this) > 1)             
                for e = 1:length(this)
                    this(e) = this(e).motionCorrectFrames;
                end
                that = this(1);
                that = that.reconstituteComposites(this);
                this = that.motionCorrectEpochs;
                return
            end
            
            % base of recursion
            this.product_ = mlfourd.ImagingContext(this.tracerRevision); % fdgv1e*r1
            this = this.motionCorrectEpochs;
        end
        function this = motionCorrectEpochs(this)
            %% MOTIONCORRECTEPOCHS
            %  @param this.sessionData is well-formed for the problem.
            %  @param this.product is well-formed; e.g., after completing this.partitionMonolith.
            %  @return without mutations for rank(this.tracerRevision) < 4.
            %  @return motion-corrected mutations for this.{indexOfReference,resolveTag,resolveBuilder,sessionData,product}.
            %  @return results of this.sumProduct.
            
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4))
                return % product := fdgv1e*r1.4dfp.ifh
            end
            
            this.indexOfReference = thisSz(4); % duration of this epoch
            this.resolveTag       = this.resolveTagFrame(this.indexOfReference);
            this.resolveBuilder_  = mlfourdfp.T4ResolveBuilder( ...
                'sessionData', this.sessionData, ...
                'theImages', this.product.fqfileprefix, ...
                'indexOfReference', this.indexOfReference, ...
                'NRevisions', 2); 
            this.resolveBuilder_  = this.resolveBuilder_.resolve('resolveTag', this.resolveTag);
            this.sessionData_     = this.resolveBuilder_.sessionData; 
            % tracerRevision := fdgv1e*r2.4dfp.ifh; e1-e9, e1to9
            % resolveTag := op_fdgv1e*r1_frame*; e1-e9, e1to9
            this.product_         = this.resolveBuilder_.product;
            % product := fdgv1e*r2_op_fdgv1e*r1_frame*.4dfp.ifh
            this                  = this.sumProduct;
            % product := fdgv1e*r2_op_fdgv1e*r1_frame*_sumt.4dfp.ifh
        end
        function this = motionCorrectModalities(this)
            %% MOTIONCORRECTMODALITIES
            %  @param this.sessionData is well-formed for the problem.
            %  @param this.product is well-formed tracer as mlfourd.ImagingContext; 
            %  e.g., after completing this.motionCorrectFrames.
            %  @param motion-corrected umap is created from this.ctSourceForUmap.
            %  @return t4-resolve results on tracer, this.ctSourceForUmap, T1, t2
            %  @return mutations to this.{compositeResolveBuilder,sessionData,product}.
            
            %assert(strcmp(this.resolveTag, 'op_fdgv1e1to9r1_frame9'));  
            this.sessionData_.rnumber = 1;
            this.buildVisitor.lns_4dfp(this.ctSourceForUmap);
            this.locallyStageModalities;
            
            ctFp      = mybasename(this.ctSourceForUmap);
            theImages = {this.product_.fileprefix ... 
                         ctFp ...
                         this.T1( 'typ','fp') ...
                         this.t2( 'typ','fp')}; 
                         % 'fdgv1e1to9r2_op_fdgv1e1to9r1_frame9_sumt' 
            pwd0 = this.product_.filepath;             
            this.compositeResolveBuilder_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData, ...
                'theImages', theImages, ...
                'NRevisions', 2);               
            this.compositeResolveBuilder_ = this.compositeResolveBuilder_.resolve; 
            this.compositeResolveBuilder_ = this.compositeResolveBuilder_.t4img_4dfp( ...
                fullfile(pwd0, sprintf('%sr0_to_%s_t4', ctFp, this.compositeResolveBuilder_.resolveTag)), ...
                fullfile(pwd0, this.umapSynth('tracer', '', 'typ', 'fp')), ...
                'out', fullfile(pwd0, this.umap(this.compositeResolveBuilder_.resolveTag, 'typ', 'fp')));
            this.sessionData_ = this.compositeResolveBuilder_.sessionData;
            this.product_     = this.compositeResolveBuilder_.product;
        end
        function this = motionUncorrectUmap(this)
            %% MOTIONUNCORRECTUMAP
            %  @param this.motionCorrectModalities has completed successfully with motion-corrected umap 
            %  contained in this.product.
            %  @return this.product := this.umapSynth back-resolved to all original frames of tracer monolith.
            
            assert(strcmp(this.compositeResolveBuilder.product, 'umapSynth_op_fdgv1e1to9r1_frame9'));
            this = this.motionUncorrectUmapToFrames( ...
                this.compositeResolveBuilder.product);
        end
        function this = motionUncorrectUmapToFrames(this, umapOpParentFqfp)
            %% MOTIONUNCORRECTUMAPTOFRAMES uses previously split and motion-corrected monolithic image with 
            %  hierarchically partitioned epochs.  The internally specified umap is back-resolved onto the hierarchy.
            %  @return single back-resolved umap.
            %  @return multiple, internally stored back-projections and a single back-resolution onto the 
            %  the motion-correction of the summed images from descendent branches of the partitioning hierarchy tree.            
            
            % base of recursion
            % this.product_ obtained from this.motionCorrectFrames
            that = this;
            this = this.motionUncorrectUmapToEpochs(umapOpParentFqfp); 
            this = that.reconstituteComposites(this);
            
            % recursion over epochs
            if (length(this) > 1)   
                for e = 1:length(this)
                    this(e) = this(e).motionUncorrectUmapToFrames(this(e).product);                    
                end
                return
            end           
        end
        function this = motionUncorrectUmapToEpochs(this, umapOpParentFqfp)
            %% MOTIONUNCORRECTUMAPTOEPOCHS back-resolves an image aligned with a single frame onto all frames.
            %  @param rank(this.sizeTracerRevision) < 3 => return without mutation.
            %  @param this.motionCorrectFrames has run successfully, creating this.resolveBuilder.
            %  @param umapOpParentFqfp is the image aligned with a single frame to be back-resolve.
            %  @return umapOpParentFqfp back-resolved to all available frames, 1:this.sizeTracerRevision.  
            %  @return this is composite with respect to {indexOfReference}.
            
            assert(~isempty(this.resolveBuilder_), 'ensure motionCorrectFrames has completed successfully');
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4))
                this.resolveBuilder_.theImages = this.resolveBuilder_.tracerRevision;
                this.sessionData_              = this.resolveBuilder_.sessionData;
                this.product_                  = this.resolveBuilder_.product;
                return
                % return, but must then use singleton from parent image to motion-uncorrect the umap
                % error('mlpet:notImplemented', ...
                %     'TracerResolveBuilder.motionUncorrectUmapToEpochs needs to motion-uncorrect singleton epochs');
            end            
            
            prev            = this;
            tracerEpochPrev = prev.resolveBuilder_.tracerEpoch('typ','fqfp');
            idxRefPrev      = prev.resolveBuilder_.indexOfReference;
            
            for idxRef = 1:thisSz(4)
                
                outFqfp = this(idxRef).umap(this(idxRef).resolveTag, 'typ', 'fqfp');
                if (~lexist(this(idxRef).umap(this(idxRef).resolveTag)))
                    % resolve umapOpParentFqfp to idxOfRef
                    this(idxRef) = prev;
                    this(idxRef).resolveTag = '';
                    this(idxRef).resolveTag = this(idxRef).resolveTagFrame(idxRef);
                    %assert(strcmp(this(idxRef).resolveTag, sprintf('op_fdgv1%sr1_frame%i', this(idxRef).epochLabel, idxRef)));
                    this(idxRef).resolveBuilder_.indexOfReference = idxRef;  
                    this(idxRef).resolveBuilder_.rnumber = 1;
                    this(idxRef).resolveBuilder_ = this(idxRef).resolveBuilder_.resolve('resolveTag', this(idxRef).resolveTag);
                    this(idxRef).resolveBuilder_ = this(idxRef).resolveBuilder_.t4img_4dfp( ...
                        sprintf('%sr0_frame%i_to_%s_t4', tracerEpochPrev, idxRefPrev, this(idxRef).resolveTag), ...
                        umapOpParentFqfp, ...
                        'out', outFqfp);
                        % t4     := fdgv1e1to9r2_frame9_to_op_fdgv1e1to9r1_frame[1-9]
                        % source := umapSynth_op_T1001_b40r2_op_fdgv1e1to9r1_frame9
                        % out    := umapSynth_op_fdgv1e1to9r1_frame[1-9]     
                    this(idxRef).resolveBuilder_.epoch     = idxRef;
                    this(idxRef).resolveBuilder_.theImages = this(idxRef).resolveBuilder_.tracerRevision;
                    this(idxRef).sessionData_              = this(idxRef).resolveBuilder_.sessionData;                                                          
                    this(idxRef).product_                  = this(idxRef).resolveBuilder_.product;
                    fprintf('motionUncorrectUmapToEpochs:\n');
                    fprintf('this(%i).product->%s; \numapOpParentFqfp->%s\n', idxRef, this(idxRef).product, umapOpParentFqfp);
                end
            end
        end
        function this = reconstituteComposites(this, those)
            %% RECONSTITUTECOMPOSITES
            %  @param this is singleton
            %  @param those is composite
            %  @return this is singleton containing reconstitution of those onto this with updating of
            %  this.{sessionData.rnumber,resolveTag,epoch,product}.
            
            import mlfourd.*;
            e   = 1;
            ffp = those(e).product.fourdfp; % fdgv1e1r2_op_fdgv1e1r1_frame8_sumt
            assert(3 == ffp.rank); %% KLUDGE
            while (e < length(those))
                e = e + 1;
                if (this.buildVisitor.lexist_4dfp(those(e).tracerResolvedSumt))
                    icE = ImagingContext(those(e).tracerResolvedSumt); % fdgv1e*r2_sumt
                elseif (this.buildVisitor.lexist_4dfp(those(e).tracerRevision))
                    icE = ImagingContext(those(e).tracerRevision); % fdgv1e*r2
                else
                    error('mlraichle:filesystemErr', ...
                        'TracerResolveBuilder.reconstituteComposites could not find %s', ffp_.fqfn);
                end
                ffp.img(:,:,:,e) = icE.fourdfp.img;
            end  
            
            %% this is singleton, not composite

            this.sessionData_.rnumber = 1; % KLUDGE
            this.resolveTag           = '';
            this.epoch                = 1:length(those);
            ffp.fqfilename            = this.tracerRevision; % E1to9/fdgv1e1to9r1
            this.product_             = ImagingContext(ffp);
            if (~lexist(this.product_.fqfilename, 'file'))
                this.product_.save;
                %warning('mlraichle:IOWarn:overwritingExistingFile', ...
                %    'TracerResolveBuilder.reconstituteComposites is overwriting %s', this.product_.fqfilename);
            end
        end	
        function sz   = sizeTracerRevision(this)
            %% SIZETRACERREVISION
            %  @return sz, the size of the image data specified by this.tracerRevision.
            
            assert(this.buildVisitor.lexist_4dfp(this.tracerRevision('typ','fqfp')));
            sz = this.buildVisitor.ifhMatrixSize(this.tracerRevision('typ', '4dfp.ifh'));
        end
        function this = sumProduct(this)
            assert(isa(this.product_, 'mlfourd.ImagingContext'))
            if (this.buildVisitor.lexist_4dfp([this.product_.fqfp '_sumt']))
                this.product_ = mlfourd.ImagingContext([this.product_.fqfp '_sumt.4dfp.ifh']);
                return
            end
            this.product_ = this.product_.timeSummed;
            this.product_.fourdfp;
            this.product_.save; % _sumt
        end
        function        touchFinishedMarker(this)
            this.finished.touchFinishedMarker;   
        end
		  
 		function this = TracerResolveBuilder(varargin)
            %% TRACERRESOLVEBUILDER
            %  @param ctSourceForUmap is the f.-q.-filename of prepared CT.  
            %  @return instance ready for t4-resolve management of tracer data.  
            
 			this = this@mlpet.TracerBuilder(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addParameter('ctSourceForUmap', ...
                fullfile(this.vLocation, 'ctMaskedOnT1001r2_op_T1001.4dfp.ifh'), ...
                @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            this.ctSourceForUmap = ip.Results.ctSourceForUmap;
            this.finished = mlpipeline.Finished(this, ...
                'path', this.logPath, ...
                'tag', sprintf('%s_%s', ...
                       lower(this.sessionData.tracerRevision('typ','fp')), class(this)));
 		end
    end 
    
    %% PROTECTED    
    
    properties (Access = protected)
        aComposite_ % cell array for simplicity
    end
    
    methods (Access = protected)
        function this   = saveEpoch(this, monoFfp)
            %% SAVEEPOCH
            %  @param this corresponds to a partitioning of an epoch from all the frames of monolith.
            %  @param monoFfp is ImagingContext.fourdfp for the monolithic tracer imaging data;
            %  monolith.sizeTracerRevision must have rank == 4.
            %  @return this.product := saved partitioning of monolith at this.epoch cast as ImagingContext, 
            %  stateTypeclass mlfourd.FourdfpState.
            
            monoFfp.img = monoFfp.img(:,:,:,this.epoch);
            monoFfp.fqfileprefix = this.tracerRevision('typ', 'fqfp');
            monoFfp.save;
            this.product_ = monoFfp;
        end
        function frames = partitionFrames(this, monolith)
            %% PARTITIONFRAMES 
            %  @param this corresponds to a partitioning of an epoch from all the frames of monolith.
            %  @param monolith is the TracerResolveBuilder for the monolithic tracer imaging data;
            %  monolith.sizeTracerRevision must have rank == 4.
            %  @return frames specifies the indices of frames of monolith that correspond to this.epoch.
            
            monoSz = monolith.sizeTracerRevision;
            nFullEpoch = floor(monoSz(4)/this.MAX_LENGTH_EPOCH);
            ep = this.epoch;
            if (ep*nFullEpoch > monoSz(4))
                frames = (ep-1)*nFullEpoch+1:monoSz(4); % remaining frames
                return
            end
            frames = (ep-1)*nFullEpoch+1:ep*nFullEpoch; % partition of frames
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

