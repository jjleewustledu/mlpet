classdef PetRegistrationBuilder < mlfsl.RegistrationBuilderPrototype
	%% PETREGISTRATIONBUILDER  

	%  $Revision$
 	%  was created 27-Jan-2016 00:59:45
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	methods 
        function prod = motionCorrect(this, src)
            this.sourceImage = src;
            visitor = mlpet.PetFlirtVisitor(this.sessionData);
            this = visitor.motionCorrect(this);
            prod = this.product;
        end
        
 		function this = PetRegistrationBuilder(varargin)
 			%% PETREGISTRATIONBUILDER
 			%  @param sessData is an instance of mlpipeline.SessionData.
            
            this = this@mlfsl.RegistrationBuilderPrototype(varargin{:});
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

