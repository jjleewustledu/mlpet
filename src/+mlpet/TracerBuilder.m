classdef TracerBuilder < mlpipeline.AbstractDataBuilder & mlpet.ITracerBuilder
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

        %%
        
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
            this = this.prepareTracerRevision;
        end
        function this = prepareTracerLocation(this, varargin)
            %% PREPARETRACERLOCATION
            %  @param this.sessionData has valid method tracerLocation.
            %  @param doRecovery is logical (default false).  If true then backup exists at [tracerLocation '-Backup'].
            %  @return this.product_ := tracerLocation on the filesystem, a filepath.  
            
            ip = inputParser;
            addOptional(ip, 'doRecovery', false, @islogical);
            parse(ip, varargin{:});
            
            tracerLoc = this.sessionData.tracerLocation;
            if (ip.Results.doRecovery)
                movefile([tracerLoc '-Backup'], tracerLoc);
                return
            end            
            if (~isdir(tracerLoc))
                mkdir(tracerLoc);
            end  
            this.product_ = tracerLoc;
        end
        function this = prepareListmodeMhdr(this)
            %% PREPARELISTMODEMHDR
            %  @param this.sessionData has valid methods tracerLocation, tracerListmodeMhdr, tracerListmodeSif, tracerMhdr, tracerSif.
            %  @return tracerListmodeMhdr, tracerMhdr, tracerListmodeSif, tracerSif exist.
            %  @return this.product_ := tracerSif as mlfourd.ImagingContext.
            
            lmMhdr = this.sessionData.tracerListmodeMhdr('typ', 'fqfp');
            lmSif  = this.sessionData.tracerListmodeSif( 'typ', 'fqfp');
            sif    = this.sessionData.tracerSif(         'typ', 'fqfp');
            
            assert(lexist(this.sessionData.tracerListmodeMhdr), ...
                'mlpet:fileNotFound', ...
                'TracerBuilder.prepareListmodeMhdr could not find %s; review e7tools/JSRecon12', ...
                this.sessionData.tracerListmodeMhdr);
            if (~this.buildVisitor.lexist_4dfp(lmSif))
                pwd0 = pushd(fileparts(lmSif));
                this.buildVisitor.sif_4dfp(lmMhdr);
                popd(pwd0);
            end   
            if (~this.buildVisitor.lexist_4dfp(sif))
                pwd0 = pushd(fileparts(sif));
                this.buildVisitor.lns_4dfp(lmSif);
                popd(pwd0);
            end
            this.product_ = mlfourd.ImagingContext([sif '.4dfp.ifh']);
        end
        function this = prepareMprToAtlasT4(this)
            %% PREPAREMPRTOATLAST4
            %  @param this.sessionData has valid methods mprage, atlas.
            %  @return this.product_ := [mprage '_to_' atlas '_t4'] existing in the same folder as mprage.
            
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
        function this = prepareTracerRevision(this)
            %% PREPARETRACERREVISION
            %  @param valid param named vendorSupport in ctor.
            %  @param valid this.sessionData.
            %  @return this.product := vendorSupport->cropfrac(this.sessionData.tracerSif) as mlfourdfp.ImagingContext.
            
            this.vendorSupport_.ensureTracerSymlinks; 
            import mlfourd.*;
            if (this.buildVisitor.lexist_4dfp(this.sessionData.tracerRevision('typ','fqfp')))                
                this.product_ = ImagingContext(this.sessionData.tracerRevision);
                return
            end
            this.product_ = ImagingContext( ...
                [this.vendorSupport_.cropfrac(this.vendorSupport_.sif) this.sessionData.filetypeExt]);
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
            bv.lns_4dfp(this.tof('typ','fqfp'));
            bv.lns_4dfp(this.umapSynth('tracer', '', 'typ', 'fqfp'));
            if (~isempty(ip.Results.fourdfp))
                cellfun(@(x) bv.lns_4dfp(x), ensureCell(ip.Results.fourdfp), 'UniformOutput', false);
            end
            if (~isempty(ip.Results.fqfn))
                cellfun(@(x) bv.lns(x),      ensureCell(ip.Results.fqfn),    'UniformOutput', false);
            end
        end
        function pth  = logPath(this)
            pth = fullfile(this.sessionData.tracerLocation, 'Log', '');
            if (~isdir(pth))
                mkdir(pth);
            end
        end
        function this  = updateFinished(this, varargin)
            ip = inputParser;
            addParameter(ip, 'tag', ...
                sprintf('%s_%s', lower(this.sessionData.tracerRevision('typ','fp')), class(this)), ...
                @ischar);
            parse(ip, varargin{:});
            
            this.finished_ = mlpipeline.Finished(this, 'path', this.logPath, 'tag', ip.Results.tag);
        end
        
 		function this = TracerBuilder(varargin)
 			%% TRACERBUILDER
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

