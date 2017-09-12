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
        TAUS_FDG = [30,30,30,30,30,30,30,30,30,30,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60]
        TAUS_OC = [30,30,30,30,30,30,30,30,30,30,30,30,30,30]
        TAUS_OO = [30,30,30,30,30,30,30,30,30,30]
        TAUS_HO = [30,30,30,30,30,30,30,30,30,30]
    end
    
    properties
        ctSourceFqfn % fqfilename
    end    
    
    properties (Dependent)
        ctSourceFp
        imgblurTag
    end
    
    methods (Static)
        function reconstituteFramesAC2(sessd)
            import mlfourdfp.*;
            
            fv   = mlfourdfp.FourdfpVisitor;
            pwd0 = pushd(sessd.tracerLocation);            
            pth1to11 = fullfile(sessd.tracerLocation, 'E1to11', '');
            ffp0 = Fourdfp.load('E1/fdgv1e1r1_frame1.4dfp.ifh');
            ffp0.img = zeros(172,172,127,85);
            ffp0.fqfileprefix = fullfile(sessd.tracerLocation, 'fdgv1r1_op_fdgv1e1to11r1_frame11');
            sessd.rnumber = 2;
            
            for e = 1:10
                sessd.epoch = e;
                pwd1 = pushd(sessd.tracerLocation);
                t4 = fullfile(pth1to11, sprintf('fdgv1e1to11r2_frame%i_to_op_fdgv1e1to11r1_frame11_t4', e));
                fp = sprintf('fdgv1e%ir2_op_fdgv1e%ir1_frame8', e, e);  % verify
                fpDest = sprintf('fdgv1e%ir2_op_fdgv1e%ir1_frame11', e, e);
                fv.t4img_4dfp(t4, fp, 'out', fpDest, 'options', ['-O' fp]);
                ffp = Fourdfp.load([fpDest '.4dfp.ifh']);
                ffp0.img(:,:,:,(e-1)*8+1:e*8) = ffp.img;
                popd(pwd1);
            end
            
            e = 11;
            sessd.epoch = e;
            pwd1 = pushd(sessd.tracerLocation);            
            fpDest = sprintf('fdgv1e%ir2_op_fdgv1e1to11r1_frame5', e);
            ffp = Fourdfp.load([fpDest '.4dfp.ifh']);
            ffp0.img(:,:,:,(e-1)*8+1:end) = ffp.img;
            popd(pwd1);
            
            ffp0.save;
            fv.imgblur_4dfp(ffp0.fqfileprefix, 4.3);
            popd(pwd0);
        end
    end

	methods 
        
        %% GET
        
        function g = get.ctSourceFp(this)
            g = mybasename(this.ctSourceFqfn);
        end
        function g = get.imgblurTag(this)
            g = this.sessionData_.petPointSpread('tag_imgblur_4dfp', true);
        end
        
        %%
        
        function [this,monolith] = partitionMonolith(this)
            %% PARTITIONMONOLITH into composite {TracerResolveBuilders}; monolithic tracerRevision is partitioned.
            %  @param  this.tracerRevision exists.
            %  @param  this.MAX_LENGTH_EPOCH is integer > 0.  
            %  @return with identity if rank(monolith) < 4.
            %  @return this := composite {TracerResolveBuilder} with partitioning of monolith into epochs with each 
            %          |epoch| <= this.MAX_LENGTH_EPOCH if rank(monolith) == 4.  
            %          Save epochs if not already on filesystem.
            %  @return this.epoch as determined by this.partitionEpochFrames.
            %  @return monolith := struct, fields := {sessionData, imagingContext}, with pre-partitioning state for 
            %          later use; use FilenameState to minimize memory footprint.
            %  See also:  mlpipeline.RootDataBuilder.
            
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4))
                return
            end
            
            import mlfourd.*;
            if (thisSz(4) > this.MAX_LENGTH_EPOCH)
                monoBldr                = this;
                monolith.sessionData    = monoBldr.sessionData;
                monolith.imagingContext = ImagingContext(monoBldr.tracerRevision); % small memory footprint
                mono                    = ImagingContext(monoBldr.tracerRevision);
                monoFfp                 = mono.fourdfp;
                this.nEpochs_           = ceil(thisSz(4)/this.MAX_LENGTH_EPOCH);
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
            %  @return multiEpochOfSummed  := composite multi-epoch {TracerResolveBuilder} 
            %                                 each containing summed motion-corrected frames.
            %  @return reconstitutedSummed := singlet TracerResolveBuilder containing summed motion-corrected frames.
                
            if (length(this) > 1)    
                
                % recursion over epochs to generate composite
                for e = 1:length(this)
                    [this(e),~,multiEpochOfSummed(e)] = this(e).motionCorrectFrames;
                end
                singleEpoch = multiEpochOfSummed(1);
                singleEpoch = singleEpoch.reconstituteComposites(multiEpochOfSummed);
                [this,reconstitutedSummed] = singleEpoch.motionCorrectEpochs;
                return
            end
            
            % base case, returns singlet
            this.product_ = mlfourd.ImagingContext(this.tracerRevision);
            multiEpochOfSummed = [];
            [this,reconstitutedSummed] = this.motionCorrectEpochs;
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
            rB_                  = rB_.resolve;
            this.resolveBuilder_ = rB_;
            this.sessionData_    = rB_.sessionData; 
            this.product_        = rB_.product;            
            summed               = this.sumProduct;
            popd(pwd0);
        end
        function this = motionCorrectModalities(this)
            %% MOTIONCORRECTMODALITIES
            %  @param  this.sessionData is well-formed for the problem.
            %  @param  this.product is a single-epoch motion-corrected tracer.
            %          e.g., after completing this.motionCorrectFrames, 
            %          reconstitutedSummed.product := E1to9/fdgv1e1to9r2_op_fdgv1e1to9r1_frame9_sumt &&
            %          this := reconstitutedSummed.
            %  @param  this.ctSourceFqfn is the source for motion-corrected umap.
            %  @return motion-correction of this.ctSourceFqfn, T1, t2 onto this.product for this.{compositeResolveBuilder,sessionData,product};
            %          e.g., this.product := umapSynth_to_op_fdgv1e1to9r1_frame9.
            
            pwd0 = pushd(this.product_.filepath);      
            this.locallyStageModalities('fourdfp', this.ctSourceFqfn);             
            this.sessionData_.rnumber = 1;
            theImages = {this.product_.fileprefix ... 
                         this.ctSourceFp ...
                         this.T1('typ','fp') ...
                         this.t2('typ','fp')};    
            cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', theImages, ...
                'NRevisions', 2);    
                        
            % update this.{compositeResolveBuilder_,sessionData_,product_}                      
            cRB_ = cRB_.resolve;             
            cRB_ = cRB_.t4img_4dfp( ...
                sprintf('%sr0_to_%s_t4', this.ctSourceFp, cRB_.resolveTag), ...
                cRB_.umapSynth('tracer', '', 'typ', 'fp'), ...
                'out', cRB_.umap(cRB_.resolveTag, 'typ', 'fp'));
            this.compositeResolveBuilder_ = cRB_;
            this.sessionData_             = cRB_.sessionData;
            this.product_                 = cRB_.product;            
            popd(pwd0);
        end
        function this = motionUncorrectUmap(this, multiEpochOfSummed)
            %% MOTIONUNCORRECTUMAP
            %  @param this.motionCorrectModalities has completed successfully with motion-corrected umap 
            %  contained in this.product; e.g., umapSynth_to_op_fdgv1e1to9r1_frame9
            %  @param parent ~fdgv1e1to9r2_op_fdgv1e1to9r1_frame9
            %  @return this.product := this.umapSynth back-resolved to all original frames of tracer monolith.
            
            umapOnFrame9 = this.product;
            this.assertUmap(umapOnFrame9);
            this.motionUncorrectToFrames(umapOnFrame9, multiEpochOfSummed);
            
            this.sessionData.epoch = [];
            loc = this.sessionData.tracerLocation;
            ensuredir(loc);
            cd(loc);
            this = this.umapAufbau;
            this = this.partitionUmaps;
            this = this.convertUmapsToE7Format;
            
        end
        function thisUncorrected = motionUncorrectToFrames(this, source, multiEpochOfSummed)
            %% MOTIONUNCORRECTTOFRAMES
            
            thisUncorrected = this.motionUncorrectToEpochs(source, multiEpochOfSummed);
                % thisUncorrected(${u}).product->E1to9/umapSynth_op_fdgv1e1to9r1_frame${u}
            if (length(thisUncorrected) > 1)
                for u = 1:length(thisUncorrected)
                    multiEpochOfSummed(u).motionUncorrectToEpochs2(thisUncorrected(u).product, multiEpochOfSummed(u)); 
                end
            end           
        end
        function thisUncorrected = motionUncorrectToEpochs(this, source, multiEpochOfSummed)
            %% MOTIONUNCORRECTTOEPOCHS back-resolves a source in the space of some reference epoch to all available epochs.
            %  @param this.resolveBulder.product is the motion-corrected-summed singlet object to which source will align.
            %  @param source is an ImagingContext.
            %  @param thisCorrected is a collection of external TracerResolveBuilders.
            %  @return thisUncorrected, a collection of TracerResolveBuilders for E1to9, each conveying back-resolving
            %  to one of the available epochs.
            
            assert(isa(source, 'mlfourd.ImagingContext'));
            assert(isa(multiEpochOfSummed, 'mlpet.TracerResolveBuilder'));
            import mlfourd.*;
            
            for idxRef = 1:length(multiEpochOfSummed)

                if (idxRef == this.resolveBuilder_.indexOfReference)
                    continue
                end
                
                %% resolve source to thisMotionUncorrected(idxRef)
                loc = this.resolveBuilder_.sessionData.tracerLocation;
                ensuredir(loc);
                pwd0 = pushd(loc); % E1to9;    
                thisUncorrected(idxRef) = this; %#ok<*AGROW>                
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
                        'out', childRB.umap(childRB.resolveTag, 'typ', 'fp'));
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
                    fprintf('this(%i).product->\n    %s\n\n', idxRef, thisUncorrected(idxRef).product); 
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
        function thisUncorrected = motionUncorrectToEpochs2(this, source, multiEpochOfSummed)
            %% MOTIONUNCORRECTTOEPOCHS back-resolves a source in the space of some reference epoch to all available epochs.
            %  @param this.resolveBulder.product is the motion-corrected-summed singlet object to which source will align.
            %  @param source is an ImagingContext.
            %  @param thisCorrected is from a collection of external TracerResolveBuilders.
            %  @return thisUncorrected, a collection of TracerResolveBuilders, each conveying back-resolving
            %  to one of the available epochs.
            
            assert(isa(source, 'mlfourd.ImagingContext'));
            assert(isa(multiEpochOfSummed, 'mlpet.TracerResolveBuilder'));
            import mlfourd.*;
            
            for idxRef = 1:this.MAX_LENGTH_EPOCH
                
                %% resolve source to thisMotionUncorrected(idxRef)
                
                loc = this.resolveBuilder_.sessionData.tracerLocation;
                ensuredir(loc);
                pwd0 = pushd(loc); % E1, ..., E8;    
                thisUncorrected(idxRef) = this; %#ok<*AGROW>                
                try
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
                        'out', childRB.umap(childRB.resolveTag, 'typ', 'fp'));
                        % t4     := ${E}/fdgv1${e}r0_frame8_to_op_fdgv1${e}r1_frame${idxRef}_t4; 
                        % source := E1to9/umapSynth_op_fdgv1e1to9r1_frame${e};          
                        % out    :=       umapSynth_op_fdgv1${e}r1_frame${idxRef}               
                    childRB.theImages    = childRB.tracerRevision('typ', 'fqfp');   
                    childRB.epoch        = idxRef;
                    
                    %% update thisMotionUncorrected(idxRef).{resolveBuilder_,sessionData_,product_}
                
                    thisUncorrected(idxRef).resolveBuilder_ = childRB; 
                    thisUncorrected(idxRef).sessionData_    = childRB.sessionData;                                    
                    thisUncorrected(idxRef).product_        = ImagingContext(this.resolveBuilder_.umap(childRB.resolveTag)); % ~ childRB.product;  
                    
                    fprintf('motionUncorrectToEpochs:\n');
                    fprintf('source.fqfileprefix->\n    %s\n', source.fqfileprefix); 
                        % E1to9/umapSynth_op_fdgv1e1to9r1_frame${e}; 
                    fprintf('this(%i).product->\n    %s\n\n', idxRef, thisUncorrected(idxRef).product); 
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
        function t4 = parentToChildT4(this, resolveTag)
            tracerEpochParent = this.resolveBuilder_.tracerEpoch('typ','fqfp'); % E1to9/fdgv1e1to9
            idxRefParent      = this.resolveBuilder_.indexOfReference;          % 9
            t4 = sprintf('%sr0_frame%i_to_%s_t4', tracerEpochParent, idxRefParent, resolveTag);
        end
        function this = motionUncorrectUmapToFrames(this, umapOpParent) %, monolith)
            %% MOTIONUNCORRECTUMAPTOFRAMES uses previously split and motion-corrected monolithic image with 
            %  partitioned tree of epochs or frames. 
            %  @param this.product contains singlet-frame created by this.motionCorrectModalities; 
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
        function this = reconstituteFramesAC(this)
            %% RECONSTITUTEACFRAMES
            %  @param this.sessionData.tracerConvertedLocation has form ~FDG_V1-Converted-Frame${i}-AC.
            %  @param this.sessionData.tracerListmodeFrameV has form ~FDG_V1-LM-00/FDG_V1-OM-00-OP-00${j}-000.v.
            %         i and j have C-indexing.
            %  @param this.sessionData.tracerListmodeMhdr has form ~FDG_V1-LM-00/FDG_V1-OM-00-OP.mhdr.
            %  @return all frames and sub-frames reconstituted into file this.sessionData.tracerRevision
            %          ~FDG_V1-AC/fdgv1r1.
                   
            assert(this.sessionData_.attenuationCorrected);  
            ensuredir(this.sessionData_.tracerLocation);
            aufbau = this.aufbauFourdfp;
            if (~lexist(aufbau.fqfilename, 'file'))

                this.sessionData_.frame = 0;
                innerf = 0;
                nFrames = this.getNFrames;
                while (isdir(this.sessionData_.tracerConvertedLocation))

                    this.prepareTracerLocation;
                    this.prepareListmodeMhdr;
                    assert(lexist(this.sessionData_.tracerListmodeMhdr, 'file'));                
                    pwd0 = pushd(this.sessionData_.tracerLocation); % paranoia
                    this = this.prepareCroppedTracerRevision;
                    ffp = this.product.fourdfp;
                    sz = ffp.size;
                    ffp = this.t4imgFromNac(ffp, nFrames);
                    if (ffp.rank < 4)
                        innerf = innerf + 1;
                        aufbau.img(:,:,:,innerf) = ffp.img;
                    else
                        for t = 1:sz(4)   
                            innerf = innerf + 1;
                            aufbau.img(:,:,:,innerf) = ffp.img(:,:,:,t);
                        end
                    end                
                    this.sessionData_.frame = this.sessionData_.frame + 1;  
                    popd(pwd0); % paranoia    
                end     
            end
            
            % update this.{sessionData_,product_}
            this.sessionData_.rnumber = 1; 
            this.product_             = mlfourd.ImagingContext(aufbau);
            ensuredir(this.product_.filepath);
            if (~lexist(this.product_.fqfilename, 'file'))
                this.product_.save;
            end
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
        nEpochs_
    end
    
    methods (Access = protected)
        function ffp  = aufbauFourdfp(this)
            sessDNac = this.sessionData_;
            sessDNac.attenuationCorrected = false;
            sessDNac.epoch = 1;
            assert(lexist(sessDNac.tracerRevision('frame', 1)));
            ffp = mlfourdfp.Fourdfp.load(sessDNac.tracerRevision('frame', 1));
            ffp.fqfileprefix = this.sessionData_.tracerRevision('typ', 'fqfp');
            ffp.img = zeros(size(ffp));
            assert(strcmp(ffp.filesuffix, '.4dfp.ifh'));
        end
        function [epoch,epochSubframe] = getEpochIndices(this, nacFrame)
            epoch = floor(nacFrame/this.MAX_LENGTH_EPOCH) + 1;
            epochSubframe = mod(nacFrame, this.MAX_LENGTH_EPOCH) + 1;  
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
            bv = this.buildVisitor;
            [epoch,epochSubframe] = this.getEpochIndices(this.sessionData_.frame);
            nEpochs = ceil(nFrames/this.MAX_LENGTH_EPOCH);            
            this.sessionData_.epoch = epoch;
            this.sessionData_.frame = epochSubframe;
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
                    sessDNac.tracerEpoch('typ', 'fp'), epochSubframe, sessDNac.resolveTag, this.MAX_LENGTH_EPOCH));
            dest = strrep(ffp.fileprefix, '__', '___');
            if (~lexist(strrep(t4, 'r0', 'r1'), 'file'))
                bv.move_4dfp(ffp.fileprefix, strrep(ffp.fileprefix, '__', ''));
                return
            end
            if (~bv.lexist_4dfp(dest))
                t4rb.t4img_4dfp(t4, ffp.fileprefix, 'out', dest);
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
                t4rb.t4img_4dfp(t4_, ffp.fileprefix, 'out', dest_);
            end
            ffp   = mlfourdfp.Fourdfp.load([dest_ '.4dfp.ifh']);
        end
        
        function        assertUmap(this, obj)
            assert(lstrfind(obj.fileprefix, 'umap'));
            sz = this.size_4dfp(obj);
            assert(3 == length(sz) || 1 == sz(4));
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
        function epochFrames = partitionEpochFrames(this, monoBldr)
            %% PARTITIONFRAMES 
            %  @param this corresponds to a partitioning of an epoch from all the frames of monolith.
            %  @param monoBldr is the TracerResolveBuilder for the monolithic tracer imaging data;
            %  monoBldr.sizeTracerRevision must have rank == 4.
            %  @return epochFrames specifies the indices of frames of monolith that correspond to this.epoch.
            
            monoSz = monoBldr.sizeTracerRevision;
            e = this.sessionData_.epoch;
            if (e*this.MAX_LENGTH_EPOCH > monoSz(4))
                epochFrames = (e-1)*this.MAX_LENGTH_EPOCH+1:monoSz(4); % remaining frames
                return
            end
            epochFrames = (e-1)*this.MAX_LENGTH_EPOCH+1:e*this.MAX_LENGTH_EPOCH; % partition of frames
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
            
            assert(this.buildVisitor.lexist_4dfp(this.sessionData_.tracerRevision('typ','fqfp')));
            sz = this.buildVisitor.ifhMatrixSize(this.sessionData_.tracerRevision('typ', '4dfp.ifh'));
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
            fps = cellfun(@(x) sprintf('umapSynth_frame%i', x), num2cell(0:64), 'UniformOutput', false);
            cub = mlfourdfp.CarneyUmapBuilder('sessionData', this.sessionData);
            cub = cub.convertUmapsToE7Format(fps);
            this.product_ = cub.product;
        end
        function this = partitionUmaps(this)
            
            switch (upper(this.sessionData.tracer))
                case 'FDG'
                    % \Sigma\tau^{\text{nac}}_i = 3600 s; N(tau^{\text{nac}}_i) = 65
                    tausNac = this.TAUS_FDG;
                case {'CO' 'OC'}
                    tausNac = this.TAUS_OC;
                case {'HO' 'OH' 'OO'}
                    tausNac = this.TAUS_OO;
                otherwise
                    error('mlpet:unsupportedSwitchCase', ...
                        'TracerResolveBuilder.partitionUmaps.this.sessionData.tracer->%s', this.sessionData.tracer);
            end
            
            tNac = zeros(1, length(tausNac));
            for iNac = 1:length(tausNac)
                tNac(iNac) = sum(tausNac(1:iNac)); % end of frame
            end
            
            import mlfourd.*;
            umaps = ImagingContext('umapSynth.4dfp.ifh');
            umap0 = umaps.fourdfp;
            umap0.img = umap0.img(:,:,:,1);
            assert(length(tNac) == umaps.fourdfp.size(4));
            
            iNac = 0;
            while (iNac < length(tNac))
                umap = umap0;
                umap.img = umaps.fourdfp.img(:,:,:,iNac+1);
                umap.fileprefix = sessd.umap('', 'frame', iNac); 
                umap.save;
                umapComposite(iNac+1) = umap;
                iNac = iNac + 1;
            end
            this.product_ = ImagingContext(umapComposite);
        end    
        function this = umapAufbau(this)
            %  @return this:  this.product is the multi-frame umap as mlfourdfp.Fourdfp.
            
            import mlfourd.* mlfourdfp.*;
            fprintf('TracerResolveBuilder.umapAufbau:  working in %s\n', pwd);
            
            sessd = this.sessionData;
            sessd.rnumber = 1;
            tracerSz = this.size_4dfp(ImagingContext(sessd.tracerRevision));
            nEpoch = floor(tracerSz(4)/this.MAX_LENGTH_EPOCH); 
            tracerFp = sessd.tracerRevision('typ', 'fp');
            if (~this.buildVisitor.lexist_4dfp([tracerFp '_b43']))
                this.buildVisitor.imgblur_4dfp( tracerFp, 4.3);
            end           
            
            sessd1 = sessd;
            sessd1.epoch = 1;
            sessd1.resolveTag = sessd1.resolveTagFrame(this.MAX_LENGTH_EPOCH, 'reset', true);
            umap = ImagingContext(sessd1.umap(sessd1.resolveTag));
            
            umapFfp = umap.fourdfp;
            umapFfp.fqfilename = [sessd.umap('') '.4dfp.ifh'];
            umapSz = umapFfp.size;
            umapFfp.img = zeros(umapSz(1),umapSz(2),umapSz(3),tracerSz(4));
            for ep = 1:nEpoch
                for fr = 1:this.MAX_LENGTH_EPOCH
                    sessd_ = sessd;
                    sessd_.epoch = ep;
                    sessd_.resolveTag = sessd_.resolveTagFrame(fr, 'reset', true);
                    frame_ = NIfTId.load(sessd_.umap(sessd_.resolveTag));
                    umapFfp.img(:,:,:,8*(ep-1)+fr) = frame_.img;
                end
            end
            tLast = nEpoch*this.MAX_LENGTH_EPOCH;
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

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

