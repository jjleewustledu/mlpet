classdef PETNIfTId < mlfourd.NIfTId
	%% PETNIFTID enables polymorphism of NIfTId over PET data.

	%  $Revision$
 	%  was created 08-Dec-2015 15:11:44
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties
 		
 	end

    methods (Static) 
        function nii = load(fn, varargin)
            %% LOAD reads NIfTI objects from the file-system 
            %  Freesurfer's mri_convert provides imaging format support.  If no file-extension is included, LOAD will attempt guesses.
            %  Usage:  nifti = PETNIfTId.load(filename[, description])                   
            
            nii = mlpet.PETNIfTId(mlfourd.NIfTId.load(fn, varargin{:}));
        end
    end
    
	methods 
        function nii = clone(this)
            nii = mlpet.PETNIfTId(clone@mlfourd.NIfTId(this));
        end
        function nii = makeSimilar(this, varargin)
            nii = mlpet.PETNIfTId(makeSimilar@mlfourd.NIfTId(this, varargin{:}));
        end
		  
 		function this = PETNIfTId(varargin)
 			%% PETNIFTID
 			%  Usage:  this = PETNIfTId()

 			this = this@mlfourd.NIfTId(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

