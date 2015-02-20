classdef DecayCorrectedEcat < mlpet.EcatExactHRPlus & mlpet.IDecayCorrection  
	%% DECAYCORRECTEDECAT   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
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
        function this = load(fileLoc, pie)
            import mlpet.*;
            this = DecayCorrectedEcat(EcatExactHRPlus(fileLoc), pie);
        end
    end

	methods 		  
 		function this = DecayCorrectedEcat(ecat, pie) 
 			%% DECAYCORRECTEDECAT 
 			%  Usage:  this = DecayCorrectedEcat(EcatExactHRPlus_object, pie_factor) 

 			this = this@mlpet.EcatExactHRPlus(ecat.fqfilename); 
            assert( isa(ecat, 'mlpet.EcatExactHRPlus'));
            assert(~isa(ecat, 'mlpet.DecayCorrectedEcat'));
            assert( isnumeric(pie));
            
            this.decayCorrection_ = mlpet.DecayCorrection(this, pie);
            this.counts = this.decayCorrection_.correctedCounts(this.counts, this.times);
            this = this.updateFileprefix;
 		end 
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        decayCorrection_
    end
    
    methods (Access = 'private')
        function this = updateFileprefix(this)            
            this.nifti_.fileprefix = [this.nifti_.fileprefix '_decayCorrect'];
            if (this.useBequerels)                
                this.nifti_.fileprefix = [this.nifti_.fileprefix '_Bq'];
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

