classdef (Abstract) TracerKinetics < handle
	%% TRACERKINETICS  

	%  $Revision$
 	%  was created 10-Sep-2020 17:07:33 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/src/+mlpet.
 	%% It was developed on Matlab 9.7.0.1434023 (R2019b) Update 6 for MACI64.  Copyright 2020 John Joowon Lee.
 	 	
    properties (Constant)
        BLOOD_DENSITY = 1.06         % https://hypertextbook.com/facts/2004/MichaelShmukler.shtml; human whole blood 37 C
        BRAIN_DENSITY = 1.05         % Torack et al., 1976, g/mL        
        PLASMA_DENSITY = 1.03
        DENSITY_BLOOD = 1.06
        DENSITY_BRAIN = 1.05
        DENSITY_PLASMA = 1.03
        LAMBDA = 0.95                % brain-blood equilibrium partition coefficient, mL/mL, Herscovitch, Raichle, JCBFM (1985) 5:65
        RATIO_SMALL_LARGE_HCT = 0.85 % Grubb, et al., 1978
        RBC_FACTOR = 0.766           % per Tom Videen, metproc.inc, line 193  
    end
    
    methods (Static)
        function cbf = invsToCbf(f)
            % 1/s -> mL/min/hg
            cbf = 6000*f/mlpet.TracerKinetics.DENSITY_BRAIN;
        end
        function f = cbfToInvs(cbf)
            % mL/min/hg -> 1/s
            f = cbf*mlpet.TracerKinetics.DENSITY_BRAIN/6000;
        end
        function mLmL = lambdaToUnitless(mLg)
            % mL/g -> mL/mL            
            mLmL = mLg*mlpet.TracerKinetics.DENSITY_BRAIN;
        end
        function mLg = unitlessToLambda(mLmL)
            % mL/mL -> mL/g
            mLg = mLmL/mlpet.TracerKinetics.DENSITY_BRAIN;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

