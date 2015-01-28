classdef PETAlignmentBuilder < mlfsl.AlignmentBuilderPrototype
	%% PETALIGNMENTBUILDER 
    %  See also:  mlpatterns.BuilderImpl

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.1.0.604 (R2013a) 
 	%  $Id$  	 

	methods 
        function this       = buildUnpacked(this)
            vtor = mlunpacking.UnpackingVisitor;
            this = vtor.visitPETAlignmentBuilder(this);
        end
 		function this       = buildFlirted(this)
            vtor = mlfsl.FlirtVisitor;
            this = vtor.visitPETAlignmentBuilder(this);
        end         
 		function this       = buildFlirtedSmallAngles(this)
            vtor = mlfsl.FlirtVisitor;
            this = vtor.visitPETAlignmentBuilderSmallAngles(this);
        end 
 		function this       = buildFlirtedPET2MR(this)
            vtor = mlfsl.FlirtVisitor;
            this = vtor.visitAlignmentBuilder(this);
        end 
        function [this,xfm] = buildFlirtedPET2Transmission2MR(this)
            vtor       = mlfsl.FlirtVisitor;
            [this,xfm] = vtor.visitAlignmentBuilderUsingTransmission(this);
        end
 		function this       = buildFlirtedMR2PET(this)
            vtor = mlfsl.FlirtVisitor;
            this = vtor.visitAlignmentBuilder2invertXfm(this);
            this = vtor.visitAlignmentBuilder2applyXfm(this);
        end  
        function this       = buildFlirtedWithXfm(this)
            vtor = mlfsl.FlirtVisitor;
            this = vtor.visitAlignmentBuilder2applyXfm(this);
        end
        function [this,xfm] = concatXfms(this, xfms)
            vtor       = mlfsl.FlirtVisitor;
            [this,xfm] = vtor.visitAlignmentBuilder2concatXfms(this, xfms);
        end
        function this       = filterOptimally(this)
            vtor = AveragingVisitor;
            for p = 1:length(this.petComposite)
                this.product = this.petComposite{p};
                this = vtor.visitFilterOptimally(this);
                this.petComposite{p} = this.product;
                
                % move to visitor
                this.petComposite{p} = mlfourd.BlurredNIfTI( ...
                    this.petComposite{p});
                this.petComposite{p} = this.petComposite{p}.blurred;                
            end
        end        
        function obj        = clone(this)
            obj = mlpet.PETAlignmentBuilder(this);
        end
        
 		function this = PETAlignmentBuilder(varargin) 
 			%% PETALIGNMENTBUILDER 
 			%  Usage:  this = PETAlignmentBuilder([aPETAlignmentBuilder]|['parameter', value]) 
            %  See also:  AlignmentBuilderPrototype

 			this = this@mlfsl.AlignmentBuilderPrototype(varargin{:}); 
        end
    end 
        
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

