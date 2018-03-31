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
        viewer
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
        function test_buildTimeContraction(this)
            tracers = {'FDG' 'OC' 'OO' 'HO'};
            for tr = 1:length(tracers)
                this.testObj.tracer = tracers{tr};
                [this.testObj,tw] = this.testObj.buildTimeContraction;
                plot(tw);
                xlabel('frame indices'); ylabel(sprintf('\\Sigma_{x} activity(%s(x)) in Bq', tracers{tr}));
                title('time-windowed volume contraction');
                this.viewer.view(this.testObj.product);
            end
        end
        function test_buildOnAtl(this)
            tracers = {'FDG' 'OC' 'OO' 'HO'};
            for tr = 1:length(tracers)
                this.testObj.tracer = tracers{tr};
                this.testObj = this.testObj.buildOnAtl; 
                this.viewer.view(this.testObj.atlas, this.testObj.product);
            end
        end
        function test_buildTracer(this)
            tracers = {'FDG' 'OC' 'OO' 'HO'};
            for tr = 1:length(tracers)
                this.testObj.tracer = tracers{tr};
                this.testObj = this.testObj.buildTracer;
                p = this.testObj.product;    
                this.viewer.view(this.testObj.atlas, p)        
                this.verifyEqual(this.testObj.volumeAverage(p), 1, 'RelTol', 0.01);
                this.verifyEqual(p.fqfilename, this.tracer.tracerSuvr('typ','fqfn'));
                this.verifyTrue(lexist_4dfp(p.fqfileprefix));
            end
        end
        function test_buildBetas(this)
            [this.testObj,cmro2,oef,msk] = this.testObj.buildBetas;
            this.verifyEqual(this.testObj.product.Coefficients{1,'Estimate'}, 0.85312, 'RelTol', 0.01);
            this.verifyEqual(this.testObj.product.Coefficients{2,'Estimate'}, 0.13157, 'RelTol', 0.01);
            plotResiduals(   this.testObj.product);
            plotDiagnostics( this.testObj.product, 'cookd');
            plotSlice(       this.testObj.product);
            this.viewer.view(this.testObj.atlas, cmro2, oef)
            volAver = cmro2.volumeAveraged(msk);
            this.verifyEqual(double(volAver.img), 0.8684285283, 'RelTol', 0.01)
            volAver = oef.volumeAveraged(msk);
            this.verifyEqual(double(volAver.img), 1.0403, 'RelTol', 0.01)
        end
        function test_buildGlcMetab(this)
            [this.testObj,ogi,agi] = this.testObj.buildGlcMetab;
            this.viewer.view(this.testObj.atlas, ogi, agi)
        end
        function test_view(this)
            names = {'fdg' 'oc' 'oo' 'ho' 'cmro2' 'oef' 'ogi' 'agi'};
            named = cellfun(@(x) this.testObj.tracerSuvrNamed(x, 'typ', '4dfp.img'), names, 'UniformOutput', false);
            this.viewer.view(named);
        end
	end

 	methods (TestClassSetup)
		function setupTracerSuvrBuilder(this)
 			import mlpet.*;
            studyd        = mlraichle.StudyData;
            sessp         = fullfile(studyd.subjectsDir, this.hyglyNN, '');
            this.sessd    = mlraichle.SessionData( ...
                'studyData', studyd, 'sessionPath', sessp, 'vnumber', this.vnumber, 'ac', true);
 			this.testObj_ = TracerSuvrBuilder('sessionData', this.sessd);
            this.viewer   = mlfourdfp.Viewer('freeview');
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

