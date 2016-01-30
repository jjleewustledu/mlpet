classdef PetFlirtVisitor < mlfsl.FlirtVisitor
	%% PETFLIRTVISITOR  

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
            proxy  = bldr.sourceImage.clone;
            proxyb = proxy.blurred(2*this.pointSpread);
            proxyb = proxyb.maskedByZ(this.zbounds(proxyb));
            this.cleanWorkspace(proxyb);
            proxyb.save;
            
            mOpts         = mlfsl.McflirtOptions;
            mOpts.cost    = 'normmi'; % 'normcorr'
            mOpts.dof     = 6;
            mOpts.in      = proxyb.fqfileprefix;
            proxyts       = this.proxyTimeSummed(proxyb); % saves proxyts
            mOpts.reffile = proxyts.fqfileprefix;
            this.cleanWorkspace(this.mcf_mat_fqdn(proxyb));
            proxymc       = this.mcflirt__(mOpts); % saves proxymc
            
            aOpts.input          = bldr.sourceImage.fqfn;
            aOpts.ref            = proxyts.fqfilename;
            aOpts.output         = this.mcf_fqfn(bldr.sourceImage);
            aOpts.transformation = this.mat_fqdn(proxymc);
            bldr.product         = this.applyxfm4D__(aOpts); % saves bldr.product
        end
        function p = pointSpread(~)
            reg = mlpet.PETRegistry.instance;
            p   = reg.petPointSpread;
        end
        
 		function this = PetFlirtVisitor(varargin)
 			this = this@mlfsl.FlirtVisitor(varargin{:});
 		end
    end 
    
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
                deleteExisting2([ic '*'])
                return
            end
            error('mlfsl:unsupportedTypeclass', ...
                  'typeclass of PetFlirtVisitor.cleanWorkspace.ic was %s; \nchar(ic)->%s', class(ic), char(ic));
        end
        function fqdn = mat_fqdn(this, ic)
            assert(isa(ic, 'mlfourd.ImagingContext'));
            fqdn = [ic.fqfileprefix this.XFM_SUFFIX]; 
        end
        function fqfn = mcf_fqfn(this, ic)
            assert(isa(ic, 'mlfourd.ImagingContext'));
            fqfn = [ic.fqfileprefix this.MCF_SUFFIX ic.filesuffix];
        end
        function fqdn = mcf_mat_fqdn(this, ic)
            assert(isa(ic, 'mlfourd.ImagingContext'));            
            fqdn = [ic.fqfileprefix this.MCF_SUFFIX this.XFM_SUFFIX]; 
        end
        function ic_sumt = proxyTimeSummed(this, ic)
            import mlfourd.*;
            fqfn = [ic.fqfileprefix DynamicNIfTId.SUMT_SUFFIX DynamicNIfTId.FILETYPE_EXT];
            if (lexist(fqfn, 'file'))
                ic_sumt = ImagingContext(fqfn);
                return
            end
            ic_sumt = ic.clone;
            ic_sumt = ic_sumt.timeSummed;            
            this.cleanWorkspace(ic_sumt);
            ic_sumt.save;
        end
        function z = zbounds(~, ic)
            szz = size(ic.niftid, 3);
            z   = [ceil(0.05*szz) floor(0.95*szz)];
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

