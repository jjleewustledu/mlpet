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
        ctSourceFqfn % fqfilename
    end    
    
    properties (Dependent)
        ctSourceFp
    end

	methods 
        
        %% GET
        
        function g = get.ctSourceFp(this)
            g = mybasename(this.ctSourceFqfn);
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
            %  @return this.epoch as determined by this.partitionEpochFrames.
            %  See also:  mlpipeline.RootDataBuilder.
            
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4))
                return
            end
            
            import mlfourd.*;
            if (thisSz(4) > this.MAX_LENGTH_EPOCH)
                monoBldr = this;
                monoIc   = ImagingContext(monoBldr.tracerRevision);
                monoFfp  = monoIc.fourdfp;
                nEpochs = ceil(thisSz(4)/this.MAX_LENGTH_EPOCH);
                for e = 1:nEpochs
                    this(e) = monoBldr;
                    this(e).sessionData_.epoch = e;
                    ice  = ImagingContext(this(e).tracerRevision);
                    if (~this(e).buildVisitor.lexist_4dfp(ice.fqfileprefix))
                        this(e) = this(e).saveEpoch(monoBldr, monoFfp);
                    else
                        this(e).product_ = ice;
                    end
                end
            end
        end
        function this = motionCorrectFrames(this)
            %% MOTIONCORRECTNACFRAMES may split the monolith image into partitioned epochs 
            %  using hierarchically organized data and filesystems.
            %  @return single motion-corrected epoch as TracerResolveBuilder,
            %  e.g., this.product := fdgv1e*r1.
            %  @return creation of multiple, composite, motion-corrected epochs as TracerResolveBuilders; 
            %  a single parent epoch is the the motion-correction of summed images of its children.
                
            % recursion over epochs to generate composite
            if (length(this) > 1)             
                for e = 1:length(this)
                    this(e) = this(e).motionCorrectFrames;
                end
                singlet = this(1);
                singlet = singlet.reconstituteComposites(this);
                this    = singlet.motionCorrectEpochs;
                return
            end
            
            % base of recursion, returns singlet
            this.product_ = mlfourd.ImagingContext(this.tracerRevision);
            this = this.motionCorrectEpochs;
        end
        function this = motionCorrectEpochs(this)
            %% MOTIONCORRECTEPOCHS
            %  @param this.sessionData is well-formed for the problem.
            %  @param this.product is well-formed; e.g., after completing this.partitionMonolith.
            %  @return without mutations for rank(this.tracerRevision) < 4.
            %  e.g., this.product := fdgv1e*r1.4dfp.ifh.
            %  @return motion-corrected mutations for this.{resolveBuilder,sessionData,product}.
            %  e.g., this.tracerRevision := fdgv1e*r2.4dfp.ifh; e1-e9, e1to9
            %        this.product        := fdgv1e*r2_op_fdgv1e*r1_frame*.4dfp.ifh
            %        this.product        := fdgv1e*r2_op_fdgv1e*r1_frame*_sumt.4dfp.ifh
            %  @return results of this.sumProduct.
            
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4))
                return 
            end
            
            % thisSz(4) == duration of this epoch
            this.resolveBuilder_  = mlfourdfp.T4ResolveBuilder( ...
                'sessionData', this.sessionData, ...
                'theImages', this.product.fqfileprefix, ...
                'indexOfReference', thisSz(4), ...
                'NRevisions', 2, ...
                'resolveTag', this.resolveTagFrame(thisSz(4), 'reset', true)); 
            
            % update this.{resolveBuilder_,sessionData_,product_}
            this.resolveBuilder_  = this.resolveBuilder_.resolve;
            this.sessionData_     = this.resolveBuilder_.sessionData; 
            this.product_         = this.resolveBuilder_.product;
            this                  = this.sumProduct;
        end
        function this = motionCorrectModalities(this)
            %% MOTIONCORRECTMODALITIES
            %  @param this.sessionData is well-formed for the problem.
            %  @param this.product is well-formed tracer as mlfourd.ImagingContext; 
            %  e.g., after completing this.motionCorrectFrames, 
            %        product := fdgv1e1to9r2_op_fdgv1e1to9r1_frame9_sumt 
            %  @param motion-corrected umap is created from this.ctSourceFqfn.
            %  @return t4-resolve results on tracer, this.ctSourceFqfn, T1, t2
            %  @return mutations to this.{compositeResolveBuilder,sessionData,product}.
            
            %assert(strcmp(this.resolveBuilder_.resolveTag, 'op_fdgv1e1to9r1_frame9'));  
            this.sessionData_.rnumber = 1;
            this.locallyStageModalities('fourdfp', this.ctSourceFqfn);            
            theImages = {this.product_.fileprefix ... 
                         this.ctSourceFp ...
                         this.T1( 'typ','fp') ...
                         this.t2( 'typ','fp')};    
            this.compositeResolveBuilder_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', theImages, ...
                'NRevisions', 2);    
                        
            % update this.{compositeResolveBuilder_,sessionData_,product_}                      
            pwd0 = this.product_.filepath;
            this.compositeResolveBuilder_ = this.compositeResolveBuilder_.resolve; 
            this.compositeResolveBuilder_ = this.compositeResolveBuilder_.t4img_4dfp( ...
                fullfile(pwd0, sprintf('%sr0_to_%s_t4', this.ctSourceFp, this.compositeResolveBuilder_.resolveTag)), ...
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
            
            assert(strcmp(this.product.fileprefix, 'umapSynth_op_fdgv1e1to9r1_frame9'));
            this = this.motionUncorrectUmapToFrames(this.product);
            this = this.partitionUmaps;
        end
        function this = motionUncorrectUmapToFrames(this, umapOpParent)
            %% MOTIONUNCORRECTUMAPTOFRAMES uses previously split and motion-corrected monolithic image with 
            %  hierarchically partitioned epochs.  The internally specified umap is back-resolved onto the hierarchy.
            %  @return single back-resolved umap.
            %  @return multiple, internally stored back-projections and a single back-resolution onto the 
            %  the motion-correction of the summed images from descendent branches of the partitioning hierarchy tree.            
            
            % base of recursion
            % this.product_ obtained from this.motionCorrectModalities
            % focus moves to this.resolveBuilder
            assert(~isempty(this.resolveBuilder_), 'ensure motionCorrectFrames has completed successfully');
            this.sessionData_ = this.resolveBuilder_.sessionData;
            this.product_     = this.resolveBuilder_.product; % necessary?
            parent            = this;
            this              = this.motionUncorrectUmapToEpochs(umapOpParent);
            
            % recursion over epochs
            if (length(this) > 1)   
                for e = 1:length(this)
                    this(e) = this(e).motionUncorrectUmapToFrames(this(e).product);                    
                end
                singlet = this(1);
                singlet = singlet.reconstituteUmaps(this, parent);
                this    = singlet;
                return
            end           
        end
        function this = motionUncorrectUmapToEpochs(this, umapOpParent)
            %% MOTIONUNCORRECTUMAPTOEPOCHS back-resolves an image aligned with a single frame onto all frames.
            %  @param rank(this.sizeTracerRevision) < 3 => return without mutation.
            %  @param this.motionCorrectFrames has run successfully, creating this.resolveBuilder.
            %  @param umapOpParent is the ImagingContext object aligned with a single frame to be back-resolve.
            %  @return umapOpParent back-resolved to all available frames, 1:this.sizeTracerRevision.  
            %  @return this is composite.
            
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4))
                this = [];
                return
            end            
            
            parent          = this;
            tracerEpochPrev = parent.resolveBuilder_.tracerEpoch('typ','fqfp');
            idxRefPrev      = parent.resolveBuilder_.indexOfReference;
            
            for idxRef = 1:thisSz(4)

                % resolve umapOpParentFqfp to idxOfRef
                this(idxRef) = parent;
                %assert(strcmp(this(idxRef).resolveBuilder_.resolveTag, sprintf('op_fdgv1%sr1_frame%i', this(idxRef).resolveBuilder_.epochLabel, idxRef)));
                
                % update this.{resolveBuilder_,sessionData_,product_}
                pwd0 = pushd(this(idxRef).resolveBuilder_.product.filepath); % KLUDGE
                try
                    rB_                   = this(idxRef).resolveBuilder_;
                    rB_.skipT4imgAll      = true;
                    rB_.indexOfReference  = idxRef;  
                    rB_.rnumber           = 1;
                    rB_.resolveTag        = rB_.resolveTagFrame(idxRef, 'reset', true);
                    rB_.sessionData.epoch = idxRef;
                    rB_                   = rB_.updateFinished;
                    rB_                   = rB_.resolve;
                    rB_                   = rB_.t4img_4dfp( ...
                        sprintf('%sr0_frame%i_to_%s_t4', tracerEpochPrev, idxRefPrev, rB_.resolveTag), ...
                        umapOpParent.fqfileprefix, ...
                        'out', this(idxRef).umap(rB_.resolveTag, 'typ', 'fqfp'));
                        % t4     := fdgv1e1to9r2_frame9_to_op_fdgv1e1to9r1_frame[1-9]
                        % source := umapSynth_op_T1001_b40r2_op_fdgv1e1to9r1_frame9
                        % out    := umapSynth_op_fdgv1e1to9r1_frame[1-9]     
                    rB_.theImages                = rB_.tracerRevision('typ', 'fqfp');
                    rB_.skipT4imgAll             = false;
                    this(idxRef).resolveBuilder_ = rB_;
                    this(idxRef).sessionData_    = rB_.sessionData;                                    
                    this(idxRef).product_        = rB_.product;

                    fprintf('motionUncorrectUmapToEpochs:umapOpParentFqfp->%s\n', umapOpParent);
                    fprintf('this(%i).product->%s\n', idxRef, this(idxRef).product);
                catch ME
                    handwarning(ME);
                end
                popd(pwd0); % KLUDGE
            end
        end
        function this = reconstituteComposites(this, those)
            %% RECONSTITUTECOMPOSITES contracts composite TracerResolveBuilder to singlet.
            %  @param this is singlet TracerResolveBuilder.
            %  @param those is composite TracerResolveBuilder;
            %  e.g., those(1) := fdgv1e1r2_op_fdgv1e1r1_frame8_sumt.
            %  @return this is singlet TracerResolveBuilder containing reconstitution of those onto this with updating of
            %  this.{sessionData.rnumber,resolveBuilder,epoch,product}.
            
            contraction = those(1).product.fourdfp;
            assert(3 == contraction.rank);
            
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
                        'TracerResolveBuilder.reconstituteComposites could not find %s', ffp_.fqfn);
                end
                contraction.img(:,:,:,e) = icE.fourdfp.img;
            end  
            
            % update this.{resolveBuilder_,sessionData_,product_}
            this.resolveBuilder_.resolveTag = '';
            this.sessionData_.epoch         = 1:length(those);
            this.sessionData_.rnumber       = 1; 
            contraction.fqfilename          = this.sessionData_.tracerRevision; % E1to9/fdgv1e1to9r1
            this.product_                   = ImagingContext(contraction);
            if (~lexist(this.product_.fqfilename, 'file'))
                this.product_.save;
                % warning('mlraichle:IOWarn:overwritingExistingFile', ...
                %     'TracerResolveBuilder.reconstituteComposites is overwriting %s', this.product_.fqfilename);
            end
        end	
        function this = reconstituteUmaps(this, those, parent)
            for idxRef = 1:length(those)
                those(idxRef).umap(rB_.resolveTag, 'typ', 'fqfp')
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
            %  @param ctSourceFqfn is the f.-q.-filename of prepared CT.  
            %  @return instance ready for t4-resolve management of tracer data.  
            
 			this = this@mlpet.TracerBuilder(varargin{:});
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            ip.addParameter('ctSourceFqfn', ...
                fullfile(this.vLocation, 'ctMaskedOnT1001r2_op_T1001.4dfp.ifh'), ...
                @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            this.ctSourceFqfn = ip.Results.ctSourceFqfn;
            this = this.updateFinished;
 		end
    end 
    
    %% PROTECTED    
    
    properties (Access = protected)
        aComposite_ % cell array for simplicity
    end
    
    methods (Access = protected)
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
        function epochFrames = partitionEpochFrames(this, monoBldr)
            %% PARTITIONFRAMES 
            %  @param this corresponds to a partitioning of an epoch from all the frames of monolith.
            %  @param monoBldr is the TracerResolveBuilder for the monolithic tracer imaging data;
            %  monoBldr.sizeTracerRevision must have rank == 4.
            %  @return epochFrames specifies the indices of frames of monolith that correspond to this.epoch.
            
            monoSz = monoBldr.sizeTracerRevision;
            nFullEpoch = floor(monoSz(4)/this.MAX_LENGTH_EPOCH);
            ep = this.sessionData_.epoch;
            if (ep*nFullEpoch > monoSz(4))
                epochFrames = (ep-1)*nFullEpoch+1:monoSz(4); % remaining frames
                return
            end
            epochFrames = (ep-1)*nFullEpoch+1:ep*nFullEpoch; % partition of frames
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

