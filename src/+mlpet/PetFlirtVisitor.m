classdef PETFlirtVisitor < mlfsl.FlirtVisitor
	%% PETFLIRTVISITOR 
    %  overwrites intermediate files used by flirt operations but will not overwrite data from 
    %  AbstractRegistrationBuilder:  sourceImage, referenceImage, sourceWeight, referenceWeight.

	%  $Revision$
 	%  was created 27-Jan-2016 23:28:30
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		
 	end

	methods 		  
        function bldr = motionCorrect(this, bldr)
            this.ensureBuilderSaved(bldr);
            [proxysrc,proxyts] = this.ensureMotionCorrectProxies(bldr);
            
            mOpts         = mlfsl.McflirtOptions;
            mOpts.cost    = 'normcorr'; % 'normmi'
            mOpts.dof     = 6;
            mOpts.in      = proxysrc;
            mOpts.reffile = proxyts;
            proxymc       = this.mcflirt__(mOpts); % saves proxymc
            
            aOpts.input          = bldr.sourceImage;
            aOpts.ref            = proxyts;
            aOpts.output         = this.mcf_fqfn(bldr.sourceImage);
            aOpts.transformation = this.mat_fqdn(proxymc);
            bldr.xfm             = aOpts.transformation;
            bldr.product         = this.applyxfm4D__(aOpts); % saves bldr.product
            bldr.product.addLog('mlpet.PETFlirtVisitor.motionCorrect');
            bldr.product.addLog(bldr.sourceImage.getLog.contents);
        end
        function [bldr,xfm] = registerBijective(this, bldr, proxyBldr)
            this.ensureBuilderSaved(bldr);
            this.ensureBuilderSaved(proxyBldr);
            
            opts              = mlfsl.FlirtOptions;
            opts.in           = proxyBldr.sourceImage;
            opts.ref          = proxyBldr.referenceImage;
            opts.cost         = 'normmi';
            opts.dof          = 6;  
            opts.searchrx     = ' -30 30 ';
            opts.searchry     = ' -30 30 ';
            opts.searchrz     = ' -30 30 ';
            %opts.coarsesearch = ' 20 ';
            %opts.finesearch   = ' 10 ';
            opts.inweight     = proxyBldr.sourceWeight;
            opts.refweight    = proxyBldr.referenceWeight;           
            opts.init         = this.flirt__(opts);
            
            opts.in           = bldr.sourceImage;
            opts.ref          = bldr.referenceImage;
            opts.inweight     = bldr.sourceWeight;
            opts.refweight    = bldr.referenceWeight; 
            bldr.product      = this.transform__(opts);
            bldr.product.addLog('mlpet.PETFlirtVisitor.registerBijective');
            bldr.product.addLog(bldr.sourceImage.getLog.contents);
            bldr.xfm          = opts.init;
            xfm               = opts.init;
        end
        
 		function this = PETFlirtVisitor(varargin)
 			this = this@mlfsl.FlirtVisitor(varargin{:});
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)
        function cleanWorkspace(this, ic)
            if (isa(ic, 'mlfourd.ImagingContext'))
                deleteExisting(ic.fqfilename);
                dt = mlsystem.DirTool([this.mat_fqdn(ic) '*']);
                for d = 1:length(dt.fqdns)
                    rmdir(dt.fqdns{d}, 's');
                end
                return
            end
            if (ischar(ic))
                deleteExisting3([ic '*'])
                return
            end
            error('mlfsl:unsupportedTypeclass', ...
                  'typeclass of PETFlirtVisitor.cleanWorkspace.ic was %s; \nchar(ic)->%s', class(ic), char(ic));
        end
        function [proxysrc,proxyts] = ensureMotionCorrectProxies(this, bldr)            
            proxysrc = bldr.sourceImage.clone;            
            proxysrc = proxysrc.blurred(bldr.blurringFactor*bldr.pointSpread);
            if (~isa(bldr.sessionData, 'mlraichle.SessionData')) %% KLUDGE
                proxysrc = proxysrc.maskedByZ;
            end
            this.cleanWorkspace(proxysrc);
            this.cleanWorkspace(this.mcf_mat_fqdn(proxysrc));
            proxysrc.save;
            
            proxyts = bldr.ensureTimeIndep(proxysrc); 
            this.cleanWorkspace(proxyts);
            proxyts.save;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

