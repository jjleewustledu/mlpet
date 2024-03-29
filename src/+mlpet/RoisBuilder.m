classdef RoisBuilder < mlfourdfp.AbstractSessionBuilder
	%% ROISBUILDER  

	%  $Revision$
 	%  was created 01-Jun-2017 15:58:20 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlrois/src/+mlrois.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
    
	methods         
        
        %%
        
        function aab = aparcAsegBinarized(this, varargin)
            %% APARCASEGBINARIZED uses a pre-existing ct4rb to orthogonally project aparcAseg to the target of ct4rb,
            %  then binarize.
            %  @param required t4rb is an mlfourdfp.IT4ResolveBuilder.
            %  @param optional reuse is logical; default true -> use aparcAsegBinarized_op_tracerRevision.4dfp.hdr.
            %  returns aab, an mlfourd.ImagingContext.
            
            ip = inputParser;
            addRequired(ip, 't4rb',  @(x) isa(x, 'mlfourdfp.IT4ResolveBuilder'));
            addOptional(ip, 'reuse', true, @islogical);
            parse(ip, varargin{:});
            
            sessd = this.sessionData;            
            pwd0 = pushd(sessd.tracerLocation);
            aab = sprintf('aparcAsegBinarized_op_%s.4dfp.hdr', sessd.tracerRevision('typ','fp'));
            if (ip.Results.reuse && lexist(aab, 'file'))
                aab = mlfourd.ImagingContext(aab);
                return
            end
            
            aa = 'aparcAseg.4dfp.hdr';
            if (~lexist(aa))
                ic = mlfourd.ImagingContext2(sessd.aparcAseg('typ', 'mgz'));
                ic.selectFourdfpTool();
                ic.save();
                aa = ic.fqfileprefix;
            end
            t4rb = ip.Results.t4rb;
            t4 = sprintf('%s_to_%s_t4', sessd.brainmask('typ','fp'), t4rb.resolveTag);
            aa = t4rb.t4img_4dfp(t4, mybasename(aa), 'options', '-n'); % target is specified by t4rb
            aa = mlfourd.ImagingContext([aa '.4dfp.hdr']);
            nn = aa.numericalNiftid;
            nn.saveas(['aparcAseg_' t4rb.resolveTag '.4dfp.hdr']);
            nn = nn.binarized; % set threshold to intensity floor
            nn.saveas(['aparcAsegBinarized_' t4rb.resolveTag '.4dfp.hdr']);
            aab = mlfourd.ImagingContext(nn);
            
            % teardown
            this.teardown('sessionData', t4rb.sessionData);
            popd(pwd0);
        end
        function [mskt,msktNorm] = msktgenImg(this, varargin)
            %% MSKTGENIMG calls mpr2atl_4dfp and msktgen_4dfp on tracerFn to create quasi-binary masks.
            %  @param optional tracerFn is char; default is this.sessiondata.tracerRevisionAvgt.
            %  @returns mskt     is a quasi-binary mask with max ~ 1000 (mlfourd.ImagingContext)
            %  @returns msktNorm is a quasi-binary mask with max = 1    (mlfourd.ImagingContext)            
            
            ip = inputParser;
            addOptional(ip, 'tracerFn', this.sessionData.tracerRevisionAvgt('typ', 'fn'), @ischar);
            parse(ip, varargin{:});
            
            import mlfourd.*;
            pwd0 = pushd(this.sessionData.tracerLocation);
            tracerSafe = mybasename(this.ensureSafeFileprefix(ip.Results.tracerFn));
            if (lexist([tracerSafe '_mskt.4dfp.hdr'], 'file') && ...
                lexist([tracerSafe '_msktNorm.4dfp.hdr'], 'file'))
                mskt     = ImagingContext([tracerSafe '_mskt.4dfp.hdr']);
                msktNorm = ImagingContext([tracerSafe '_msktNorm.4dfp.hdr']);
                return
            end
            
            lns_4dfp(ip.Results.tracerFn, tracerSafe);            
            st4rb  = mlfourdfp.SimpleT4ResolveBuilder('sessionData', this.sessionData);
            st4rb.msktgenImg(tracerSafe); % no resolving done, just utility call
            mskt   = ImagingContext([tracerSafe '_mskt.4dfp.hdr']);
            msktNN = mskt.numericalNiftid;
            msktNN.img = msktNN.img/msktNN.dipmax;
            msktNN.fileprefix = [tracerSafe '_msktNorm'];
            msktNN.filesuffix = '.4dfp.hdr';
            msktNN.save;
            msktNorm = ImagingContext(msktNN);
            
            % teardown
            this.teardown;
            popd(pwd0);
        end
        function teardown(this, varargin)
            ip = inputParser;
            addParameter(ip, 'sessionData', this.sessionData, @(x) isa(x, 'mlpipeline.ISessionData'));
            parse(ip, varargin{:});  
            return
            
            sessd = ip.Results.sessionData;
            deleteExisting([sessd.tracerRevision('tag', '_sumt_g11', 'typ', 'fp') '*']);
            tmpdir = fullfile(tempdir, mydatetimestr(now));
            mkdir(tmpdir);
            movefileExisting(sprintf('aparcAseg*r%i_op_* ', sessd.rnumber-1), tmpdir);
            deleteExisting('aparcAsegr*');
            deleteExisting('aparcAsegBinarizedr*');
            movefileExisting(fullfile(tmpdir, '*'));
            rmdir(tmpdir);
        end        
        
 		function this = RoisBuilder(varargin)
 			%% ROISBUILDER
            %  @param named 'logger' is an mlpipeline.ILogger.
            %  @param named 'product' is the initial state of the product to build.
            %  @param named 'sessionData' is an mlpipeline.ISessionData.

 			this = this@mlfourdfp.AbstractSessionBuilder(varargin{:});
        end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

