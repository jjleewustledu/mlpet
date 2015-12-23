classdef PETImagingContext < mlfourd.ImagingContext
	%% PETIMAGINGCONTEXT  

	%  $Revision$
 	%  was created 08-Dec-2015 20:30:10
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties
 		
 	end

    methods (Static)
        function this = load(obj)
            %% LOAD
            %  Usage:  this = PETImagingContext.load(object)
            %                                        ^ fileprefix, filename, NIfTI, NIfTId, MGH, ImagingComponent
            
            this = mlpet.PETImagingContext(obj);
        end
    end
    
	methods 
        function this = timeSummed(this)
            niid = mlfourd.DynamicNIfTId(this.niftid);
            niid = niid.timeSummed;
            niid.save;
            this.niftid = niid.component;
        end
        function this = blurred(this, varargin)
            import mlpet.*;
            
            ip = inputParser;
            addOptional(ip, 'blur', PETRegistry.instance.petPointSpread, @isnumeric);
            parse(ip, varargin{:});
            
            niid = mlfourd.BlurringNIfTId(this.niftid);
            niid = niid.blurred(ip.Results.blur);
            niid.save;
            this.niftid = niid.component;
        end
        function c = clone(this)
            %% CLONE returns with state typeclass of mlfourd.ImagingLocation.
            %  Usage:  a_clone = this.clone;
            
            c = mlpet.PETImagingContext([]);
            c.state_ = mlfourd.ImagingLocation.load(this.fqfilename, c);
        end
		  
 		function this = PETImagingContext(varargin)
 			%% PETIMAGINGCONTEXT.  The copy-ctor returns with state typeclass of mlfourd.ImagingLocation.
            %  Usage:  this = PETImagingContext(object)
            %                                   ^ fileprefix, filename, NIfTI, NIfTId, MGH, ImagingComponent,
            %                                     ImagingContext

 			this = this@mlfourd.ImagingContext(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

