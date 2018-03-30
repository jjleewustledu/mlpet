classdef Test_TracerSurferBuilder < matlab.unittest.TestCase
	%% TEST_TRACERSURFERBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_TracerSurferBuilder)
 	%          >> result  = run(mlpet_unittest.Test_TracerSurferBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 02-Nov-2017 20:20:18 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
        hygly = 'HYGLY28'
        pwd0 
 		registry
        sessd
        sessp
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_reconAll(this)
            mrip = fullfile(this.sessionData.sessionPath, 'mri');
            backup = fullfile(this.sessionData.sessionPath, 'mri-backup');
            if (isdir(mrip))
                mlbash(sprintf('mv %s %s', mrip, backup));
            end
            mlraichle.HyperglycemiaDirector.reconAll( ...
                'sessionsExpr', [this.hygly '*'], 'visitsExpr', 'V1*');
        end
	end

 	methods (TestClassSetup)
		function setupTracerSurferBuilder(this)
 			import mlpet.*;
            this.sessp = fullfile(getenv('PPG'), 'jjlee2', this.hygly, '');
            this.sessd = mlraichle.SessionData('studyData', mlraichle.StudyData, 'sessionPath', this.sessp);
 			this.testObj_ = TracerSurferBuilder('sessionData', this.sessd);     
            this.pwd0 = pushd(this.sessp);
            this.addTeardown(@this.popd);
 		end
	end

 	methods (TestMethodSetup)
		function setupTracerSurferBuilderTest(this)
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
        function popd(this)
            popd(this.pwd0);
        end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

