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
         drawnMin   % as col vector
         drawnSec   % as col vector
         countedMin % as col vector
         countedSec % as col vector
         counts     % as col vector
         nSyringes
         variableCountTime % as col vector
         
         pNumber
         scanDate
         scanIndex
         scanType
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

