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
        imgblurTag
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
            %% PARTITIONMONOLITH embedded in this monolith into composite of TracerResolveBuilders; 
            %  monolithic tracerRevision will be partitioned.
            %  @param this.tracerRevision exists.
            %  @param this.MAX_LENGTH_EPOCH is integer > 0.  
            %  @return without mutations if rank(monolith) < 4.
            %  @return composite TracerResolveBuilder with partitioning of tracer-monolith into epochs
            %  with each |epoch| <= this.MAX_LENGTH_EPOCH if rank(monolith) == 4.  
            %  Epochs are saved if not already on filesystem.
            %  @return this.epoch as determined by this.partitionEpochFrames.
            %  @return monolith with pre-partitioned state for later use; 
            %  use FilenameState to minimize memory footprint.
            %  See also:  mlpipeline.RootDataBuilder.
            
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4))
                return
            end
            
            import mlfourd.*;
            if (thisSz(4) > this.MAX_LENGTH_EPOCH)
                monoBldr           = this;
                monolith.sessionData = monoBldr.sessionData;
                monolith.imagingContext      = ImagingContext(monoBldr.tracerRevision); % small memory footprint
                mono               = ImagingContext(monoBldr.tracerRevision);
                monoFfp            = mono.fourdfp;
                this.nEpochs_      = ceil(thisSz(4)/this.MAX_LENGTH_EPOCH);
                for e = 1:this.nEpochs_
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
            %% MOTIONCORRECTNACFRAMES may split the monolith image with partitioned tree of epochs.
            %  @param this.product contains multiepoch created by this.partitionMonolith.
            %  @return creation of multiple, composite, motion-corrected epochs as TracerResolveBuilders.
            %  @return singlet motion-corrected parents epoch, sum of children, in TracerResolveBuilder.product,
            %  e.g., this.product := fdgv1e*r1.
                
            if (length(this) > 1)    
                % recursion over epochs to generate composite
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
            %  @param this.product is well-formed tracer as mlfourd.ImagingContext;
            %  e.g., after completing this.partitionMonolith & this.motionCorrectFrames
            %        product := E1/fdgv1er1
            %  @return without mutations for rank(this.sessionData.tracerRevision) < 4.
            %  @return motion-corrected mutations for this.{resolveBuilder,sessionData,product}.
            %  e.g., this.product := fdgv1e*r2_op_fdgv1e*r1_frame*
            
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4)) % thisSz(4) == duration of this epoch
                return 
            end            
            
            rB_ = mlfourdfp.T4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', this.product_.fqfileprefix, ...
                'indexOfReference', thisSz(4), ...
                'NRevisions', 2, ...
                'resolveTag', this.sessionData_.resolveTagFrame(thisSz(4), 'reset', true)); 
            
            % update this.{resolveBuilder_,sessionData_,product_}
            rB_                  = rB_.resolve;
            this.resolveBuilder_ = rB_;
            this.sessionData_    = rB_.sessionData; 
            this.product_        = rB_.product;
        end
        function [this,parent] = motionCorrectModalities(this)
            %% MOTIONCORRECTMODALITIES
            %  @param this.sessionData is well-formed for the problem.
            %  @param this.product is well-formed tracer as mlfourd.ImagingContext; 
            %  e.g., after completing this.motionCorrectFrames, 
            %        product := E1to9/fdgv1e1to9r2_op_fdgv1e1to9r1_frame9
            %  @param this.ctSourceFqfn is the source for motion-corrected umap.
            %  @return motion-corrected mutations of this.ctSourceFqfn, T1, t2 onto this.product for this.{compositeResolveBuilder,sessionData,product};
            %  e.g., product := umapSynth_to_op_fdgv1e1to9r1_frame9.
            
            parent = this; 
            this = this.sumProduct;
            
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
        function [this,parent] = motionUncorrectUmap(this, parent, monolith)
            %% MOTIONUNCORRECTUMAP
            %  @param this.motionCorrectModalities has completed successfully with motion-corrected umap 
            %  contained in this.product; e.g., umapSynth_to_op_fdgv1e1to9r1_frame9
            %  @param parent ~fdgv1e1to9r2_op_fdgv1e1to9r1_frame9
            %  @return this.product := this.umapSynth back-resolved to all original frames of tracer monolith.
            
            umap = this.product;
            this.assertUmap(umap);
            this       =       this.motionUncorrectUmapToFrames(umap, monolith);
            %thisEpochs = thisEpochs.motionUncorrectUmapToFrames(umap, monolith);
            %this = this.partitionUmaps(thisEpochs);
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
        function this = motionUncorrectUmapToEpochs2(this, e, umapOpParent)
            %% MOTIONUNCORRECTUMAPTOEPOCHS back-resolves a umap aligned to a single frame onto all frames.
            %  @param this is multiframe
            %  @param this.motionCorrectFrames has run successfully, generating this.resolveBuilder.
            %  @param umapOpParent is the ImagingContext aligned to a single frame to be back-resolved to all frames.
            %  @return this := [] but no other mutations for rank(this.sizeTracerRevision) < 3.
            %  @return umapOpParent back-resolved to all available frames, 1:this.sizeTracerRevision(4).  
            %  @return this := this(1:this.sizeTracerRevision(4)), a composite.
            
            this.resolveBuilder_.epoch = e;
            
            this.assertUmap(umapOpParent);
            thisSz = this.sizeTracerRevision;
            if (length(thisSz) < 4 || 1 == thisSz(4))
                this = [];
                return
            end            
            
            %% N.B.:  this, this(idxRef), this(idxRef).compositeResolveBuilder_, this(idxRef).resolveBuilder_, this(idxRef).resolveBuilder_.sessionData
            
            parent            = this;
            parentTracerEpoch = parent.resolveBuilder_.tracerEpoch('typ','fqfp'); % ${E}/fdgv1${e}
            parentIdxRef      = parent.resolveBuilder_.indexOfReference;          % ${e}                                                                                  
            for idxRef = 1:thisSz(4) % thisSz(4)->1:8

                %% resolve umapOpParent to idxOfRef
                
                this(idxRef) = parent;                
                pwd0 = pushd(this(idxRef).resolveBuilder_.sessionData.tracerLocation); % ${E}
                try
                    rB_                   = this(idxRef).resolveBuilder_;
                    rB_.rnumber           = 1;
                    rB_.indexOfReference  = idxRef;  
                    rB_.resolveTag        = rB_.resolveTagFrame(idxRef, 'reset', true); % op_fdgv1e1to9r1_frame${idxRef};                      
                    rB_.theImages         = [];
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
        nEpochs_
    end
    
    methods (Access = protected)
        function assertUmap(this, obj)
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
            if (~lexist(this.product_.fqfilename, 'file'))
                this.product_.save;
                % warning('mlraichle:IOWarn:overwritingExistingFile', ...
                %     'TracerResolveBuilder.reconstituteComposites is overwriting %s', this.product_.fqfilename);
            end
        end	
        function this = reconstituteUmaps(this, those, monolith)
            
            return
            
            fprintf('TracerResolveBuilder.umapAufbau:  working in %s\n', pwd);
            aufbau = monolith.imagingContext;
            aufbauFfp = aufbau.fourdfp;
            aufbauFfp.fqfilename = monolith.sessionData.umap('');  %fullfile(pwd, 'umapSynth.4dfp.ifh');
            aufbauSize = aufbauFfp.size;
            aufbauFfp.img = zeros(aufbauSize);
            
            import mlfourd.*;
            bv = this.buildVisitor;
            e  = 0;
            while (e < length(those))
                e = e + 1;
                sessdE = those(e).sessionData;
                for f = 1:this.MAX_LENGTH_EPOCH
                    if (bv.lexist_4dfp(      sessdE.umapSynth('typ', 'fqfp', 'frame', f)))
                        % ${E}/umapSynth_op_fdgv1${e}r1_frame${f}
                        ic = ImagingContext(sessdE.umapSynth('typ', 'fqfp', 'frame', f)); 
                        aufbauFfp.img(:,:,:,this.MAX_LENGTH_EPOCH*(e-1)+f) = ic.fourdfp.img;
