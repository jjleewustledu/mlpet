classdef TracerBuilder < mlpipeline.AbstractDataBuilder & mlpet.ITracerBuilder
	%% TRACERBUILDER.

	%  $Revision$
 	%  was created 9-Mar-2017 15:39
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee. 	

     
    properties (Constant)
        MAX_MONOLITH_LENGTH = 8
    end
    
	properties
        activeFrames % frame1:frameEnd
        indexOfReference
        recoverNACFolder = false 
    end
    
    properties (Dependent)
        buildVisitor
        compositeResolveBuilder
        finished
        framesResolveBuilder
        resolveTag
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
        function g    = get.finished(this)
            g = this.product.finished;
        end
        function g    = get.framesResolveBuilder(this)
            g = this.framesResolveBuilder_;
        end
        function g    = get.resolveTag(this)
            g = this.sessionData.resolveTag;
        end
        function this = set.resolveTag(this, s)
            assert(ischar(s));
            this.sessionData.resolveTag = s;
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
            this.prepareNACLocation;         
            this = this.buildTracerNAC;
            this.prepareMR;
        end
        function        prepareNACLocation(this)
            %% PREPARENACLOCATION recovers the NAC location from backup or creates it de novo.
            
            sessd = this.sessionData;
            if (this.recoverNACFolder)
                movefile([sessd.tracerNACLocation '-Backup'], sessd.tracerNACLocation);
                return
            end            
            if (~isdir(sessd.tracerNACLocation))
                mkdir(sessd.tracerNACLocation);
            end            
        end
        function this = buildTracerNAC(this)
            %% BUILDTRACERNAC builds 4dfp-formatted tracer NAC images; use to prep data before conveying to clusters.
            %  See also:  mlfourdfp.FourdfpVisitor.sif_4dfp.
            
            sessd = this.sessionData;
            mhdr  = sessd.tracerListmodeMhdr( 'typ', 'fqfp');
            nac   = sessd.tracerNAC('typ', 'fqfp');
            
            if (this.buildVisitor.lexist_4dfp(nac))
                return
            end
            if (~this.buildVisitor.lexist_4dfp(mhdr))
                fprintf('mlraichle.T4ResolveBuilder.buildTracerNAC:  building %s\n', mhdr);
                cd(fileparts(mhdr));
                this.buildVisitor.sif_4dfp(mhdr);
            end
            if (~isdir(sessd.tracerNACLocation))
                mkdir(sessd.tracerNACLocation);
            end     
            pwd0 = pushd(sessd.tracerNACLocation);
            this.buildVisitor.lns_4dfp(mhdr);
            popd(pwd0);
            %movefile([mhdr '.4dfp.*'], sessd.tracerNACLocation);
        end
        function        prepareMR(this)
            %% PREPAREMR runs msktgenMprage as needed for use by resolve.
            
            sessd      = this.sessionData;
            mpr        = sessd.mprage('typ', 'fp');
            atl        = sessd.atlas('typ', 'fp');
            mprToAtlT4 = [mpr '_to_' atl '_t4'];            
            if (~lexist(fullfile(sessd.mprage('typ', 'path'), mprToAtlT4)))
                cd(sessd.mprage('typ', 'path'));
                this.compositeResolveBuilder.msktgenMprage(mpr, atl);
            end
        end
        function this = gatherConvertedAC(this)
        end 
        function [this,aab] = resolveRoisOnAC(this, varargin)
            %% RESOLVEROISONAC
            %  @params named 'roisBuild' is an 'mlrois.IRoisBuilder'
            %  @returns aab, an mlfourd.ImagingContext from mlpet.BrainmaskBuilder.aparcAsegBinarized.
            
            ip = inputParser;
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});            
            sessd = this.sessionData;
            
            % actions
            
            pwd0 = sessd.petLocation;
            ensuredir(pwd0);
            pushd(pwd0);
            bmb = mlpet.BrainmaskBuilder('sessionData', sessd);
            [~,ct4rb] = bmb.brainmaskBinarized( ...
                'tracer', this.sessionData.tracerRevisionSumt('typ', 'mlfourd.ImagingContext'));
            aab = bmb.aparcAsegBinarized(ct4rb);
            popd(pwd0);
        end
        
 		function this = TracerBuilder(varargin)
 			%% TRACERBUILDER
            %  @params named 'logger' is an mlpipeline.AbstractLogger.
            %  @params named 'product' is the initial state of the product to build.
            %  @params named 'sessionData' is an mlpipeline.ISessionData.
 			%  @params named 'buildVisitor' is an mlfourdfp.FourdfpVisitor.
            %  @params named 'roisBuild' is an mlrois.IRoisBuilder.
 			
            this = this@mlpipeline.AbstractDataBuilder(varargin{:});
            
            import mlfourdfp.*;
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'buildVisitor', ...
                FourdfpVisitor, @(x) isa(x, 'mlfourdfp.FourdfpVisitor'));
            addParameter(ip, 'roisBuild', ...
                mlpet.BrainmaskBuilder( ...
                    'sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
%             addParameter(ip, 'framesResolveBuild', ...
%                 T4ResolveBuilder( ...
%                     'sessionData', this.sessionData), @(x) isa(x, 'mlfourdfp.T4ResolveBuilder'));
%             addParameter(ip, 'compositeResolveBuild', ...
%                 CompositeT4ResolveBuilder( ...
%                     'sessionData', this.sessionData), @(x) isa(x, 'mlfourdfp.CompositeT4ResolveBuilder'));
            addParameter(ip, 'vendorSupport', ...
                mlsiemens.MMRBuilder('sessionData', this.sessionData));
            parse(ip, varargin{:});
            
            this.buildVisitor_ = ip.Results.buildVisitor;
            this.roisBuilder_ = ip.Results.roisBuild;
%            this.framesResolveBuilder_ = ip.Results.framesResolveBuild;
%            this.compositeResolveBuilder_ = ip.Results.compositeResolveBuild;
            this.vendorSupport_ = ip.Results.vendorSupport;
        end        
 	end 
    
    %% PROTECTED
    
    methods (Access = 'protected')
        function fr   = firstFortranTimeFrame(this)
            NNativeFrames = this.framesResolveBuilder.imageFrames.readLength(this.sessionData.tracerRevision('typ', 'fqfp'));
            NUmapFrames   = this.framesResolveBuilder.imageFrames.readLength(this.sessionData.tracerResolved('typ', 'fqfp'));
            fr = NNativeFrames - NUmapFrames + 1;
        end
        function fp   = frameFileprefix(~, fp, fr)
            fp = sprintf('%s_frame%i', fp, fr);
        end
        function f    = epochNumber(~, str)
            names = regexp(str, '\w+(-|_)(E|e)poch(?<f>\d+)', 'names');
            f = str2double(names.f);
        end
        function f    = segmentNumber(~, str)
            names = regexp(str, '\w+(-|_)(S|s)eg(?<f>\d+)', 'names');
            f = str2double(names.f);
        end
        function f    = frameNumber(~, str, offset)
            names = regexp(str, '\w+(-|_)(F|f)rame(?<f>\d+)', 'names');
            f = str2double(names.f) + offset;
        end
        function pth  = logPath(this)
            pth = fullfile(this.sessionData.tracerLocation, 'Log', '');
            if (~isdir(pth))
                mkdir(pth);
            end
        end
        function this = pasteFrames(this, varargin)
            
            ip = inputParser;
            addRequired(ip, 'ipr', @isstruct);
            addOptional(ip, 'tag', '', @ischar);
            parse(ip, varargin{:});
            ipr = ip.Results.ipr;
            tag = mybasename(ip.Results.tag);
            
            assert(isfield(  ipr, 'dest'));
            assert(ischar(   ipr.dest));
            assert(isfield  (ipr, 'frames'));
            assert(isnumeric(ipr.frames));
            
            pasteList = sprintf('%s_%s_paste.lst', ipr.dest, tag);
            if (lexist(pasteList)); delete(pasteList); end
            
            fid = fopen(pasteList, 'w');
            for f = 1:length(ipr.frames)
                if (ipr.frames(f))
                    fqfp = this.frameFileprefix(ipr.dest, f);
                    fprintf(fid, '%s_%s.4dfp.img\n', fqfp, tag);
                end
            end
            fclose(fid);
            this.buildVisitor.paste_4dfp(pasteList, [ipr.dest '_' tag], 'options', '-a ');
        end
    end
        
    properties (Access = protected)
        buildVisitor_
        compositeResolveBuilder_
        framesResolveBuilder_
        roisBuilder_
        vendorSupport_
    end    
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

