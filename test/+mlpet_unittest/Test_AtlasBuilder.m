classdef Test_AtlasBuilder < matlab.unittest.TestCase
	%% TEST_ATLASBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_AtlasBuilder)
 	%          >> result  = run(mlpet_unittest.Test_AtlasBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 29-Mar-2018 00:02:54 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        fv
        hyglyNN = 'HYGLY28'
 		registry
        sessd
 		testObj
        viewer
        vnumber = 1
 	end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_tracer_to_atl_t4(this)
            this.verifyEqual(this.testObj.tracer_to_atl_t4, ...
                fullfile(this.sessd.vLocation, sprintf('fdgv%ir1_to_TRIO_Y_NDC_t4', this.vnumber)));
            tracer = this.sessd.tracerResolvedFinalSumt;
            this.assertTrue(lexist(tracer, 'file'));
            fqfp = this.fv.t4img_4dfp( ...
                this.testObj.tracer_to_atl_t4, ...
                myfileprefix(tracer), ...
                'out', sprintf('~/Tmp/test_%s', datestr(now, 30)), ...
                'options', ['-O' this.sessd.atlas('typ','fqfp')]);
            mlbash(sprintf('freeview %s.4dfp.img %s.4dfp.img', ...
                fqfp, this.sessd.atlas.fqfileprefix))
            delete_4dfp(fqfp);
        end  
        function test_mprForReconall(this)
            pwd0 = pushd(this.sessd.vLocation);
            this.viewer.view(this.testObj.mprForReconall('typ','fn'), 't1_mprage_sag_series122.4dfp.hdr')
            popd(pwd0);
        end
	end

 	methods (TestClassSetup)
		function setupTracerSuvrBuilder(this)
 			import mlpet.*;
            studyd        = mlraichle.StudyData;
            sessp         = fullfile(studyd.subjectsDir, this.hyglyNN, '');
            this.sessd    = mlraichle.SessionData('studyData', studyd, 'sessionPath', sessp, 'vnumber', this.vnumber, 'ac', true);
 			this.testObj_ = AtlasBuilder('sessionData', this.sessd);
            this.fv       = mlfourdfp.FourdfpVisitor;
            this.viewer   = mlfourdfp.Viewer('freeview');
 		end
	end

 	methods (TestMethodSetup)
		function setupAtlasBuilderTest(this)
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

