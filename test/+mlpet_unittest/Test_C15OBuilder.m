classdef Test_C15OBuilder < matlab.unittest.TestCase
	%% TEST_C15OBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_C15OBuilder)
 	%          >> result  = run(mlpet_unittest.Test_C15OBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 16-Oct-2015 14:52:57
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

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
 		function setupC15OBuilder(this)
 			import mlpet.*;
 			this.testObj = C15OBuilder;
 		end
 	end

 	methods (TestClassTeardown)
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

