classdef TracerBuilder < mlpet.AbstractTracerBuilder
	%% TRACERBUILDER

	%  $Revision$
 	%  was created 9-Mar-2017 15:39
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee. 	
    
    
    properties 
        sourceBlur = 1.5
        destBlur   = 1.5
    end
    
    properties (Dependent)
        compositeResolveBuilder
        resolveBuilder
        roisBuilder
        vendorSupport
    end
    
    methods (Static)
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
            this.finished_.neverTouch = s;  
            this.compositeResolveBuilder_.finished_.neverTouch = s;
            this.resolveBuilder_.finished_.neverTouch = s;
        end
        function g = getNeverTouch(this)
            g = this.finished_.neverTouch;     
            if (~isempty(this.compositeResolveBuilder_))
                try
                    g = g && this.compositeResolveBuilder_.finished_.neverTouch; %#ok<*NASGU>
                catch ME
                    handwarning(ME);
                end
            end
            if (~isempty(this.resolveBuilder_))
                try
                    g = g && this.resolveBuilder_.finished_.neverTouch;
                catch ME
                    handwarning(ME);
                end
            end
        end
        
        function this = locallyStageParcs(this)
            
            sd = this.sessionData;
            if (~lexist_4dfp(sd.brainmask('typ', 'fp')))
                this.sessionData.mri_convert(  sd.brainmask.fqfilename, [sd.brainmask('typ', 'fp') '.nii']);
                this.buildVisitor.nifti_4dfp_4(sd.brainmask('typ', 'fp'));
            end
            if (~lexist_4dfp(sd.aparcAseg('typ', 'fp')))
                sd.mri_convert(                sd.aparcAseg.fqfilename, [sd.aparcAseg('typ', 'fp') '.nii']);
                this.buildVisitor.nifti_4dfp_4(sd.aparcAseg('typ', 'fp'));
            end
            if (~lexist_4dfp(sd.wmparc('typ', 'fp')))
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
            addParameter(ip, 'fourdfp', '', @(x) bv.lexist_4dfp(x));
            addParameter(ip, 'fqfn',    '', @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            bv.lns_4dfp(this.T1('typ','fqfp'));            
            bv.lns_4dfp(this.t2('typ','fqfp'));  
            if (bv.lexist_4dfp(this.tof('typ','fqfp')))
                bv.lns_4dfp(this.tof('typ','fqfp'));
            end
            bv.lns_4dfp(this.umapSynth('tracer', '', 'typ', 'fqfp'));
            if (~isempty(ip.Results.fourdfp))
                ffp = ensureCell(ip.Results.fourdfp);
                dprintf('mlpet.TracerBuilder.locallyStageModalities:  lns_4dfp %s', ...
                    cell2str(ffp, 'AsRows', true));
                cellfun(@(x) bv.lns_4dfp(x), ffp, 'UniformOutput', false);
            end
            if (~isempty(ip.Results.fqfn))
                fqfn = ensureCell(ip.Results.fqfn);
                dprintf('mlpet.TracerBuilder.locallyStageModalities:  lns_4dfp %s', ...
                    cell2str(fqfn, 'AsRows', true));
                cellfun(@(x) bv.lns(x), fqfn, 'UniformOutput', false);
            end
        end
        function this = locallyStageTracer(this)
            %% LOCALLYSTAGETRACER 
            %  @param this.sessionData must be well-formed with valid methods:
            %  tracerLocation, tracerLocation, tracerListmodeMhdr, tracerListmodeSif, tracerMhdr, tracerSif, mprage, atlas.
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
            
            if (~bv.lexist_4dfp(lmSif))
                pwd0 = pushd(fileparts(lmSif));
                bv.sif_4dfp(lmMhdr, lmSif);
                popd(pwd0);
            end   
            if (~bv.lexist_4dfp(trSif))
                ensuredir(fileparts(trSif));
                pwd0 = pushd(fileparts(trSif));
                bv.lns_4dfp(lmSif);
                popd(pwd0);
            end
            this.product_ = mlfourd.ImagingContext([trSif '.4dfp.ifh']);
        end
        function this = prepareMprToAtlasT4(this)
            %% PREPAREMPRTOATLAST4
            %  @param this.sessionData.{mprage,atlas} are valid.
            %  @return this.product_ := [mprage '_to_' atlas '_t4'], existing in the same folder as mprage.
            
            sessd      = this.sessionData;
            mpr        = sessd.mprage('typ', 'fp');
            atl        = sessd.atlas('typ', 'fp');
            mprToAtlT4 = [mpr '_to_' atl '_t4'];            
            if (~lexist(fullfile(sessd.mprage('typ', 'path'), mprToAtlT4)))
                pwd0 = pushd(sessd.mprage('typ', 'path'));
                this.compositeResolveBuilder.msktgenMprage(mpr, atl);
                popd(pwd0);
            end
            this.product_ = mprToAtlT4;
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
            fqfn  = [fqfp '.4dfp.ifh'];
            
            import mlfourd.*;
            this.vendorSupport_.ensureTracerSymlinks; 
            if (lexist(fqfn, 'file'))   
                this.product_ = ImagingContext(fqfn);
                return
            end
            this.product_ = ImagingContext( ...
                [this.vendorSupport_.cropfrac(fqfp0, fqfp) ext]);
        end
        function pth  = logPath(this)
            pth = fullfile(this.sessionData.tracerLocation, 'Log', '');
            ensuredir(pth);
        end
        function this = updateFinished(this, varargin)
            ip = inputParser;
            addParameter(ip, 'tag', ...
                sprintf('%s_%s', lower(this.sessionData.tracerRevision('typ','fp')), class(this)), ...
                @ischar);
            addParameter(ip, 'tag2', '', @ischar);
            parse(ip, varargin{:});
            
            ensuredir(this.logPath);
            this.finished_ = mlpipeline.Finished(this, ...
                'path', this.logPath, 'tag', sprintf('%s%s', ip.Results.tag, ip.Results.tag2));
        end
        
        function this = prepareProduct(this, prod)
            if (~isa(prod, 'mlfourd.ImagingContext'))
                prod = mlfourd.ImagingContext(prod);
            end
            this.product_ = prod;
        end
        function        reconstituteImgRec(this, varargin)  
            %% RECONSTITUTEIMGREC
            %  @param filesystem has {this.sessionData.tracerConvertedLocation} for all available frames.
            %  @param named fqfp, or fully-qualified fileprefix, of output; defaults to this.product.fqfileprefix. 
            %  @return prepend timing information from sif_4dfp1 to start of [fqfp '.4dfp.img.rec'].
            
            %  TODO @param named toskip is numeric and should be determined by inspection of motion-correction results.

            bv = this.buildVisitor;
            ip = inputParser;
            addParameter(ip, 'fqfp', this.product.fqfileprefix, @bv.lexist_4dfp);
            addParameter(ip, 'toskip', [], @isnumeric);
            parse(ip, varargin{:});
            
            sessd = this.sessionData_;
            assert(sessd.attenuationCorrected);  
            assert(isdir(sessd.tracerLocation));
            pwd0 = pushd(sessd.tracerLocation);
            prev = mlfourdfp.ImgRecParser.loadx(this.product.fqfileprefix, '.4dfp.img.rec');
            prev.saveas([this.product.fqfileprefix '_' datestr(now, 30) '.4dfp.img.rec']);
            imgrec = mlfourdfp.ImgRecLogger;
            imgrec.consNoHeadFoot(prev.cellContents)

            timingEntry0 = {'mlpet.TracerBuilder.reconstituteImgRec:' ...
                'Frame           Length(msec)    Midpoint(sec)   Start(msec)      Frame_Min       Frame_Max       Decay_Fac      Rescale'};
            timingEntries = {};
            sessd.frame = 0;
            innerf = 0;
            while (isdir(sessd.tracerConvertedLocation))

                assert(lexist(sessd.tracerListmodeSif('frame', sessd.frame), 'file'))
                imgrec_ = mlfourdfp.ImgRecParser.loadx(sessd.tracerListmodeSif('frame', sessd.frame, 'typ', 'fqfp'), '.4dfp.img.rec'); % handle
                timingEntries_ = imgrec_.extractLinesByRegexp( ...
                    '^Frame_\d+\s+\d+\s+\d+\.\d+\s+\d+\s+\d+\.\d+\s+\d+\.\d+\s+\d+\.\d+\s+\d+\s*$');
                assert(~isempty(timingEntries_))
                for te = 1:length(timingEntries_)
                    innerf = innerf + 1;
                    timingEntries_{te} = regexprep(timingEntries_{te}, '^Frame_\d+', sprintf('Frame_%i', innerf));
                end
                timingEntries = [timingEntries timingEntries_]; %#ok<AGROW>
                sessd.frame = sessd.frame + 1;
            end
            imgrec.cons([timingEntry0 timingEntries]);
            imgrec.saveas([ip.Results.fqfp '.4dfp.img.rec']);
            popd(pwd0);
        end
        function this = resolveModalitiesToTracer(this, varargin)
            %% RESOLVEMODALITIESTOTRACER resolves a set of images from heterogeneous modalities to the tracer encapsulated 
            %  within this.product. 
            %  @param  this.sessionData is well-formed for the problem. 
            %  @param  this.product is a single-epoch motion-corrected tracer.
            %  @param  modalities is a cell-array of fileprefixes without filepaths.
            %  @param  modalities or their sym-links are in the pwd.
            %  @param  varargin is a cell-array of heterogenous modalities instantiated as mlfourd.ImagingContext 
            %  objects; default := {T1, t2, tof}.
            %  @return these is a composite of mlpet.TracerResolveBuilder, each component.product containing
            %  the resolved heterogenous modalities.            
            
            ip = inputParser;
            addRequired( ip, 'modalities', @(x) iscell(x) && all(cellfun(@(y) lexist([y '.4dfp.ifh'], 'file'), x)));
            addParameter(ip, 'tag2', '', @ischar);
            parse(ip, varargin{:});
            
            pwd0 = pushd(this.product_.filepath);      
            this.sessionData_.rnumber = 1;
            theImages = [{this.product_.fileprefix} ip.Results.modalities];
            cRB_ = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', this.sessionData_, ...
                'theImages', theImages, ...
                'NRevisions', 2);                                        
            cRB_ = cRB_.updateFinished('tag2', ip.Results.tag2);
                        
            % update this.{compositeResolveBuilder_,sessionData_,product_}                      
            cRB_ = cRB_.resolve('destBlur', this.destBlur, 'sourceBlur', this.sourceBlur);             
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
            tof = mlfourd.ImagingContext([fqfp '.4dfp.ifh']);
            %popd(pwd0);
        end
        
 		function this = TracerBuilder(varargin)
 			%% TRACERBUILDER
            %  @param named 'roisBuilder' is an mlrois.IRoisBuilder.
            %  @param named 'resolveBuilder' is an mlfourdfp.T4ResolveBuilder.
            %  @param named 'compositeResolveBuilder' is an mlfourdp.CompositeT4ResolveBuilder.
            %  @param named 'vendorSupport' is, e.g., mlsiemens.MMRBuilder.
 			
            this = this@mlpet.AbstractTracerBuilder(varargin{:});
            
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

