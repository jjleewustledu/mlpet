classdef Test_GlucoseMetabolismBuilder < matlab.unittest.TestCase
	%% TEST_GLUCOSEMETABOLISMBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_GlucoseMetabolismBuilder)
 	%          >> result  = run(mlpet_unittest.Test_GlucoseMetabolismBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 03-Feb-2016 21:47:53
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

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
	end

 	methods (TestClassSetup)
		function setupGlucoseMetabolismBuilder(this)
 			import mlpet.*;
 			this.testObj_ = GlucoseMetabolismBuilder;
 		end
	end

 	methods (TestMethodSetup)
		function setupGlucoseMetabolismBuilderTest(this)
 			this.testObj = this.testObj_;
 		end
	end

	properties (Access = 'private')
 		testObj_
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

