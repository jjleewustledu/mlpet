classdef TracerBuilder < mlpipeline.AbstractDataBuilder
	%% TRACERBUILDER

	%  $Revision$
 	%  was created 9-Mar-2017 15:39
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee. 	
    
    properties (Dependent)
        buildVisitor
        compositeResolveBuilder
        resolveBuilder
        roisBuilder
        vendorSupport
    end
        
    methods 
        
        %% GET/SET
        
        function g    = get.buildVisitor(this)
            g = this.buildVisitor_;
        end
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
            fqfp0 =  sessd.tracerListmodeSif('typ', 'fqfp');
            fqfp  = [sessd.tracerRevision(   'typ', 'fqfp', 'frame', sessd.frame) '__'];
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
        function this = locallyStageModalities(this, varargin)
            %% LOCALLYSTAGEMODALITIES
            %  @param existing T1, t2, tof, umapSynth on the filesystem.
            %  @param named fourdfp are 4dfp fileprefixes.
            %  @param named fqfn are filenames.
            %  @return sym-links to T1, t2, tof, umapSynth in the pwd.  
            
            bv = this.buildVisitor;
            
            ip = inputParser;
            addParameter(ip, 'fourdfp', '', @(x) bv.lexist_4dfp(x));
            addParameter(ip, 'fqfn',    '', @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            bv.lns_4dfp(this.T1('typ','fqfp'));            
            bv.lns_4dfp(this.t2('typ','fqfp'));            
            %bv.lns_4dfp(this.tof('typ','fqfp'));
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
        
 		function this = TracerBuilder(varargin)
 			%% TRACERBUILDER
            %  @param named 'logger' is an mlpipeline.AbstractLogger.
            %  @param named 'product' is the initial state of the product to build; default := [].
            %  @param named 'sessionData' is an mlpipeline.ISessionData; default := [].
 			%  @param named 'buildVisitor' is an mlfourdfp.FourdfpVisitor.
            %  @param named 'roisBuilder' is an mlrois.IRoisBuilder.
            %  @param named 'resolveBuilder' is an mlfourdfp.T4ResolveBuilder.
            %  @param named 'compositeResolveBuilder' is an mlfourdp.CompositeT4ResolveBuilder.
            %  @param named 'vendorSupport' is, e.g., mlsiemens.MMRBuilder.
 			
            this = this@mlpipeline.AbstractDataBuilder(varargin{:});
            
            import mlfourdfp.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'buildVisitor', ...
                FourdfpVisitor, @(x) isa(x, 'mlfourdfp.FourdfpVisitor'));
            addParameter(ip, 'roisBuilder', ...
                mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            addParameter(ip, 'resolveBuilder', ...
                [], @(x) isa(x, 'mlfourdfp.T4ResolveBuilder') || isempty(x));
            addParameter(ip, 'compositeResolveBuilder', ...
                [], @(x) isa(x, 'mlfourdfp.CompositeT4ResolveBuilder') || isempty(x));
            addParameter(ip, 'vendorSupport', ...
                mlsiemens.MMRBuilder('sessionData', this.sessionData));
            parse(ip, varargin{:});
            
            this.buildVisitor_            = ip.Results.buildVisitor;
            this.roisBuilder_             = ip.Results.roisBuilder;
            this.resolveBuilder_          = ip.Results.resolveBuilder;
            this.compositeResolveBuilder_ = ip.Results.compositeResolveBuilder;
            this.vendorSupport_           = ip.Results.vendorSupport;
        end        
 	end 
    
    %% PROTECTED
    
    properties (Access = protected)
        buildVisitor_
        compositeResolveBuilder_
        resolveBuilder_
        roisBuilder_
        vendorSupport_
    end    
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

