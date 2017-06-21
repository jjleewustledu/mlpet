classdef AbstractO15Builder < mlpet.TracerBuilder
	%% ABSTRACTO15BUILDER  

	%  $Revision$
 	%  was created 30-May-2017 17:31:46 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	
    properties 
        constructKineticsPassed
 	end
    
    methods %% GET        
        function g = get.constructKineticsPassed(this)
            if (~isempty(this.constructKineticsPassed_))
                g = this.constructKineticsPassed_;
                return
            end
            g = this.checkConstructKineticsPassed;
        end
    end
    
	methods 
		  
 		function this = AbstractO15Builder(varargin)
 			%% ABSTRACTO15BUILDER
 			%  Usage:  this = AbstractO15Builder()

 			this = this@mlpet.TracerBuilder(varargin{:});
 		end
        function tf   = checkConstructKineticsPassed(this)
            error('mlpet:notImplemented', 'AbstractO15Builder.checkConstructKineticsPassed');
        end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        constructKineticsPassed_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

