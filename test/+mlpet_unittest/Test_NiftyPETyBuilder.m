classdef Test_NiftyPETyBuilder < matlab.unittest.TestCase
	%% TEST_NIFTYPETYBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_NiftyPETyBuilder)
 	%          >> result  = run(mlpet_unittest.Test_NiftyPETyBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 17-Nov-2017 18:34:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		registry
 		testObj
 	end

	methods (Test)
		function test_constructFrame(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
 		end
	end

 	methods (TestClassSetup)
		function setupNiftyPETyBuilder(this)
 			import mlpet.*;
 			this.testObj_ = NiftyPETyBuilder;
 		end
	end

 	methods (TestMethodSetup)
		function setupNiftyPETyBuilderTest(this)
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

