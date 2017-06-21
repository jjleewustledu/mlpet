classdef TracerBuilder < mlpipeline.AbstractDataBuilder & mlpet.ITracerBuilder
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
    
    methods (Static)
        function viewStudyConverted(varargin)
            ip = inputParser;
            addParameter(ip, 'ac', false, @islogical);
            addParameter(ip, 'tracer', 'FDG', @ischar);
            parse(ip, varargin{:});
            
            fv = mlfourdfp.FourdfpVisitor;
            studyd = mlraichle.StudyData;
            cd(studyd.subjectsDir);
            subjs = mlsystem.DirTool('HYGLY*');
            for d = 1:length(subjs)
                for v = 1:2
                    try
                        sessd = mlraichle.SessionData( ...
                            'studyData', studyd, 'sessionPath', subjs.fqdns{d}, 'vnumber', v, ...
                            'tracer', ip.Results.tracer, 'ac', ip.Results.ac);
                        cd(sessd.tracerListmodeLocation);
                        if (~lexist(sessd.tracerListmodeSif('typ','fn'), 'file'))
                            fv.sif_4dfp(sessd.tracerListmodeMhdr('typ','fp'))
                        end
                    catch ME
                        handwarning(ME);
                    end
                end
            end
            for d = 1:length(subjs)
                for v = 1:2
                    try
                        sessd = mlraichle.SessionData( ...
                            'studyData', studyd, 'sessionPath', subjs.fqdns{d}, 'vnumber', v, ...
                            'tracer', ip.Results.tracer, 'ac', ip.Results.ac);
                        cd(sessd.tracerListmodeLocation);
                        ic = mlfourd.ImagingContext(sessd.tracerListmodeSif('typ','fn'));
                        ic.viewer = 'fslview';
                        ic.view;
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
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
            %% GATHERCONVERTEDAC ensures working directories, cropped tracer field-of-view, tracer blurred to point-spread, 
            %  HO_sumt, T1 and umapSynth.  Working format is 4dfp.
            
            bv       = this.buildVisitor;
            meth     = [class(this) '.gatherConvertedAC'];
            sessd    = this.sessionData;
            sessdNAC = sessd;
            sessdNAC.attenuationCorrected = false;
            
            % actions
            
            pwd0 = sessd.petLocation;
            ensuredir(pwd0);
            pushd(pwd0);
            assert(lexist_4dfp(sessd.tracerListmodeMhdr), '%s could not find %s', meth, sessd.tracerListmodeMhdr);            
            if (~lexist_4dfp(sessd.ho))
                if (~lexist_4dfp(sessd.tracerListmodeSif('typ', 'fqfp')))
                    bv.sif_4dfp(sessd.tracerListmodeMhdr, sessd.tracerListmodeSif('typ', 'fqfp'));
                end
                bv.cropfrac_4dfp(0.5, sessd.tracerListmodeSif('typ', 'fqfp'), sessd.ho);
            end
            if (~lexist_4dfp(sessd.ho('suffix', sessd.petPointSpreadSuffix)))
                bv.imgblur_4dfp(sessd.ho, mean(sessd.petPointSpread));
            end
            if (~lexist_4dfp(sessd.ho('suffix', '_sumt')))
                m =  bv.ifhMatrixSize(sessd.ho('typ', 'fqfn'));
                bv.actmapf_4dfp(sprintf('"%i+"', m(4)), sessd.ho, 'options', '-asumt');
            end
            assert(lexist_4dfp(sessd.T1));
            assert(lexist_4dfp(sessdNAC.umapSynth));
            popd(pwd0);
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
            import mlraichle.*;
            bmb = mlpet.BrainmaskBuilder('sessionData', sessd);
            [~,ct4rb] = bmb.brainmaskBinarized( ...
                'tracer', this.sessionData.tracerRevisionSumt('typ', 'mlfourd.ImagingContext'));
            aab = bmb.aparcAsegBinarized(ct4rb);
            popd(pwd0);
        end
        
 		function this = TracerBuilder(varargin)
 			%% TRACERBUILDER
 			%  @param named 'buildVisitor' is an mlfourdfp.FourdfpVisitor.
 			
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

