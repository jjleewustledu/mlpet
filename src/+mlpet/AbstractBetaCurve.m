classdef AbstractBetaCurve < mlpet.AbstractWellData & mlpet.IBetaCurve
	%% ABSTRACTBETACURVE 
    %  Yet abstract:  static method load, method save

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$  	
    
	methods 
        function this = AbstractBetaCurve(fileLoc)
            %% ABSTRACTBETACURVE
            %  Usage:  this = this@mlpet.AbstractBetaCurve(file_location);
            %          this = this@mlpet.AbstractBetaCurve('/path/to/p1234data/p1234ho1.crv')
            %          this = this@mlpet.AbstractBetaCurve('/path/to/p1234data/p1234ho1')
            %          this = this@mlpet.AbstractBetaCurve('p1234ho1')
            
            this = this@mlpet.AbstractWellData(fileLoc);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

