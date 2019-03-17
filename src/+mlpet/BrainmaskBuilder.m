classdef BrainmaskBuilder < mlpet.RoisBuilder
	%% BRAINMASKBUILDER builds binary masks of the brain, cerebellum and brainstem for use by 
    %  various project directors, e.g., mlraichle.HyperglycemiaDirector, mlraichle.HoDirector.
    %  Access the roi with property product.

	%  $Revision$
 	%  was created 01-Jun-2017 16:50:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
	methods	
        
        function [bmbb,ct4rb] = brainmaskBinarized(this, varargin)
            %% BRAINMASKBINARIZED resolves brainmaskBinarizeBlended to tracer
            %  @param named tracer is an mlfourd.ImagingContext.
            %  @param named reuse is logical; reusing existing brainmaskBinarizeBlended is default.
            %  @returns bmbb, brainmaskBinarizeBlended, as mlfourd.ImagingContext.
            %  @returns ct4rb as mlfourdfp.CompositeT4ResolveBuilder.
            
            ip = inputParser;
            addParameter(ip, 'tracer', [],  @(x) isa(x, 'mlfourd.ImagingContext')); 
            addParameter(ip, 'reuse', true, @islogical);
            parse(ip, varargin{:});
            
            pwd0    = pushd(ensuredir(this.sessionData.tracerLocation));
            sessd   = this.sessionData;
            tr      = ip.Results.tracer;
            if (~lexist([tr.fileprefix '_brain.4dfp.hdr'], 'file'))
                [~,msktNorm] = this.msktgenImg; % ImagingContext
                msktNormNN   = msktNorm.numericalNiftid;
                tr_sumtNN    = tr.numericalNiftid;
                tr           = mlfourd.ImagingContext(tr_sumtNN.*msktNormNN);
                tr.filepath  = pwd;
                tr.filename  = [ip.Results.tracer.fileprefix '_brain.4dfp.hdr'];
                tr.save;
            end
            
            if (~lexist(this.brainmask.filename, 'file')) % in cwd
                this.buildVisitor.lns_4dfp(this.brainmask.fqfileprefix);
            end            
            ct4rb = mlfourdfp.CompositeT4ResolveBuilder( ...
                'sessionData', sessd, 'theImages', {tr.fileprefix this.brainmask.fileprefix});
            bmbbFn = sessd.brainmaskBinarizeBlended('tag', ['_' ct4rb.resolveTag], 'typ', 'fn.4dfp.hdr');
            if (ip.Results.reuse && lexist(bmbbFn))
                bmbb = mlfourd.ImagingContext(bmbbFn);
                return
            end
            ct4rb = ct4rb.resolve;
            bmbb  = ct4rb.product{2};
            bmbb.numericalNiftid; % retain ImagingContext
            bmbb  = bmbb.binarizeBlended;
            bmbb.saveas(bmbbFn);
            
            % teardown
            this.teardown('tracer', ip.Results.tracer, 'sessionData', ct4rb.sessionData);
            popd(pwd0);
        end
        function teardown(this, varargin)
            ip = inputParser;
            addParameter(ip, 'tracer', [],  @(x) isa(x, 'mlfourd.ImagingContext')); 
            addParameter(ip, 'sessionData', this.sessionData, @(x) isa(x, 'mlpipeline.SessionData'));
            parse(ip, varargin{:});            
            return
            
            sessd = ip.Results.sessionData;
            tmpdir = fullfile(tempdir, mydatetimestr(now));
            mkdir(tmpdir);
            movefileExisting(sprintf('brainmaskr%i_op_*', sessd.rnumber-1), tmpdir);
            movefileExisting(sprintf('%s_brainr%i_op_*', ip.Results.tracer.fileprefix, sessd.rnumber-1), tmpdir);
            ensuredir('T4');
            movefileExisting('*_t4')
            deleteExisting('brainmaskr*');
            deleteExisting(sprintf('%s_brainr*', ip.Results.tracer.fileprefix));
            deleteExisting('*_b15.4dfp.*');
            movefileExisting(fullfile(tmpdir, '*'));
            rmdir(tmpdir);
        end
        
 		function this = BrainmaskBuilder(varargin)
 			%% BRAINMASKBUILDER ensures there exists sessionData.sessionPath/brainmask.4dfp.hdr;
            %  it is set as the initial state of this.product.
            %  @param named 'logger' is an mlpipeline.ILogger.
            %  @param named 'product' is the initial state of the product to build.
 			%  @param named 'sessionData' is an 'mlpipeline.ISessionData'.

 			this = this@mlpet.RoisBuilder(varargin{:});
            
            sessd = this.sessionData;
            bmfp  = fullfile(sessd.sessionPath, sessd.brainmask('typ', 'fp'));
            bmnii = [bmfp '.nii'];
            bmifh = [bmfp '.4dfp.hdr'];
            if (~lexist_4dfp(bmifh))
                sessd.mri_convert(sessd.brainmask('typ', 'fqfn'), bmnii);
                sessd.nifti_4dfp_4(bmfp);
            end
            this.product_ = mlfourd.ImagingContext(bmifh);
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

