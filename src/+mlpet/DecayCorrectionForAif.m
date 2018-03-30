classdef DecayCorrectionForAif < mlpet.DecayCorrection
	%% DECAYCORRECTIONFORAIF  

	%  $Revision$
 	%  was created 25-Jan-2018 21:08:02 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	methods         
 		function this = DecayCorrectionForAif(varargin)
 			%% DECAYCORRECTIONFORAIF
 			%  Usage:  this = DecayCorrectionForAif()

 			this = this@mlpet.DecayCorrection(varargin{:});
        end
    end
    
    %% PROTECTED
    
    methods (Access = protected)        
        function c = adjustClient(this, c, sgn, tzero)
            sgn   = sign(sgn);
            times = this.client_.times - tzero;
            c     = c.*exp(sgn*this.decayConstant*times);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

