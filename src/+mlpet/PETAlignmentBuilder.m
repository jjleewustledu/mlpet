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
            visit = mlfsl.FlirtVisitor;
            this  = visit.alignPET(this);
        end         
 		function this       = buildFlirtedSmallAngles(this)
            visit = mlfsl.FlirtVisitor;
            this  = visit.alignSmallAnglesForPET(this);
        end 
 		function this       = buildFlirtedPET2MR(this)
            visit = mlfsl.FlirtVisitor;
            this  = visit.align6DOF(this);
        end 
        function [this,xfm] = buildFlirtedPET2Transmission2MR(this)
            visit      = mlfsl.FlirtVisitor;
            [this,xfm] = visit.alignPETUsingTransmission(this);
        end
 		function this       = buildFlirtedMR2PET(this)
            visit = mlfsl.FlirtVisitor;
            this  = visit.alignPETUsingTransmission(this);
            this  = visit.applyTransformOfBuilder(this);
        end  
        function this       = buildFlirtedWithXfm(this)
            visit = mlfsl.FlirtVisitor;
            this  = visit.applyTransformOfBuilder(this);
        end
        function [this,xfm] = concatXfms(this, xfms)
            visit      = mlfsl.FlirtVisitor;
            [this,xfm] = visit.concatTransformsOfBuilder(this, xfms);
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

