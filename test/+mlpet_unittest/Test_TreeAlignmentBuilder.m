classdef Test_TreeAlignmentBuilder < matlab.unittest.TestCase
	%% TEST_TREEALIGNMENTBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_TreeAlignmentBuilder)
 	%          >> result  = run(mlpet_unittest.Test_TreeAlignmentBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 03-May-2018 23:09:21 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        census
 		registry
        sessd
        sessf = 'HYGLY28'
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_alignToAparcA2009sAseg(this)
        end
        function test_gatherSubjectImaging(this)
        end
        function test_gatherImaging(this)
        end
        function test_alignAllT1001OpStudyAtlas(this)
            this.testObj.alignAllT1001OpStudyAtlas;
            this.testObj.view;
        end
        function test_t4imgAllT1001OnStudyAtlas(this)
            this.testObj.t4imgAllT1001OnStudyAtlas;
            this.testObj.view;
        end
        function test_aT1001(this)
            disp(this.testObj.aT1001(1));
        end
        function test_allT1001(this)
            disp(this.testObj.allT1001);
        end
	end

 	methods (TestClassSetup)
		function setupTreeAlignmentBuilder(this)
            this.sessd = mlraichle.SessionData( ...
                'studyData', mlraichle.StudyData, 'sessionFolder', this.sessf, 'tracer', 'FDG'); % referenceTracer
            this.census = mlraichle.StudyCensus('sessionData', this.sessd);
 			import mlpet.*;
 			this.testObj_ = TreeAlignmentBuilder('census', this.census, 'sessionData', this.sessd);
 		end
	end

 	methods (TestMethodSetup)
		function setupTreeAlignmentBuilderTest(this)
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

