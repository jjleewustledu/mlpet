classdef Test_DCVRecovery < matlab.unittest.TestCase
	%% TEST_DCVRECOVERY 

	%  Usage:  >> results = run(mlpet_unittest.Test_DCVRecovery)
 	%          >> result  = run(mlpet_unittest.Test_DCVRecovery, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 11-Feb-2016 23:08:24
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		registry
 		testObj
    end
    
    properties (Dependent)
        AMAtest_fqfn
    end
    
    methods %% GET
        function g = get.AMAtest_fqfn(this)
            g = fullfile(getenv('ARBELAEZ'), 'deconvolution', 'data 2014jul17', 'AMAtest4.crv');
        end
    end

	methods (Test)
        function test_responseByCatheterSavitskyGolay(this)
            import mlarbelaez.* mlpet.*;         
            dccrv = DecayCorrectedCRV(CRV(this.AMAtest_fqfn));
            [R,csg] = this.testObj.responseByCatheterSavitzkyGolay(dccrv);
            
        end
		function test_responseByCatheterResponse(this)
 			import mlpet.*;
            dccrv = DecayCorrectedCRV(CRV(this.AMAtest_fqfn));
            [~,cr] = this.testObj.responseByCatheterResponse(dccrv);
            this.verifyEqual(cr.bestFitParams, cr.paramsManager.mean, 'RelTol', 0.1);
 		end
	end

 	methods (TestClassSetup)
		function setupDCVRecovery(this)
 			import mlpet.*;
 			this.testObj_ = DCVRecovery;
 		end
	end

 	methods (TestMethodSetup)
		function setupDCVRecoveryTest(this)
            warning('off', 'mfiles:regexpNotFound');
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
            warning('on', 'mfiles:regexpNotFound');
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

