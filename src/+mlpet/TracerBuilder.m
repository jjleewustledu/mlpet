classdef TracerBuilder < mlpipeline.AbstractDataBuilder
	%% TRACERBUILDER.

	%  $Revision$
 	%  was created 9-Mar-2017 15:39
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlfourdfp/src/+mlfourdfp.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2017 John Joowon Lee. 	

    
    properties
    end
    
    properties (Dependent)
        buildVisitor
        compositeResolveBuilder
        finished
        framesResolveBuilder
        roisBuilder
    end    
        
    methods 
        
        %% GET/SET
        
        function g = get.buildVisitor(this)
            g = this.buildVisitor_;
        end
        function g = get.compositeResolveBuilder(this)
            g = this.compositeResolveBuilder_;
        end
        function g = get.finished(this)
            g = this.product.finished;
        end
        function g = get.framesResolveBuilder(this)
            g = this.framesResolveBuilder_;
        end
        function g = get.roisBuilder(this)
            g = this.roisBuilder_;
        end
        
        function this = set.roisBuilder(this, s)
            assert(isa(s, 'mlrois.IRoisBuilder'));
            this.roisBuilder_ = s;
        end

        %%
        
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
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'buildVisitor', mlfourdfp.FourdfpVisitor, @(x) isa(x, 'mlfourdfp.FourdfpVisitor'));
            addParameter(ip, 'roisBuild', mlpet.BrainmaskBuilder('sessionData', this.sessionData), @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            
            this.buildVisitor_ = ip.Results.buildVisitor;
            import mlfourdfp.*;
            %this.framesResolveBuilder_ = T4ResolveBuilder('sessionData', this.sessionData);
            %this.compositeResolveBuilder_ = CompositeT4ResolveBuilder('sessionData', this.sessionData);
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
        
    %% PRIVATE
    
    properties (Access = private)
        buildVisitor_
        compositeResolveBuilder_
        framesResolveBuilder_
        roisBuilder_
    end    
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

