classdef DecayCorrectionForScanner < mlpet.DecayCorrection
	%% DECAYCORRECTIONFORSCANNER  

	%  $Revision$
 	%  was created 25-Jan-2018 21:08:10 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	methods		
 		function this = DecayCorrectionForScanner(varargin)
 			%% DECAYCORRECTIONFORSCANNER
 			%  Usage:  this = DecayCorrectionForScanner()

 			this = this@mlpet.DecayCorrection(varargin{:});
        end
    end
    
    %% PROTECTED
    
    methods (Access = protected)        
        function c = adjustClient(this, c, sgn, tzero)
            sgn   = sign(sgn);
            times = this.client_.times - tzero;
            switch (length(size(c)))
                case 2
                    c = c.*exp(sgn*this.decayConstant*times);
                case 3
                    for t = 1:size(c,3)
                        c(:,:,t) = c(:,:,t).*exp(sgn*this.decayConstant*times(t));
                    end
                case 4
                    for t = 1:size(c,4)
                        c(:,:,:,t) = c(:,:,:,t).*exp(sgn*this.decayConstant*times(t));
                    end
                otherwise
                    error('mlpet:unsupportedArraySize', ...
                          'size(DecayCorrection.adjustClient.cnts) -> %s', mat2str(size(c)));
            end 
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

