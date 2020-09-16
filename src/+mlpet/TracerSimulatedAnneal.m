classdef TracerSimulatedAnneal < mloptimization.SimulatedAnnealing
	%% TRACERSIMULATEDANNEAL  

	%  $Revision$
 	%  was created 10-Sep-2020 20:00:41 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1434023 (R2019b) Update 6 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        artery_interpolated
        ks0
        ks_lower
        ks_upper
        quiet = false
        visualize = false
        visualize_anneal = false 		
    end
    
	properties (Dependent)   
        ks
    end
    
    methods (Static)        
        function conc = slide_fast(conc, Dt)
            %% SLIDE_FAST slides discretized function conc(t) to conc(t - Dt);
            %  @param conc is row vector without NaN.
            %  @param t is row vector with same size as conc.
            %  @param Dt is scalar rounded to integer.
            %
            %  Dt > 0 will slide conc(t) towards later times t.
            %  Dt < 0 will slide conc(t) towards earlier times t.
            
            Dt = round(Dt);
            if Dt == 0
                return
            end
            if Dt < 0
                T = length(conc);
               conc_ = conc(end)*ones(1, length(conc));
               conc_(1:T+Dt) = conc(1-Dt:end);
               conc = conc_;
               return
            end
            conc_ = zeros(size(conc));
            conc_(1+Dt:end) = conc(1:end-Dt);
            conc = conc_;
        end
    end

	methods	
        
        %% GET
        
        function g = get.ks(this)
            g = this.results_.ks;
        end
        
        %%
        
 		function this = TracerSimulatedAnneal(varargin)
 			this = this@mloptimization.SimulatedAnnealing(varargin{:});
        end
 	end 
    
    %% PROTECTED
    
    methods (Access = protected)
        function [m,sd] = find_result(this, lbl)
            ks_ = this.ks;
            assert(strcmp(lbl(1), 'k'))
            ik = str2double(lbl(2));
            m = ks_(ik);
            sd = 0;
        end
        function [lb,ub,ks0] = remapper(this)
            for i = 1:this.map.Count
                lbl = sprintf('k%i', i);
                lb(i)  = this.map(lbl).min; %#ok<AGROW>
                ub(i)  = this.map(lbl).max; %#ok<AGROW>
                ks0(i) = this.map(lbl).init; %#ok<AGROW>
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