%                     elseif (bv.lexist_4dfp(  tracerMultiframeBuild.fqfileprefix))
%                         % E1to9/umapSynth_op_fdgv1e1to9r1_frame9
%                         ic = ImagingContext(tracerMultiframeBuild.fqfilename);
%                         aufbauFfp.img(:,:,:,this.MAX_LENGTH_EPOCH*(e-1)+f) = ic.fourdfp.img(:,:,:,e-this.MAX_LENGTH_EPOCH);
                    else
                        warning('mlpet:possibleMissingFile', ...
                            'TracerResolveBuilder.reconstituteUmaps could not find %s or ', ...
                            sessdE.umapSynth('typ', 'fqfp', 'frame', f));
                    end
                end
            end
            
            % update this.{sessionData_,product_}
            if (~this.buildVisitor.lexist_4dfp([monolith.sessionData.tracerRevision('typ', 'fqfp') this.imgblurTag])) % 'fdgv1r1_b55'))
                this.buildVisitor.imgblur_4dfp('fdgv1r1', this.imgblurTag);
            end
            this.sessionData_ = aufbauFfp.sessionData;
            this.product_     = ImagingContext(aufbauFfp);
            aufbauFfp.save;
        end   
        function epochFrames = partitionEpochFrames(this, monoBldr)
            %% PARTITIONFRAMES 
            %  @param this corresponds to a partitioning of an epoch from all the frames of monolith.
            %  @param monoBldr is the TracerResolveBuilder for the monolithic tracer imaging data;
            %  monoBldr.sizeTracerRevision must have rank == 4.
            %  @return epochFrames specifies the indices of frames of monolith that correspond to this.epoch.
            
            monoSz = monoBldr.sizeTracerRevision;
            epMax = floor(monoSz(4)/this.MAX_LENGTH_EPOCH);
            ep = this.sessionData_.epoch;
            if (ep*epMax > monoSz(4))
                epochFrames = (ep-1)*epMax+1:monoSz(4); % remaining frames
                return
            end
            epochFrames = (ep-1)*epMax+1:ep*epMax; % partition of frames
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
            this.product_ = this.product_.timeSummed;
            this.product_.fourdfp;
            this.product_.save; % _sumt
        end
        function        touchFinishedMarker(this)
            this.finished.touchFinishedMarker;   
        end
    end
    
    %% HIDDEN
    
    methods (Static)
        function converUmapsToE7Format
            fps = cellfun(@(x) sprintf('umapSynth_frame%i', x), num2cell(0:64), 'UniformOutput', false);
            
            sessd = mlraichle.SessionData( ...
                'studyData', mlraichle.StudyData, 'sessionPath', fullfile(getenv('PPG'), 'jjlee2', 'HYGLY28', ''));
            cub = mlfourdfp.CarneyUmapBuilder('sessionData', sessd);
            cub.convertUmapsToE7Format(fps);
        end
        function partitionUmaps
            
            % \Sigma\tau^{\text{nac}}_i = 3600 s; N(tau^{\text{nac}}_i) = 65
            tausNac = ...
                [30,30,30,30,30,30,30,30,30,30,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60,60];

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
                iNac = iNac + 1;
                umap = umap0;
                umap.img = umaps.fourdfp.img(:,:,:,iNac);
                umap.fileprefix = sprintf('%s_frame%i', umaps.fileprefix, iNac-1); % e7tools/JSRecon frame-numbering convention
                umap.save;
            end
        end
        function umapAufbau
            fprintf('TracerResolveBuilder.umapAufbau:  working in %s\n', pwd);
            umap = mlfourd.ImagingContext('E1/umapSynth_op_fdgv1e1r1_frame8.4dfp.ifh');
            umapFfp = umap.fourdfp;
            umapFfp.fqfilename = fullfile(pwd, 'umapSynth.4dfp.ifh');
            sz = umapFfp.size;
            umapFfp.img = zeros(sz(1),sz(2),sz(3),65);
            for ep = 1:8
                for fr = 1:8
                    frame = mlfourd.NIfTId.load( ...
                        fullfile(sprintf('E%i', ep), sprintf('umapSynth_op_fdgv1e%ir1_frame%i.4dfp.ifh', ep, fr)));
                    umapFfp.img(:,:,:,8*(ep-1)+fr) = frame.img;
                end
            end
            frame = mlfourd.NIfTId.load('E1to9/umapSynth_op_fdgv1e1to9r1_frame9_op_fdgv1e1to9r1_frame9.4dfp.ifh');
            umapFfp.img(:,:,:,65) = frame.img;
            fv = mlfourdfp.FourdfpVisitor;
            if (~fv.lexist_4dfp('fdgv1r1_b55'))
                fv.imgblur_4dfp('fdgv1r1', 5.5);
            end
            umapFfp.save;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

