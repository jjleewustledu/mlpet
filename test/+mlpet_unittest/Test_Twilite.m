classdef Test_Twilite < matlab.unittest.TestCase
	%% TEST_TWILITE 

	%  Usage:  >> results = run(mlpet_unittest.Test_Twilite)
 	%          >> result  = run(mlpet_unittest.Test_Twilite, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 23-Jan-2017 19:39:09
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		registry
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_crossCalibrate(this)
        end
        function test_specificActivity(this)
        end
        function test_times(this)
        end
        function test_timeMidpoints(this)
        end
        function test_taus(this)
        end
        function test_datetime(this)
        end
        function test_doseAdminDatetime(this)
        end
        function test_timeInterpolants(this)
        end
        function test_timeMidpointInterpolants(this)
        end
        function test_shiftTimes(this)
        end
        function test_shiftWorldlines(this)
        end
	end

 	methods (TestClassSetup)
		function setupTwilite(this)
 			import mlpet.*;
 			this.testObj_ = Twilite;
 		end
	end

 	methods (TestMethodSetup)
		function setupTwiliteTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

