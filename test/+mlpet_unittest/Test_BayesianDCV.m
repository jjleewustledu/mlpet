classdef Test_BayesianDCV < matlab.unittest.TestCase 
	%% TEST_BAYESIANDCV  

	%  Usage:  >> results = run(mlpet_unittest.Test_BayesianDCV)
 	%          >> result  = run(mlpet_unittest.Test_BayesianDCV, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 

	properties 
        dcvFilename = '/Volumes/InnominateHD2/Local/test/np755/mm06-005_p7766_2011jan14/ECAT_EXACT/pet/p7766ho1.dcv'
        dcv
 		testObj
        testFolder = '/Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest' 	
 	end 

	methods (Test) 
        function test_createEstimate(this)
            bdcv = mlpet.BayesianDCV.createEstimate(this.dcvFilename);
            %egf  = bdcv.gammaFluid;
            %save(fullfile(this.testFolder, 'Test_BayesianDCV.egf.mat'), 'egf');
            this.assertEqual(bdcv.gammaFluid.baseTitle,        this.expectedGammaFluid.baseTitle);            
            this.assertEqual(bdcv.gammaFluid.timeInterpolants, this.expectedGammaFluid.timeInterpolants);  
            this.assertEqual(bdcv.gammaFluid.dependentData,    this.expectedGammaFluid.dependentData);
            this.assertEqual(bdcv.bestFitParams,               this.expectedBestFitParams, 'RelTol', 0.05);
            this.assertEqual(bdcv.Q,                           this.expectedQ, 'RelTol', 0.05);
            this.assertEqual(bdcv.normalizedQ,                 this.expectedNormalizedQ, 'RelTol', 0.05);
        end
        function test_dcv(this)
            this.assertTrue(isa(this.testObj.dcv, 'mlpet.DCV'));
            this.assertEqual(this.testObj.dcv, this.dcv);
        end
 	end 

 	methods (TestClassSetup) 
 	end 

 	methods (TestClassTeardown) 
    end 

    methods
        function this = Test_BayesianDCV            
            this.dcv = mlpet.DCV.load(this.dcvFilename);
 			this.testObj = mlpet.BayesianDCV(this.dcv);             
            load(fullfile(this.testFolder, 'Test_BayesianDCV.egf.mat'));
            this.expectedGammaFluid = egf;
        end
    end
    
    %% PRIVATE
    
    properties (Access = 'private')
        expectedBestFitParams = ...
            [6.705462; 5.572888; 0.459081; 1.036406; 3667663.531791; 31.704192]
        expectedQ           = 1.55039e+09
        expectedNormalizedQ = 0.00167571069629573
        expectedGammaFluid
    end
    
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

