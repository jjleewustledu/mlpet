classdef PETImagingContext < mlfourd.ImagingContext
	%% PETIMAGINGCONTEXT

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
        function     add(this, varargin)
            %% ADD
            %  @param varargin are added to a composite imaging state
            
            this.state_ = this.state_.add(varargin{:});
        end
        function     addLog(this, varargin)
            %% ADDLOG
            %  @param varargin are log entries for the imaging state
            
            this.state_.addLog(varargin{:});
        end
        function a = atlas(this, varargin)
            %% ATLAS
            %  @param imaging_objects[, ...] have typeclasses supported by ImagingContext.  All alignment
            %  operations between imaging objects must have been completed.  Time-domains will be summed.
            %  @return a is the voxel-by-voxel weighted sum of this image and any submitted images; 
            %  each image is weighted by its median value.
            %  @throws MATLAB:dimagree, MATLAB:UndefinedFunction
            
            a = mlpet.PETImagingContext(this.state_.atlas(varargin{:}));
        end
        function b = binarized(this)
            %% BINARIZED
            %  @return internal image is binary: values are only 0 or 1.
            %  @warning mlfourd:possibleMaskingError
            
            b = mlpet.PETImagingContext(this.state_.binarized);
        end
        function b = blurred(this, varargin)
            %% BLURRED
            %  @param [fwhh_x fwhh_y fwhh_z] describes the anisotropic Gaussian blurring kernel
            %  applied to the internally stored image
            %  @return the blurred image
            
            b = mlpet.PETImagingContext(this.state_.blurred(varargin{:}));
        end 
        function f = char(this)
            f = this.state_.char;
        end
        function     close(this)
            this.state_.close;
        end
        function c = createIterator(this)
            %% CREATEITERATOR
            %  @return c is an iterator for a mlpatterns.Composite instance, if any
            
            c = this.state_.createIterator;
        end
        function c = csize(this)
            %% CSIZE
            %  @return c is the size of the imaging state when it is composite
            
            c = this.state_.csize;
        end
        function     disp(this)
            disp(this.state_);
        end
        function d = double(this)
            d = this.state_.double;
        end
        function f = find(this, varargin)
            %% FIND
            %  @param varargin are objects to find within a composite imaging state
            %  %return f is the position within the composite of the object
            
            f = this.state_.find(varargin{:});
        end
        function g = get(this, varargin)
            %% GET
            %  @param varargin are integer locations within a composite imaging state
            %  @return g is an element of the imaging state
            
            g = mlpet.PETImagingContext(this.state_.get(varargin{:}));
        end
        function tf = isempty(this)
            %% ISEMPTY
            %  @return tf is boolean for state emptiness
            
            tf = this.state_.isempty;
        end
        function l = length(this)
            %% LENGTH
            %  @return l is the length of a composite imaging state
            
            l = this.state_.length;
        end
        function m = masked(this, varargin)
            %% MASKED
            %  @param INIfTId of a mask with values [0 1], not required to be binary.
            %  @return internal image is masked.
            %  @warning mflourd:possibleMaskingError
            
            for v = 1:length(varargin)
                if (isa(varargin{v}, 'mlfourd.ImagingContext'))
                    varargin{v} = varargin{v}.numericalNiftid;
                end
            end
            m = mlpet.PETImagingContext(this.state_.masked(varargin{:}));
        end
        function m = maskedByZ(this, varargin)
            %% MASKEDBYZ
            %  @param rng = [low-z high-z], typically equivalent to [inferior superior];
            %  @return internal image is cropped by rng.  
            %  @throws MATLAB:assertion:failed for rng out of bounds.
            
            if (isempty(varargin))
                nniid = this.numericalNiftid;
                m = mlpet.PETImagingContext(this.state_.maskedByZ(this.zbounds(nniid.size)));
                return
            end
            m = mlpet.PETImagingContext(this.state_.maskedByZ(varargin{:}));
        end
        function o = ones(this, varargin)
            o = mlpet.PETImagingContext(this.state_.ones(varargin{:}));
        end
        function r = rank(this)
            r = this.state_.rank;
        end
        function     rm(this, varargin)
            %% RM
            %  @param varargin are integer locations which will be removed from the imaging state.
            
            this.state_ = this.state_.rm(varargin{:});
        end
        function     save(this)
            %% SAVE saves the imaging state as this.fqfilename on the filesystem.
            
            this.state_.save;
        end
        function     saveas(this, filename)
            %% SAVEAS saves the imaging state as this.fqfilename on the filesystem.
            %  @param filename is a string that is compatible with requirements of the filesystem;
            %  it replaces internal filename & filesystem information.

            this.state_ = this.state_.saveas(filename);
        end
        function tf = sizeEq(this, ic)
            %% SIZEEQ 
            %  @param ImagingContext to compare to this for size
            %  @returns tf logical for equal size

            tf = this.state_.sizeEq(ic);
        end
        function tf = sizeGt(this, ic)
            %% SIZEEQ 
            %  @param ImagingContext to compare to this for size
            %  @returns tf logical for > size

            tf = this.state_.sizeGt(ic);
        end
        function tf = sizeLt(this, ic)
            %% SIZEEQ 
            %  @param ImagingContext to compare to this for size
            %  @returns tf logical for < size

            tf = this.state_.sizeLt(ic);
        end
        function t = thresh(this, t)
            %% THRESH
            %  @param t:  use t to threshold current image (zero anything below the number)
            %  @returns t, the modified imaging context
            
            t = mlpet.PETImagingContext(this.state_.thresh(t));
        end
        function p = threshp(this, p)
            %% THRESHP
            %  @param p:  use percentage p (0-100) of ROBUST RANGE to threshold current image (zero anything below the number)
            %  @returns p, the modified imaging context
            
            p = mlpet.PETImagingContext(this.state_.threshp(p));
        end
        function t = timeSummed(this)
            %% TIMESUMMED integrates over imaging dimension 4. 
            %  @return dynamic image reduced to summed volume.
            
            t = mlpet.PETImagingContext(this.state_.timeSummed);
        end
        function u = uthresh(this, u)
            %% UTHRESH
            %  @param t:  use t to upper-threshold current image (zero anything above the number)
            %  @returns u, the modified imaging context
            
            u = mlpet.PETImagingContext(this.state_.uthresh(u));
        end
        function p = uthreshp(this, p)
            %% THRESHP
            %  @param p:  use percentage p (0-100) of ROBUST RANGE to threshold current image (zero anything below the number)
            %  @returns p, the modified imaging context
            
            p = mlpet.PETImagingContext(this.state_.uthreshp(p));
        end
        function v = volumeSummed(this)
            %% VOLUMESUMMED integrates over imaging dimensions 1:3. 
            %  @return dynamic image reduced to time series.
            
            v = mlpet.PETImagingContext(this.state_.volumeSummed);
        end
        function     view(this, varargin)
            %% VIEW
            %  @param are additional filenames and other arguments to pass to the viewer.
            %  @return new window with a view of the imaging state
            %  @throws mlfourd:IOError
            
            this.ensureAnyFormsSaved(varargin{:});
            this.state_.view(varargin{:});
        end
        function z = zeros(this, varargin)
            z = mlpet.PETImagingContext(this.state_.zeros(varargin{:}));
        end
        function z = zoomed(this, varargin)
            %% ZOOMED 
            %  @param vector of zoom multipliers; zoom(i) > 1 embeds this.img in a larger img.
            %  @return internal image is zoomed.
            
            for v = 1:length(varargin)
                if (isa(varargin{v}, 'mlfourd.ImagingContext'))
                    varargin{v} = varargin{v}.numericalNiftid;
                end
            end
            z = mlpet.PETImagingContext(this.state_.zoomed(varargin{:}));
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
        function c = clone(this)
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

