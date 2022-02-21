classdef Test_StudyResolveBuilder < matlab.unittest.TestCase
	%% TEST_STUDYRESOLVEBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_StudyResolveBuilder)
 	%          >> result  = run(mlpet_unittest.Test_StudyResolveBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 22-Jan-2020 21:38:13 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.7.0.1261785 (R2019b) Update 3 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        projData
        sesData
        sesFolder = 'ses-E03056' % NP995_25 on 20190523, hypergly
        sesFolder2 = 'ses-E00853' % NP995_25 on 20190110, basal
        sesFolder3 = 'ses-E248568' % HYGLY50 on 20180511, hypergly 
        subData
        subjectFolder = 'sub-S58163' % NP995_25, HYGLY50
        studyData
        
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
        function test_construct_resolved_session(this)
            construct_resolved('subjects/sub-S58163/ses-E03056')
            construct_resolved('subjects/sub-S58163/ses-E00853')
            construct_resolved('subjects/sub-S58163/ses-E248568')
        end
        function test_construct_resolved_subject(this)
            construct_resolved('subjects/sub-S58163')
        end
	end

 	methods (TestClassSetup)
		function setupStudyResolveBuilder(this)
            import mlraichle.*
            setenv('PROJECTS_DIR', '/scratch/jjlee/Singularity');
            setenv('SUBJECTS_DIR', '/scratch/jjlee/Singularity/subjects');
            this.studyData = StudyData();
            this.projData = ProjectData('sessionStr', 'ses-E03056');
            this.subData = SubjectData('subjectFolder', this.subjectFolder);
            this.sesData = SessionData( ...
                'studyData', this.studyData, ...
                'projectData', this.projData, ...
                'subjectData', this.subData, ...
                'sessionFolder', this.sesFolder, ...
                'tracer', 'FDG', 'ac', true); % referenceTracer
 			this.testObj_ = mlpet.SessionResolveBuilder('sessionData', this.sesData);
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

 	methods (TestMethodSetup)
		function setupStudyResolveBuilderTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

