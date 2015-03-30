classdef BayesianDCV  
	%% BAYESIANDCV characterizes a DCV object by a generalized gamma distribution  

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 
    properties (Dependent)
        dcv
        gammaFluid
        
        bestFitParams
        normalizedQ
        Q
    end

    methods %% GET
        function d = get.dcv(this)
            d = this.dcv_;
        end
        function g = get.gammaFluid(this)
            g = this.gammaFluid_;
        end
        function s = get.bestFitParams(this)
            s = this.gammaFluid.bestFitParams;
        end
        function s = get.normalizedQ(this)
            s = this.gammaFluid.normalizedQ;
        end
        function s = get.Q(this)
            s = this.gammaFluid.Q;
        end
    end

    methods (Static)
        function this = createEstimate(fname)
            %% CREATE
            %  Usage:  BayesianDCV_obj = BayesianDCV.createEstimate(dcv_filename);
            
            assert(lexist(fname, 'file'));
            this = mlpet.BayesianDCV( ...
                   mlpet.DCV(fname));
            this = this.estimateParameters;            
            this.plot
        end
    end
    
	methods 		  
 		function this = BayesianDCV(dcv) 
 			%% BAYESIANDCV 
 			%  Usage:  this = BayesianDCV(DCV_object) 
            
            assert(isa(dcv, 'mlpet.DCV'));
            this.dcv_ = dcv; 			 
        end 
        function this = estimateParameters(this)
            this.gammaFluid_ = mlbayesian.BestGammaFluid(this.dcv.timeInterpolants, this.dcv.countInterpolants);  
            this.gammaFluid_ = this.gammaFluid_.estimateDcvParameters;
        end
        function plot(this)
            figure;
            plot(this.gammaFluid.timeInterpolants, this.gammaFluid.estimateData, ...
                 this.dcv.times, this.dcv.counts, 'o');
            legend('Bayesian estimate', this.dcv.fileprefix);
            title(sprintf('BayesianDCV:  %s', this.dcv.filename));
            xlabel('time/s');
            ylabel('well-counts');
        end
    end 

    %% PRIVATE
    
	properties (Access = 'private')
        dcv_
        gammaFluid_
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

