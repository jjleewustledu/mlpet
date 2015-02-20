classdef DecayCorrectedCRV < mlpet.CRV & mlpet.IDecayCorrection 
	%% DECAYCORRECTEDCRV objectifies Snyder-Videen *.crv files with positron decay-correction.  
    %  Correction is also made to beta-detector events to yield well-counter units.
    %  Cf. man metproc 

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 
    
	properties (Dependent)        
        isotope
        halfLife
        pie
        wellFqfilename
        wellFactor
    end 
    
    methods %% GET
        function i = get.isotope(this)
            i = this.decayCorrection_.isotope;
        end
        function h = get.halfLife(this)
            h = this.decayCorrection_.halfLife;
        end
        function p = get.pie(this)
            p = this.decayCorrection_.pie;
        end
        function f = get.wellFqfilename(this)
            f = fullfile(this.filepath, [str2pnum(this.fileprefix) '.wel']);
        end
        function w = get.wellFactor(this)
            w = this.decayCorrection_.wellFactor;
        end
    end    
    
    methods (Static)
        function this = load(fileLoc)
            import mlpet.*;
            this = DecayCorrectedCRV(CRV(fileLoc));
        end
    end
    
	methods
  		function this = DecayCorrectedCRV(crv) 
 			%% DECAYCORRECTEDCRV guesses the isotope from the fileprefix of the passed CRV object.
 			%  Usage:  this = DecayCorrectedCRV(CRV_object) 
          
            this = this@mlpet.CRV(crv.fqfilename);
            assert( isa(crv, 'mlpet.CRV'));
            assert(~isa(crv, 'mlpet.DecayCorrectedCRV'));
            
            this.decayCorrection_ = mlpet.DecayCorrection(this);
            this.counts = this.decayCorrection_.correctedCounts(this.counts, this.times);
        end 
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        decayCorrection_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

