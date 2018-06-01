classdef (Abstract) TracerContext 
	%% TRACERCONTEXT  

	%  $Revision$
 	%  was created 28-May-2018 21:45:45 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Dependent)
        radMeasurements
        sessionContext
 		snumber
    end

	methods 
        
        %% GET/SET        
        
        function g    = get.radMeasurements(this)
            g = this.radMeasurements_;
        end
        function g    = get.sessionContext(this)
            g = this.sessionContext_;
        end
        function g    = get.snumber(this)
            g = this.snumber_;
        end
        
        %%        
		  
 		function this = TracerContext(varargin)
 			%% TRACERCONTEXT
 			%  @param named sessionContext.
 			
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionContext', [], @(x) isa(x, 'mlpipeline.ISessionContext'));
            addParameter(ip, 'snumber', 1, @isnumeric);
            parse(ip, varargin{:});            
            this.sessionContext_ = ip.Results.sessionContext;
            this.snumber_ = ip.Results.snumber;
            
            this.radMeasurements_ = mlsiemens.RadMeasurements('sessionContext', this.sessionContext_);
 		end
    end 
    
    %% PROTECTED
    
    properties (Access = protected)
        radMeasurements_
        sessionContext_
        snumber_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

