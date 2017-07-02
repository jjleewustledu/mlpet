classdef Test_Herscovitch1985Bayes < matlab.unittest.TestCase
	%% TEST_HERSCOVITCH1985BAYES 

	%  Usage:  >> results = run(mlpet_unittest.Test_Herscovitch1985Bayes)
 	%          >> result  = run(mlpet_unittest.Test_Herscovitch1985Bayes, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 27-Jun-2017 13:16:58 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		registry
 		testObj
 	end

	methods (Test)
		function test_ctor(this)
 		end
		function test_aifs(this)
 			import mlpet.*;
 		end
		function test_buildA1A2(this)
 			import mlpet.*;
 		end
		function test_buildB1B2(this)
 			import mlpet.*;
 		end
		function test_buildB3B4(this)
 			import mlpet.*;
 		end
	end

 	methods (TestClassSetup)
		function setupHerscovitch1985Bayes(this)
 			import mlpet.*;
 			this.testObj_ = Herscovitch1985Bayes;
 		end
	end

 	methods (TestMethodSetup)
		function setupHerscovitch1985BayesTest(this)
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

