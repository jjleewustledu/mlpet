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
 		function this       = buildFlirted(this)
            this = this.buildVisitor.alignPET(this);
        end         
 		function this       = buildFlirtedSmallAngles(this)
            this = this.buildVisitor.alignSmallAnglesForPET(this);
        end 
 		function this       = buildFlirtedPET2MR(this)
            this = this.buildVisitor.alignMultispectral(this);
        end 
        function [this,xfm] = buildFlirtedPET2Transmission2MR(this)
            [this,xfm] = this.buildVisitor.alignPETUsingTransmission(this);
        end
 		function this       = buildFlirtedMR2PET(this)
            this = this.buildVisitor.alignPETUsingTransmission(this);
            this = this.buildVisitor.transformTrilinear(this);
        end  
        function this       = buildFlirtedWithXfm(this)
            this = this.buildVisitor.transformTrilinear(this);
        end
        function [this,xfm] = concatXfms(this, xfms)
            [this,xfm] = this.buildVisitor.concatTransforms(this, xfms);
        end
        function this       = filterOptimally(this)
            vtor = AveragingVisitor;
            for p = 1:length(this.petComposite)
                this.product = this.petComposite{p};
                this = vtor.visitFilterOptimally(this);
                this.petComposite{p} = this.product;
                
                % move to visitor
                this.petComposite{p} = mlfourd.BlurringNIfTI( ...
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

