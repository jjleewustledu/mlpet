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
        fqfn = '/scratch/jjlee/Singularity/subjects_00993/sub-S00001/resampling_restricted/hodt20190326112129.4dfp.hdr';
 		registry
        sessData
        sessFold = 'ses-E00054'
        subjFold = 'sub-S00001'
        suvrCon
 		testObj
        tracer = 'HO'
        viewer
        vnumber = 1
 	end

	methods (Test)
        function test_SuvrContext(this)
            disp(this.suvrCon)
            disp(this.testObj)
        end
        function test_averageProduct(this)
            this.testObj = this.testObj.buildCbf;    
            avgCbf = this.testObj.averageProduct(this.testObj.product);
            disp(avgCbf)
            disp(avgCbf.sessionData)
            disp(avgCbf.imagingContext)
            avgCbf.fsleyes
        end
        function test_mask(this)
           mask = this.testObj.constructMaskContext(); 
           mask.fsleyes
        end
        function test_buildAll(this)
            this.testObj = this.testObj.buildAll;
            this.testObj.product{5}.fsleyes
        end
        function test_buildCbf(this)
            this.testObj = this.testObj.buildCbf;
            this.testObj.product{1}.fsleyes;
        end
        function test_buildCbv(this)
            this.testObj = this.testObj.buildCbv;
            this.testObj.product{1}.fsleyes;
        end
        function test_buildY(this)
            this.testObj = this.testObj.buildY;
            this.testObj.product{1}.fsleyes;
        end
        function test_buildBetas(this)
            that = this.testObj;
            
            theCbf = that.averageProduct(that.buildCbf.product);
            theCbv = that.averageProduct(that.buildCbv.product);
            theY   = that.averageProduct(that.buildY.product);
            [that,mdl] = that.buildBetas(theCbf, theCbv, theY);
            cmro2 = that.product{1};
            cmro2.fsleyes
            oef = that.product{2};
            oef.fsleyes
            %msk = that.product{3};            
            %this.verifyEqual(mdl.Coefficients{1,'Estimate'}, 0.85312, 'RelTol', 0.01);
            %this.verifyEqual(mdl.Coefficients{2,'Estimate'}, 0.13157, 'RelTol', 0.01);
            plotResiduals(   mdl);
            plotDiagnostics( mdl, 'cookd');
            plotSlice(       mdl);
            %this.viewer.view(msk.imagingContext, cmro2.imagingContext, oef.imagingContext)
            %volAver = cmro2.volumeAveraged(msk);
            %this.verifyEqual(double(volAver.img), 0.8684285283, 'RelTol', 0.01)
            %volAver = oef.volumeAveraged(msk);
            %this.verifyEqual(double(volAver.img), 1.0403, 'RelTol', 0.01)
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
            studyData     = mlan.StudyData();
            projData      = mlan.ProjectData('sessionStr', this.sessFold);
            subjData      = mlan.SubjectData('subjectFolder', this.subjFold);
            this.sessData = mlan.SessionData( ...
                'studyData', studyData, ...
                'projectData', projData, ...
                'subjectData', subjData, ...
                'sessionFolder', this.sessFold, ...
                'tracer', this.tracer, ...
                'ac', true);
            this.suvrCon = mlpet.SuvrContext('sessionData', this.sessData, 'filename', this.fqfn);
 			this.testObj_ = mlan.TracerSuvrBuilder('sessionData', this.sessData);
            this.testObj_.rebuild = false;
            this.viewer = mlfourdfp.Viewer('fsleyes');
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

