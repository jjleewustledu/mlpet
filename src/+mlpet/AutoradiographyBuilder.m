classdef (Abstract) AutoradiographyBuilder < mlbayesian.AbstractMcmcProblem   
	%% AUTORADIOGRAPHYBUILDER is the abstract interface for Autoradiography builders
    %  such as PETAutoradiography, DSCAutoradiography.  Empty methods may be
    %  overridden as needed.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
    
    properties (Constant)
        LAMBDA = 0.95           % brain-blood equilibrium partition coefficient, mL/g
        LAMBDA_DECAY = 0.005677 % KLUDGE:  hard-coded [15O] half-life because propagating this.decayCorrection_ to static methods is difficult
        BRAIN_DENSITY = 1.05    % assumed mean brain density, g/mL
        HERSCOVITCH_CORRECTION = false
    end

    properties (Abstract)
        aif
        mask
        ecat
        concentration_a
        concentration_obs
        map 
    end
    
    methods (Static)
        function this = load(varargin)  %#ok<VANUS>
            this = [];
        end
        function this = loadAif(varargin)  %#ok<VANUS>
            this = [];
        end
        function mask = loadMask(varargin)
            p = inputParser;
            addOptional(p, 'fqfn',    [], @(x) lexist(x, 'file'));
            addOptional(p, 'iniftid', [], @(x) isa(x, 'mlfourd.INIfTId'));
            parse(p, varargin{:});
            
            if (~isempty(p.Results.fqfn))
                mask = mlfourd.MaskingNIfTId.load(p.Results.fqfn);
                return
            end
            if (~isempty(p.Results.iniftid))
                mask = p.Results.iniftid;
                return
            end
            error('mlpet:requiredObjectNotFound', 'AutoradiographyBuilder.loadMask');
        end      
        function ecat = loadEcat(pie, varargin)
            p = inputParser;
            addRequired(p, 'pie',       @isnumeric);
            addOptional(p, 'fqfn', [],  @(x) lexist(x, 'file'));
            addOptional(p, 'ecat', [],  @(x) isa(x, 'mlpet.EcatExactHRPlus'));
            parse(p, pie, varargin{:});
            
            if (~isempty(p.Results.fqfn))
                ecat = mlpet.EcatExactHRPlus.load(p.Results.pie, p.Results.fqfn);
                return
            end
            if (~isempty(p.Results.ecat))
                ecat = p.Results.ecat;
                return
            end
            error('mlpet:requiredObjectNotFound', 'AutoradiographyBuilder.loadEcat');
        end
        function this = simulateMcmc
            this = [];
        end
        function this = runAutoradiography
            this = [];
        end
        function ci   = concentration_i
            ci = [];
        end
        function args = interpolateData
            args = {};
        end
        function f    = mLsg_to_mLmin100g(f)
            f = 100 * 60 * f;
        end
    end
    
	methods         
        function this = simulateItsMcmc(this) %#ok<MANU>
            this = [];
        end
		function ci   = itsConcentration_i(this) %#ok<MANU>
            ci = [];
        end
        function this = estimateParameters(this)
        end
        function ed   = estimateData(this) %#ok<MANU>
            ed = [];
        end
        function ed   = estimateDataFast(this) %#ok<MANU>
            ed = [];
        end
        function x    = priorLow(~, x)
        end
        function x    = priorHigh(~, x)
        end
        function        plotInitialData(~)
        end
        function        plotProduct(this) %#ok<MANU>
        end
        function        plotParVars(this) %#ok<MANU>
        end
        function this = estimatePriors(this)
        end
        
 		function this = AutoradiographyBuilder(varargin) 
 			%% AUTORADIOGRAPHYBUILDER  
 			%  Usage:  this = AutoradiographyBuilder(times, concentration_i) 
            %                                        ^ s    ^ counts/s/g

 			this = this@mlbayesian.AbstractMcmcProblem(varargin{:}); 			 
 		end 
 	end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        aif_
        mask_
        ecat_
        concentration_a_
    end

    methods (Static, Access = 'protected')
        function [times,counts] = shiftDataLeft(times0, counts0, Dt)
            idx_0  = floor(sum(double(times0 < Dt + times0(1))));
            times  = times0(idx_0:end);
            times  = times - times(1);
            counts = counts0(idx_0:end);
            counts = counts - min(counts);
        end
        function [times,counts] = shiftDataRight(times0, counts0, Dt)
            lenDt  = ceil(Dt/(times0(2) - times0(1)));
            newLen = length(counts0) + lenDt;
            
            times0 = times0 - times0(1) + Dt;
            times  = [0:1:lenDt-1 times0];
            counts = counts0(1) * ones(1,newLen);            
            counts(end-length(counts0)+1:end) = counts0;
            counts = counts - min(counts);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

