classdef DecayCorrectedEcat < mlpet.EcatExactHRPlus & mlpet.IDecayCorrection  
	%% DECAYCORRECTEDECAT implements mlpet.IScannerData for data from detection array of Ecat Exact HR+ scanners, then
    %  applies decay correction for the half-life of the selected isotope.  Most useful properties will be
    %  times, timeInterpolants, counts, countInterpolants.  It is also a NIfTIdecorator.

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
    end 
    
    methods %% GET
        function i = get.isotope(this)
            i = this.decayCorrection_.isotope;
        end
        function h = get.halfLife(this)
            h = this.decayCorrection_.halfLife;
        end
    end    
    
    methods (Static)
        function this = load(fileLoc)
            this = mlpet.DecayCorrectedEcat(mlfourd.NIfTId.load(fileLoc));
        end
    end

	methods 		  
 		function this = DecayCorrectedEcat(cmp) 
 			%% DECAYCORRECTEDECAT 
 			%  Usage:  this = DecayCorrectedEcat(INIfTId_object) 

 			this = this@mlpet.EcatExactHRPlus(cmp); 
            assert( isa(cmp, 'mlfourd.INIfTId'));
            assert(~isa(cmp, 'mlpet.DecayCorrectedEcat'));
            
            this.decayCorrection_ = mlpet.DecayCorrection(this);
            this.counts = this.decayCorrection_.correctedCounts(this.counts, this.times);
            this = this.updateFileprefix;
            this = this.setTimeMidpoints_dc;
        end 
    end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        decayCorrection_
    end
    
    methods (Access = 'protected')
        function this = updateFileprefix(this)            
            this.component_.fileprefix = [this.component_.fileprefix '_decayCorrect'];
            if (this.useBecquerels)                
                this.component_.fileprefix = [this.component_.fileprefix '_Bq'];
            end
        end
        function this = setTimeMidpoints_dc(this)
            k_decay = log(2) / this.halfLife;
            this.timeMidpoints_ = this.times;
            for t = 2:this.length
                this.timeMidpoints_(t) = this.times(t-1) - (1/k_decay) * log(0.5*(exp(-k_decay*this.taus(t)) + 1));
            end            
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

