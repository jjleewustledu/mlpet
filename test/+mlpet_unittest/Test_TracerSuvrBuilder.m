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
        hyglyNN = 'HYGLY30'
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
        function test_buildAll(this)
            p = this.testObj.buildAll;
            this.viewer.view(p)
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
                this.verifyEqual(p.fqfilename, this.testObj.tracerSuvr('typ','fqfn'));
                this.verifyTrue(lexist_4dfp(p.fqfileprefix));
            end
        end
        function test_buildBetas(this)
            [this.testObj,cmro2,oef,msk,mdl] = this.testObj.buildBetas;
            this.verifyEqual(mdl.Coefficients{1,'Estimate'}, 0.85312, 'RelTol', 0.01);
            this.verifyEqual(mdl.Coefficients{2,'Estimate'}, 0.13157, 'RelTol', 0.01);
            plotResiduals(   mdl);
            plotDiagnostics( mdl, 'cookd');
            plotSlice(       mdl);
            this.viewer.view(this.testObj.atlas, cmro2, oef)
            volAver = cmro2.volumeAveraged(msk);
            this.verifyEqual(double(volAver.img), 0.8684285283, 'RelTol', 0.01)
            volAver = oef.volumeAveraged(msk);
            this.verifyEqual(double(volAver.img), 1.0403, 'RelTol', 0.01)
        end
        function test_buildGlcMetab(this)
            [this.testObj,ogi] = this.testObj.buildGlcMetab;
            this.viewer.view(this.testObj.atlas, ogi)
        end
        function test_buildTracerSuvrAveraged(this)  
            for tr = 2:length(this.testObj.SUPPORTED_TRACERS)      
                tracers_ = {};
                for sc = 1:3
                    try
                        this.testObj.tracer = this.testObj.SUPPORTED_TRACERS{tr};
                        this.testObj.snumber = sc;
                        this.testObj = this.testObj.buildTracer;
                        tracers_ = [tracers_ {this.testObj.product}]; %#ok<AGROW> % accumulate scans of OC, OO, HO
                    catch ME
                        disp(ME);
                    end
                end  
                this.testObj = this.testObj.buildTracerSuvrAveraged(tracers_{:});
                p = this.testObj.tracerSuvrAveraged('typ','mlfourdfp.Fourdfp');
                this.viewer.view(this.testObj.atlas, p)        
                this.verifyEqual(this.testObj.volumeAverage(p), 1, 'RelTol', 0.01);
                this.verifyEqual(p.fqfileprefix, this.testObj.tracerSuvrAveraged('typ','fqfp'));
                this.verifyTrue(lexist_4dfp(p.fqfileprefix));
            end
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
            this.testObj_.rebuild = false;
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

