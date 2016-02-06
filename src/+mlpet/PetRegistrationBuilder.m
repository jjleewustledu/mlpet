classdef PETRegistrationBuilder < mlfsl.AbstractRegistrationBuilder
	%% PETREGISTRATIONBUILDER  

	%  $Revision$
 	%  was created 27-Jan-2016 00:59:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	
   
	properties (Dependent) 		
        sourceWeight
        referenceWeight
        sourceImage
        referenceImage
        product
    end

    methods %% GET/SET
        function this = set.sourceWeight(this, w)
            this.sourceWeight_ = mlpet.PETImagingContext(w);
        end
        function w    = get.sourceWeight(this)
            % may be empty
            w = this.sourceWeight_;
        end
        function this = set.referenceWeight(this, w)
            this.referenceWeight_ = mlpet.PETImagingContext(w);
        end
        function w    = get.referenceWeight(this)
            % may be empty
            w = this.referenceWeight_;
        end
        function this = set.referenceImage(this, ref)
            this.referenceImage_ = mlpet.PETImagingContext(ref);
        end
        function ref  = get.referenceImage(this)
            ref = this.referenceImage_;
        end
        function this = set.sourceImage(this, src)
            this.sourceImage_ = mlpet.PETImagingContext(src);
        end
        function src  = get.sourceImage(this)
            src = this.sourceImage_;
        end
        function this = set.product(this, s)
            this.product_ = mlpet.PETImagingContext(s);
        end
        function prod = get.product(this)
            prod = this.product_;
            %prod.setNoclobber(false);
        end
    end
    
	methods 
        function this = motionCorrect(this)
            visitor = mlpet.PETFlirtVisitor;
            this = visitor.motionCorrect(this);
        end
        function this = registerBijective(this)
            visitor = mlpet.PETFlirtVisitor;
            this = visitor.registerBijective(this, this.proxyBuilder);
            this.cleanUpProxy(this.proxyBuilder);
        end
        
        %% CTOR
        
 		function this = PETRegistrationBuilder(varargin)
            this = this@mlfsl.AbstractRegistrationBuilder(varargin{:});
        end
        function obj  = clone(this)
            obj = mlpet.PETRegistrationBuilder(this);
        end
    end
    
    %% PROTECTED
    
    methods (Access = protected)
        function ic = serializeBlurred(this, ic)
            import mlfourd.*;
            ic = ic.blurred(this.petPointSpread);
            deleteExisting(ic.fqfilename);
            ic.save;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

