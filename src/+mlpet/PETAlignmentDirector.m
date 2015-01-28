classdef PETAlignmentDirector < mlfsl.AlignmentDirectorDecorator
	%% PETALIGNMENTDIRECTOR   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.1.0.604 (R2013a) 
 	%  $Id$ 
    
    methods (Static)
        function pad = factory(varargin)
            %% FACTORY returns a PETAlignmentDirector with an AlignmentDirector with a PETAlignmentBuilder
            %  Usage:   pad = PETAlignmentDirector.factory([varargin for PETAlignmentBuilder])
            
            import mlpet.* mlfsl.*;
            pad = PETAlignmentDirector( ...
                  AlignmentDirector( ...
                  PETAlignmentBuilder(varargin{:})));
        end
        function pad = blurringFactory(varargin)
            %% FACTORY returns a PETAlignmentDirector with an AlignmentDirector with a PETAlignmentBuilder
            %  Usage:   pad = PETAlignmentDirector.factory([varargin for PETAlignmentBuilder])
            
            import mlpet.* mlfsl.*;
            varargin1 = PETAlignmentDirector.ensureProduct(varargin);
            pad = PETAlignmentDirector( ...
                  AlignmentDirector( ...
                  PETAlignmentBuilder(varargin1{:})));
        end
    end
    
	methods
        function bldr      = filterPETOptimally(~, bldr)
            prods = imcast(bldr.product, 'mlfourd.ImagingComponent');
            for p = 1:length(prods)
                assert(isa(prods{p}, 'mlfourd.NIfTI'));
                if (~lstrfind(prods{p}.fileprefix, 'fwhh'))
                    tmp = mlfourd.BlurredNIfTI(prods{p});
                    tmp = tmp.blurredNIfTI;
                    tmp.save;
                    prods{p} = tmp;
                end
            end
            bldr.product = prods;
        end
        function prd       = alignPET2MR(this, prd, mrRef)
            petBldr                = this.alignmentBuilder.clone;
            petBldr.product        = prd;
            petBldr.referenceImage = mrRef;
            petBldr                = petBldr.buildFlirtedPET2MR;
            prd                    = petBldr.product;
        end
        function [prd,xfm] = alignPET2Transmission2MR(this, prd, mrRef)
            petBldr                = this.alignmentBuilder.clone;
            petBldr.product        = prd;
            petBldr.referenceImage = mrRef;
            [petBldr,xfm]          = petBldr.buildFlirtedPET2Transmission2MR;
            prd                    = petBldr.product;
        end
        function prd       = alignMR2PET(this, prd, petRef)
            mrBldr                = this.alignmentBuilder.clone;
            mrBldr.product        = prd;
            mrBldr.referenceImage = petRef;
            mrBldr.xfm            = fullfile(prd.filepath, ...
                                    [petRef.fileprefix '_on_' prd.fileprefix mlfsl.FlirtVisitor.XFM_SUFFIX]);
            mrBldr                = mrBldr.buildFlirtedMR2PET;
            prd                   = mrBldr.product;
        end
        function bldr      = alignPETSequentially(this, bldr)
            prods                = imcast(bldr.product, 'mlfourd.ImagingComponent');
            prods{length(prods)} = this.alignPET2MR(prods{length(prods)}, bldr.referenceImage);
            bldr.product         = this.alignSequentially(prods); % ImagingComposite -> ImagingComposite -> ImagingContext
        end  
        function bldr      = alignPETUsingTransmission(this, bldr)
            prods      = this.alignSequentiallySmallAngles(bldr.product); % ImagingComposite -> ImagingComposite -> ImagingContext
            prods      = imcast(prods, 'mlfourd.ImagingComponent');
            len        = length(prods);
            [prod,xfm] = this.alignPET2Transmission2MR(prods{len}, bldr.referenceImage);
            prods{len} = prod;
            for p = 1:len-1
                prods{p} = this.alignPETWithXfm(prods{p}, bldr.referenceImage, xfm);
            end
            bldr.product = prods;
        end
        function prd       = alignPETWithXfm(this, prd, mrRef, xfm) 
            petBldr                = this.alignmentBuilder.clone;
            petBldr.product        = prd;
            petBldr.referenceImage = mrRef;
            petBldr.xfm            = xfm;
            petBldr                = petBldr.buildFlirtedWithXfm;
            prd                    = petBldr.product;
        end
        function ic        = applyXfm(this, ic)
            bldr         = this.alignmentBuilder.clone;
            bldr.product = ic;
            vtor         = mlfsl.FlirtVisitor;
            bldr         = vtor.visitAlignmentBuilder2applyXfm(bldr);
            ic           = bldr.product;
        end
        
 		function this = PETAlignmentDirector(varargin) 
 			%% PETALIGNMENTDIRECTOR 
 			%  Usage:  this = PETAlignmentDirector(anAlignmentDirectorComponent) 

            this = this@mlfsl.AlignmentDirectorDecorator(varargin{:});
            assert(isa(this.alignmentBuilder, 'mlpet.PETAlignmentBuilder'));
 		end 
    end 
    
    %% PROTECTED
    
    methods (Static, Access = 'protected')
        function args = ensureProduct(args)
            if (~lstrfind(args, 'product'))
                args = [{'product' mlpet.PETAlignmentDirector.petProduct}, args];
            end
        end
        function prd  = petProduct
            import mlfourd.*;
            pwdstr = pwd;
            lenstr = length(pwdstr);
            assert(strcmp(pwdstr(lenstr-2:lenstr), 'fsl'), 'ensure current directory is session_path/fsl');
            prd = [];
            try
                prd = ImagingComponent.load('tr_default.nii.gz');
                prd = prd.add(NIfTI.load('ho_meanvol_default.nii.gz'));
                prd = prd.add(NIfTI.load('oo_meanvol_default.nii.gz'));
            catch ME
                handexcept(ME);
            end
            try 
                prd = prd.add('oc_default.nii.gz');
            catch ME2
                handwarning(ME2);
            end
            prd = imcast(prd, 'mlfourd.ImagingContext');
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

