classdef (Abstract) IBloodData  
	%% IBLOODDATA   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
 	 

	properties (Abstract)	 
         dryWeight  % as col vector
         wetWeight  % as col vector
         drawn      % datetime
         drawnMin   % as col vector
         drawnSec   % as col vector
         counted    % datetime
         countedMin % as col vector
         countedSec % as col vector
         counts     % as col vector
         nSyringes  % quantity of syringes used
         variableCountTime % as col vector
    end 
    
    methods (Abstract)        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

