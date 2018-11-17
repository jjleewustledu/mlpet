classdef TracerBuilder < mlfourdfp.AbstractSessionBuilder
	%% TRACERBUILDER

	%  $Revision$
 	%  was created 9-Mar-2017 15:39
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee. 	
    
    
    properties 
        mask = 'none'
    end
    
    properties (Dependent)
        compositeResolveBuilder
        maxLengthEpoch
        resolveBuilder
        roisBuilder
        vendorSupport
    end
    
    methods (Static)
        function ensureBlurred(obj, blur)
            %  @param obj requires the 4dfp environment.
            %  @param blur is numeric.
            
            ic = mlfourd.ImagingContext(obj);
            if (~lexist(ic.fqfilename, 'file'))
                warning('mlpet:fileDoesNotExistOnFilesystem', 'TracerBuilder.ensureSumt.obj->%s', char(obj));
                return
            end
            if (lexist(sprintf('%s_%i%i%ifwhh.4dfp.hdr', ic.fqfileprefix, blur, blur, blur), 'file'))
                return
            end
            ic = ic.blurred(blur);
            ic.fourdfp;
            ic.save;
        end
        function ensureBlurred4dfp(obj, blur)
            %  @param obj requires the 4dfp environment.
            %  @param blur is numeric.
            
            ic = mlfourd.ImagingContext(obj);
            if (~lexist(ic.fqfilename, 'file'))
                warning('mlpet:fileDoesNotExistOnFilesystem', 'TracerBuilder.ensureSumt.obj->%s', char(obj));
                return
            end
            if (lexist(sprintf('%s_b%i.4dfp.hdr', ic.fqfileprefix, floor(10*blur)), 'file'))
                return
            end
            fv = mlfourdfp.FourdfpVisitor;
            fv.imgblur_4dfp(ic.fqfileprefix, blur);
        end
        function ensureSumt(obj)
            %  @param obj requires the 4dfp environment.
            
            ic = mlfourd.ImagingContext(obj);
            if (~lexist(ic.fqfilename, 'file'))
                warning('mlpet:fileDoesNotExistOnFilesystem', 'TracerBuilder.ensureSumt.obj->%s', char(obj));
                return
            end
            if (lexist(sprintf('%s_sumt.4dfp.hdr', ic.fqfileprefix), 'file'))
                return
            end
            ic = ic.timeSummed;
            ic.fourdfp;
            ic.save;
        end
        function fqfn = scrubTracer(fqfn, toScrub)
            assert(lexist(fqfn, 'file'));
            assert(isnumeric(toScrub));
            ffp = mlfourdfp.Fourdfp.load(fqfn);
            ffp.fileprefix = [ffp.fileprefix '_scrubbed'];
            lenScrubbed = ffp.size(4) - length(toScrub);
            img = zeros(ffp.size(1), ffp.size(2), ffp.size(3), lenScrubbed);
            u = 0;
            for t = 1:lenScrubbed
                if (~any(t == toScrub))
                    u = u + 1;
                    img(:,:,:,u) = ffp.img(:,:,:,t);
                end
            end
            ffp.img = img;
            ffp.save;
            fqfn = ffp.fqfilename;
        end
    end
        
    methods 
        
        %% GET/SET
        
        function g    = get.compositeResolveBuilder(this)
            g = this.compositeResolveBuilder_;
        end
        function g    = get.maxLengthEpoch(this)
            g = this.sessionData_.maxLengthEpoch;
        end
        function this = set.maxLengthEpoch(this, s)
            assert(isnumeric(s));
            this.sessionData_.maxLengthEpoch = s;
        end
        function g    = get.resolveBuilder(this)
            g = this.resolveBuilder_;
        end
        function g    = get.roisBuilder(this)
            g = this.roisBuilder_;
        end        
        function this = set.roisBuilder(this, s)
            assert(isa(s, 'mlrois.IRoisBuilder'));
            this.roisBuilder_ = s;
        end
        function g    = get.vendorSupport(this)
            g = this.vendorSupport_;
        end        
        function this = set.vendorSupport(this, s)
            assert(isa(s, 'mlpipeline.VendorBuilder'));
            this.vendorSupport_ = s;
        end

        %%
        
        function this = setNeverTouch(this, s)
            assert(islogical(s));
            this.finished_.neverTouchFinishfile = s;  
            this.compositeResolveBuilder_.finished_.neverTouchFinishfile = s;
            this.resolveBuilder_.finished_.neverTouchFinishfile = s;
        end
        function g    = getNeverTouch(this)
            g = this.finished_.neverTouchFinishfile;     
            if (~isempty(this.compositeResolveBuilder_))
                try
                    g = g && this.compositeResolveBuilder_.finished_.neverTouchFinishfile; %#ok<*NASGU>
                catch ME
                    handwarning(ME);
                end
            end
            if (~isempty(this.resolveBuilder_))
                try
                    g = g && this.resolveBuilder_.finished_.neverTouchFinishfile;
                catch ME
                    handwarning(ME);
                end
            end
        end
        
        function this = locallyStageBrainmasks(this)
            
            sd = this.sessionData;
            if (~lexist_4dfp(                  sd.brainmask('typ', 'fp')))
                this.sessionData.mri_convert(  sd.brainmask.fqfilename, [sd.brainmask('typ', 'fp') '.nii']);
                this.buildVisitor.nifti_4dfp_4(sd.brainmask('typ', 'fp'));
            end
            if (~lexist_4dfp(                  sd.aparcAseg('typ', 'fp')))
                sd.mri_convert(                sd.aparcAseg.fqfilename, [sd.aparcAseg('typ', 'fp') '.nii']);
                this.buildVisitor.nifti_4dfp_4(sd.aparcAseg('typ', 'fp'));
            end
            if (~lexist_4dfp(                  sd.wmparc('typ', 'fp')))
                sd.mri_convert(                sd.wmparc.fqfilename,    [sd.wmparc('typ', 'fp') '.nii']);
                this.buildVisitor.nifti_4dfp_4(sd.wmparc('typ', 'fp'));
            end
        end
        function this = locallyStageModalities(this, varargin)
            %% LOCALLYSTAGEMODALITIES
            %  @param existing T1, t2, tof (if existing), umapSynth on the filesystem as specified by this.sessionData.
            %  @param named fourdfp are 4dfp fileprefixes.
            %  @param named fqfn are filenames.
            %  @return sym-links in the pwd to T1, t2, tof (if existing), umapSynth, fourdfp & fqfn.
            
            bv = this.buildVisitor;
            
            ip = inputParser;
            addParameter(ip, 'fourdfp', ''); %, @(x) bv.lexist_4dfp(x));
            addParameter(ip, 'fqfn',    ''); %, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            trydelete([this.T1('typ','fp') '.4dfp.*']);
            bv.copyfile_4dfp(   this.T1('typ','fqfp'));  
            trydelete([this.umapSynth('tracer', '', 'typ','fp') '.4dfp.*']);
            bv.copyfile_4dfp(   this.umapSynth('tracer', '', 'typ', 'fqfp'));
            
            if (~isempty(ip.Results.fourdfp))
                try
                    ffp = ensureCell(ip.Results.fourdfp);
                    dprintf('mlpet.TracerBuilder.locallyStageModalities:  copyfile_4dfp %s', ...
                        cell2str(ffp, 'AsRows', true));
                    cellfun(@(x) bv.copyfile_4dfp(x), ffp, 'UniformOutput', false);
                catch ME
                    dispwarning(ME);
                end
            end
            if (~isempty(ip.Results.fqfn))
                try
                    fqfn = ensureCell(ip.Results.fqfn);
                    dprintf('mlpet.TracerBuilder.locallyStageModalities:  copyfile %s', ...
                        cell2str(fqfn, 'AsRows', true));
                    cellfun(@(x) copyfile(x), fqfn, 'UniformOutput', false);
                catch ME
                    dispwarning(ME);
                end
            end
        end
        function this = locallyStageTracer(this)
            %% LOCALLYSTAGETRACER 
            %  @param this.sessionData must be well-formed with valid methods:
            %  tracerLocation, tracerLocation, tracerListmodeMhdr, tracerListmodeSif, tracerSif, mprage, atlas.
            %  @param valid named param vendorSupport in ctor.
            %  @param recoverBackup logical:  if recoverBackup then [this.sessionData.tracerLocation '-Backup'] must be a well-formed dir.
            %  @return this.product := vendorSupport->cropfrac(this.sessionData.tracerSif) as mlfourdfp.ImagingContext.
            
            this.prepareTracerLocation;         
            this.prepareListmodeMhdr;
            this.prepareMprToAtlasT4;
            this = this.prepareCroppedTracerRevision;
        end
        function this = prepareTracerLocation(this, varargin)
            %% PREPARETRACERLOCATION
            %  @param this.sessionData.tracerLocation is valid.
            %  @param doRecovery is logical.  
            %         Default is false.  If true, backup ~tracerLocation to [tracerLocation '-Backup'].
            %  @return ~tracerLocation, a filepath, is dir.
            %  @return this.product_ := ~tracerLocation.
            
            ip = inputParser;
            addOptional(ip, 'doRecovery', false, @islogical);
            parse(ip, varargin{:});
            
            trLoc = this.sessionData.tracerLocation;
            if (ip.Results.doRecovery)
                movefile([trLoc '-Backup'], trLoc);
                return
            end            
            ensuredir(trLoc);
            this.product_ = trLoc;
        end
        function this = prepareListmodeMhdr(this)
            %% PREPARELISTMODEMHDR
            %  @param this.sessionData.{tracerListmodeMhdr,tracerListmodeSif,tracerSif} are valid, 
            %         not necessarily yet existing on the filesystem.
            %  @return ~tracerListmodeSif exists as file.
            %  @return ~tracerSif exists as 4dfp files.
            %  @return this.product_ := ~tracerSif as mlfourd.ImagingContext.
            
            sessd  = this.sessionData;
            bv     = this.buildVisitor;
            lmMhdr = sessd.tracerListmodeMhdr('typ', 'fqfp');
            lmSif  = sessd.tracerListmodeSif( 'typ', 'fqfp');
            trSif  = sessd.tracerSif(         'typ', 'fqfp');            
            assert(lexist(sessd.tracerListmodeMhdr, 'file'));
            
            %if (~bv.lexist_4dfp(lmSif))
                pwd0 = pushd(fileparts(lmSif));
                bv.sif_4dfp(lmMhdr, lmSif);
                popd(pwd0);
            %end   
            %if (~bv.lexist_4dfp(trSif))
                ensuredir(fileparts(trSif));
                pwd0 = pushd(fileparts(trSif));
                bv.lns_4dfp(lmSif);
                popd(pwd0);
            %end
            this.product_ = mlfourd.ImagingContext([trSif '.4dfp.hdr']);
        end
        function this = prepareCroppedTracerRevision(this)
            %% PREPARECROPPEDTRACERREVISION
            %  @param this.vendorSupport is valid.
            %  @param this.sessionData.{tracerRevision,filetypeExt} are valid.
            %  @return this.product := vendorSupport.cropfrac(this.sessionData.sif) as mlfourdfp.ImagingContext.
            
            this.vendorSupport_.sessionData = this.sessionData;
            sessd = this.vendorSupport_.sessionData;
            ext   =  sessd.filetypeExt;
            fqfp0 =  sessd.tracerListmodeSif('typ', 'fqfp', 'frame', sessd.frame);
            fqfp  =  sessd.tracerRevision(   'typ', 'fqfp', 'frame', sessd.frame);
            fqfn  = [fqfp '.4dfp.hdr'];
            
            import mlfourd.*;
            this.vendorSupport_.ensureTracerSymlinks; 
            if (lexist(fqfn, 'file'))   
                this.product_ = ImagingContext(fqfn);
                return
            end
            this.product_ = ImagingContext( ...
                [this.vendorSupport_.cropfrac(fqfp0, fqfp) ext]);
        end        
        function this = resolveModalitiesToProduct(this, varargin)
            %% RESOLVEMODALITIESTOTRACER resolves a set of images from heterogeneous modalities to the tracer encapsulated 
            %  within this.product. 
            %  @param  this.sessionData is well-formed for the problem. 
            %  @param  this.product is a single-epoch motion-corrected tracer.
            %  @param  modalities is a cell-array of fileprefixes without filepaths.
            %  @param  modalities or their sym-links are in the pwd.
            %  @param  named tag2 is char used when touching logging file by mlpipeline.Finished.
            %  @param  named mask is char := {'none' 'brainmask' 'headmask' ''}; 
            %  default := 'none'; '' =: use this.mask.
            %  @return these is a composite of mlpet.TracerResolveBuilder, each component.product containing
            %  the resolved heterogenous modalities.            
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addRequired( ip, 'modalities', @(x) iscell(x) && all(cellfun(@(y) lexist([y '.4dfp.hdr'], 'file'), x)));
            addParameter(ip, 'blurArg', this.sessionData.umapBlurArg, @isnumeric);
            addParameter(ip, 'tag', '', @ischar);
            addParameter(ip, 'tag2', '', @ischar);
            addParameter(ip, 'mask', this.mask, @ischar);
            parse(ip, varargin{:});
            this.mask = ip.Results.mask;
            
            pwd0 = pushd(this.product_.filepath);            
            this.sessionData_.rnumber = 1;
            theImages = [{this.product_.fileprefix} ip.Results.modalities];
            cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', theImages, ...
                'blurArg', ip.Results.blurArg, ...
                'maskForImages', this.mask, ...
                'NRevisions', 2);                        
            cRB_.ignoreFinishfile = true;
            cRB_ = cRB_.updateFinished('tag', ip.Results.tag, 'tag2', ip.Results.tag2);
                        
            % update this.{compositeResolveBuilder_,sessionData_,product_}   
            cRB_ = cRB_.resolve;  
            this.compositeResolveBuilder_ = cRB_;
            this.sessionData_             = cRB_.sessionData;
            this.product_                 = cRB_.product;            
            popd(pwd0);
        end
        function this = resolveProductToAnatomy(this, varargin)
            %% RESOLVEPRODUCTTOANATOMY resolves the tracer encapsulated within this.product to MP-RAGE anatomy. 
            %  @param  this.sessionData is well-formed for the problem. 
            %  @param  this.product is a single-epoch motion-corrected tracer.
            %  @param  anatomies or their sym-links are in the pwd.          
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'anatomy', this.sessionData.T1001('typ','fqfp'), @lexist_4dfp);
            addParameter(ip, 'blurArg', this.sessionData.umapBlurArg, @isnumeric);
            parse(ip, varargin{:});
            anatomy_ = mybasename(ip.Results.anatomy);
            if (~lexist_4dfp(anatomy_))
                this.buildVisitor_.copy_4dfp(ip.Results.anatomy, anatomy_);
            end
            anatomyToAtlT4 = sprintf('%s_to_%s_t4', anatomy_, this.sessionData.atlas('typ','fp'));
            if (~lexist(anatomyToAtlT4))
                copyfile(fullfile(this.sessionData.vLocation, anatomyToAtlT4));
                assert(lexist(anatomyToAtlT4));
            end
            
            pwd0 = pushd(this.product_.filepath);            
            this.sessionData_.rnumber = 1;
            theImages = {anatomy_ this.product_.fileprefix};
            cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', theImages, ...
                'blurArg', ip.Results.blurArg, ...
                'maskForImages', {anatomy_, this.product_.fileprefix}, ...
                'NRevisions', 1);                        
            cRB_ = cRB_.updateFinished('tag', ['mlpet_TracerBuilder_resolveProductToAnatomy_' anatomy_]);

            % update this.{compositeResolveBuilder_,sessionData_,product_}   
            cRB_ = cRB_.resolve;  
            this.compositeResolveBuilder_ = cRB_;
            this.sessionData_             = cRB_.sessionData;
            this.product_                 = cRB_.product; 
            popd(pwd0);
        end
        function tof  = resolveTofToT1(this)
            %pwd0 = pushd(this.sessionData.tof('typ', 'filepath'));
            [~,fqfp] = this.buildVisitor.align_TOF( ...
                'dest', this.sessionData.T1('typ', 'fp'), ...
                'source', this.sessionData.tof('typ', 'fp'), ...
                'destBlur', 1.0, ...
                'sourceBlur', 1.0, ...
                't40', this.buildVisitor.sagittal_inv_t4, ...
                'useMetricGradient', true);
            tof = mlfourd.ImagingContext([fqfp '.4dfp.hdr']);
            %popd(pwd0);
        end
        
 		function this = TracerBuilder(varargin)
 			%% TRACERBUILDER
            %  @param named 'roisBuilder' is an mlrois.IRoisBuilder.
            %  @param named 'resolveBuilder' is an mlfourdfp.T4ResolveBuilder.
            %  @param named 'compositeResolveBuilder' is an mlfourdp.CompositeT4ResolveBuilder.
            %  @param named 'vendorSupport' is, e.g., mlsiemens.MMRBuilder.
 			
            this = this@mlfourdfp.AbstractSessionBuilder(varargin{:});
            
            import mlfourdfp.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'roisBuilder', ...
                [], @(x) isempty(x) || isa(x, 'mlrois.IRoisBuilder')); % mlpet.BrainmaskBuilder('sessionData', this.sessionData)
            addParameter(ip, 'resolveBuilder', ...
                [], @(x) isa(x, 'mlfourdfp.T4ResolveBuilder') || isempty(x));
            addParameter(ip, 'compositeResolveBuilder', ...
                [], @(x) isa(x, 'mlfourdfp.CompositeT4ResolveBuilder') || isempty(x));
            addParameter(ip, 'vendorSupport', ...
                mlsiemens.MMRBuilder('sessionData', this.sessionData));
            addParameter(ip, 'ac', this.sessionData.attenuationCorrected, @islogical);
            parse(ip, varargin{:});
            
            this.roisBuilder_                     = ip.Results.roisBuilder;
            this.resolveBuilder_                  = ip.Results.resolveBuilder;
            this.compositeResolveBuilder_         = ip.Results.compositeResolveBuilder;
            this.vendorSupport_                   = ip.Results.vendorSupport;
            this.sessionData.attenuationCorrected = ip.Results.ac;
        end        
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        compositeResolveBuilder_
        resolveBuilder_
        roisBuilder_
        vendorSupport_
    end    
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

