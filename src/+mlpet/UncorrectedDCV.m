classdef UncorrectedDCV < mlpet.DCV  
	%% UNCORRECTEDDCV   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 

    properties
        timeLimit = 120
    end
    
    methods (Static)
        function this = load(fileLoc)
            this = mlpet.UncorrectedDCV(fileLoc);
        end
    end
    
	methods
 		function this = UncorrectedDCV(fileLoc) 
 			%% UNCORRECTEDDCV 
 			%  Usage:  this = UncorrectedDCV() 
            
 			this = this@mlpet.DCV(fileLoc); 
            decayCorr = mlpet.DecayCorrection.factoryFor(this);
            this.counts_ = decayCorr.uncorrectedActivities(this.counts_);
 		end 
        function t    = timeInterpolants(this, varargin)
            assert(~isempty(this.times_));
            tlim = min(this.timeLimit, this.times_(end));
            t = this.times_(1):this.dt:tlim;
            
            if (~isempty(varargin))
                t = t(varargin{:}); end
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

