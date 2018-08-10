classdef OoContext < mlpet.TracerContext 
	%% OOCONTEXT  

	%  $Revision$
 	%  was created 28-May-2018 21:52:11 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	methods
        
        %% 
        
        function ic = oo(this, varargin)
            ic = mlfourd.ImagingContext( ...
                fullfile(this.sessionContext_.vallLocation, ...
                         sprintf('oo%iv%ir1_op_oov%ir1_on_op_fdgv%ir1.4dfp.hdr', ...
                         this.snumber, this.sessionContext_.vnumber, this.sessionContext_.vnumberRef, this.sessionContext_.vnumberRef)));
        end
		  
 		function this = OoContext(varargin)
 			%% OOCONTEXT
 			%  @param named sessionContext.

            this = this@mlpet.TracerContext(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

