classdef Test_Msktgen < matlab.unittest.TestCase
	%% TEST_MSKTGEN 

	%  Usage:  >> results = run(mlpet_unittest.Test_Msktgen)
 	%          >> result  = run(mlpet_unittest.Test_Msktgen, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 14-Apr-2018 20:06:44 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        ac = false
 		registry
        sessf = 'HYGLY28'
        sessd
 		testObj
        tracer = 'HO'
        v = 2
        viewer
 	end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_constructMsktFromTimeContracted(this)
        end
        function test_constructMsktIsBinary(this)
        end
        function test_constructMskt_T1001(this)
            pwd0 = pushd(this.sessd.vLocation);
            mskt = this.testObj.constructMskt( ...
                'source', this.sessd.T1001, ...
                'intermediaryForMask', this.sessd.T1001, ...
                'sourceOfMask', 'brainmask.4dfp.hdr', ...
                'blurForMask', 0, 'threshp', 0, ...
                'doConstructResolved', false);
            mskt.filename = 'test_constructMskt_T1001.4dfp.hdr';
            this.viewer.view({this.sessd.T1001 'brainmask' mskt});   
            popd(pwd0);
        end
        function test_constructMskt(this)
            pwd0 = pushd(this.sessd.tracerLocation);
            mskt = this.testObj.constructMskt( ...
                'source', this.sessd.tracerRevision, ...
                'intermediaryForMask', this.sessd.T1001, ...
                'sourceOfMask', '../brainmask.4dfp.hdr', ...
                'blurForMask', 22, 'threshp', 0, ...
                'doConstructResolved', true);
            mskt.filename = 'test_constructMskt_HO.4dfp.hdr';
            this.viewer.view({this.sessd.tracerRevision mskt});   
            popd(pwd0);
        end
        function test_constructMskt_NR2(this)
            pwd0 = pushd(this.sessd.tracerLocation);
            mskt = this.testObj.constructMskt( ...
                'source', this.sessd.tracerRevision, ...
                'intermediaryForMask', this.sessd.T1001, ...
                'sourceOfMask', '../brainmask.4dfp.hdr', ...
                'blurForMask', 5.5, 'threshp', 20, ...
                'doConstructResolved', true, ...
                'NRevisions', 2);
            mskt.filename = 'test_constructMskt_NR2.4dfp.hdr';
            this.viewer.view({this.sessd.tracerRevision mskt});   
            popd(pwd0);
        end
        function test_constructMskt_variations(this)
        end
	end

 	methods (TestClassSetup)
		function setupMsktgen(this)
 			import mlpet.*;
            this.viewer = mlfourdfp.Viewer;
            this.sessd = mlraichle.SessionData( ...
                'studyData', mlraichle.StudyData, ...
                'sessionFolder', this.sessf, ...
                'vnumber', this.v, ...
                'tracer', this.tracer, 'ac', this.ac);
 			this.testObj_ = Msktgen('sessionData', this.sessd);
 		end
	end

 	methods (TestMethodSetup)
		function setupMsktgenTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(~)
            deleteExisting('test_constructMskt*.4dfp.*');
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

