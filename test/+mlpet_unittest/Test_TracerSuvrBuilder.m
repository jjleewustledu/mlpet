classdef Test_TracerSuvrBuilder < matlab.unittest.TestCase
	%% TEST_TRACERSUVRBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_TracerSuvrBuilder)
 	%          >> result  = run(mlpet_unittest.Test_TracerSuvrBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 28-Mar-2018 22:00:53 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        hyglyNN = 'HYGLY28'
 		registry
        sessd
 		testObj
        vnumber = 2
 	end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_buildAll(this)
        end
        function test_buildSuvr(this)
            % this.sessd.tracer == 'FDG'
            this.testObj_.buildSuvr
            ic = mlfourd.ImagingContext(this.sessd.);
        end
        function test_buildOef(this)
        end
        function test_buildCmro2(this)
        end
	end

 	methods (TestClassSetup)
		function setupTracerSuvrBuilder(this)
 			import mlpet.*;
            studyd        = mlraichle.StudyData;
            sessp         = fullfile(studyd.subjectsDir, this.hyglyNN, '');
            this.sessd    = mlraichle.SessionData('studyData', studyd, 'sessionPath', sessp, 'vnumber', this.vnumber);
 			this.testObj_ = TracerSuvrBuilder('sessionData', this.sessd);
 		end
	end

 	methods (TestMethodSetup)
		function setupTracerSuvrBuilderTest(this)
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

