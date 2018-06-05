classdef PETImagingContext < mlfourd.ImagingContext
	%% PETIMAGINGCONTEXT provides additional typeclassing for mlfourd.ImagingContext.

	%  $Revision$
 	%  was created 08-Dec-2015 20:30:10
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
        
    methods (Static)
        function this = load(obj)
            %% LOAD:  cf. ctor
            
            this = mlpet.PETImagingContext(obj);
        end
    end
    
	methods
        function a    = atlas(this, varargin)
            a = mlpet.PETImagingContext(atlas@mlfourd.ImagingContext(this, varargin{:}));
        end
        function b    = binarized(this)
            b = mlpet.PETImagingContext(binarized@mlfourd.ImagingContext(this));
        end
        function b    = binarizeBlended(this, varargin)
            b = mlpet.PETImagingContext(binarizeBlended@mlfourd.ImagingContext(this, varargin{:}));
        end
        function b    = blurred(this, varargin)
            b = mlpet.PETImagingContext(blurred@mlfourd.ImagingContext(this, varargin{:}));
        end 
        function f    = false(this, varargin)
            f = mlpet.PETImagingContext(false@mlfourd.ImagingContext(this, varargin{:}));
        end
        function g    = get(this, varargin)
            g = mlpet.PETImagingContext(get@mlfourd.ImagingContext(this, varargin{:}));
        end
        function m    = maskBlended(this, varargin)
            m = mlpet.PETImagingContext(maskBlended@mlfourd.ImagingContext(this, varargin{:}));
        end
        function m    = masked(this, varargin)
            m = mlpet.PETImagingContext(masked@mlfourd.ImagingContext(this, varargin{:}));
        end
        function m    = maskedByZ(this, varargin)
            m = mlpet.PETImagingContext(maskedByZ@mlfourd.ImagingContext(this, varargin{:}));
        end
        function n    = nan(this, varargin)
            n = mlpet.PETImagingContext(nan@mlfourd.ImagingContext(this, varargin{:}));
        end
        function n    = not(this, varargin)
           n = mlpet.PETImagingContext(not@mlfourd.ImagingContext(this, varargin{:}));
        end
        function o    = ones(this, varargin)
           o = mlpet.PETImagingContext(ones@mlfourd.ImagingContext(this, varargin{:}));
        end
        function t    = thresh(this, t)
            t = mlpet.PETImagingContext(thresh@mlfourd.ImagingContext(this, t));
        end
        function p    = threshp(this, p)
            p = mlpet.PETImagingContext(threshp@mlfourd.ImagingContext(this, p));
        end
        function t    = timeContracted(this)
            t = mlpet.PETImagingContext(timeContracted@mlfourd.ImagingContext(this));
        end
        function t    = timeSummed(this)
            t = mlpet.PETImagingContext(timeSummed@mlfourd.ImagingContext(this));
        end
        function f    = true(this, varargin)
            f = mlpet.PETImagingContext(true@mlfourd.ImagingContext(this, varargin{:}));
        end
        function u    = uthresh(this, u)
            u = mlpet.PETImagingContext(uthresh@mlfourd.ImagingContext(this, u));
        end
        function p    = uthreshp(this, p)
            p = mlpet.PETImagingContext(uthreshp@mlfourd.ImagingContext(this, p));
        end
        function v    = volumeContracted(this)
            v = mlpet.PETImagingContext(volumeContracted@mlfourd.ImagingContext(this));
        end
        function v    = volumeSummed(this)
            v = mlpet.PETImagingContext(volumeSummed@mlfourd.ImagingContext(this));
        end
        function z    = zeros(this, varargin)
            z = mlpet.PETImagingContext(zeros@mlfourd.ImagingContext(this, varargin{:}));
        end
        function z    = zoomed(this, varargin)
            z = mlpet.PETImagingContext(zoomed@mlfourd.ImagingContext(this, varargin{:}));
        end
		  
        %% CTOR
        
 		function this = PETImagingContext(varargin)
            %% PETIMAGINGCONTEXT 
            %  @param obj is imaging data:  filename, INIfTI, MGH, ImagingComponent, double, [], ImagingContext or 
            %  PETImagingContext for copy-ctor.  
            %  @return initializes context for a state design pattern.  
            %  @throws mlfourd:switchCaseError, mlfourd:unsupportedTypeclass.

            this = this@mlfourd.ImagingContext(varargin{:});
 		end
        function c    = clone(this)
            %% CLONE simplifies calling the copy constructor.
            %  @return deep copy on new handle
            
            c = mlpet.PETImagingContext(this);
        end
    end 
    
    %% PRIVATE
    
    methods (Static, Access = private)        
        function z = zbounds(size)
            z   = [ceil(0.05*size(3)) floor(0.95*size(3))];
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

