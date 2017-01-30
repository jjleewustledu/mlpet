classdef Test_Herscovitch1985 < matlab.unittest.TestCase
	%% TEST_HERSCOVITCH1985 

	%  Usage:  >> results = run(mlpet_unittest.Test_Herscovitch1985)
 	%          >> result  = run(mlpet_unittest.Test_Herscovitch1985, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 28-Jan-2017 12:53:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        % from '/Volumes/SeagateBP4/cvl/np755/mm01-007_p7267_2008jun16/bayesian_pet'
        % whole-brain CBF = 56.417 mL/100g/min on vidi, 40% uthresh
        %                 = 0.00987298 1/s        
        %              af = 2.035279E-06 from metcalc
        %              bf = 2.096733E-02 
        % estimated    A0 = 0.290615
        
        dcvShiftHO  = -18
        ecatShiftHO = -6
        dcvShiftOO  = nan
        ecatShiftOO = nan
        sessionData
 		testObj
 	end

	methods (Test)
        function test_ctor(this)
            this.verifyClass(this.testObj, 'mlpet.Herscovitch1985');
        end
        function test_plotHO(this)
            obj = this.configTracer(this.testObj, 'HO');
            obj.plotAif;
            obj.plotWholebrain(obj.flows);
        end
        function test_plotOO(this)  
            obj = this.configTracer(this.testObj, 'OO');   
            obj.plotAif;
            obj.plotWholebrain(obj.flows);
        end
        
        function test_buildHOobs(this)
            obj = this.configTracer(this.testObj, 'HO');
            obj = obj.buildPetobs('flows', obj.flows);
            this.verifyEqual(obj.product, nan(1,10));
        end
        function test_buildOOobs(this)
            obj = this.configTracer(this.testObj, 'OO');
            obj = obj.buildPetobs('flows', obj.flows);
            this.verifyEqual(obj.product, nan(1,10));
        end
        
        function test_buildA1A2(this)
            obj = this.configTracer(this.testObj, 'HO');
            obj = obj.buildPetobs;
            obj = obj.buildA1A2;
            this.verifyEqual(obj.a1, 2.035279E-06, 'RelTol', 0.01);
            this.verifyEqual(obj.a2, 2.096733E-02, 'RelTol', 0.01);
        end
        function test_buildA3A4(this)
            obj = this.configTracer(this.testObj, 'OO');
            obj = obj.buildPetobs;
            obj = obj.buildA3A4;
            this.verifyEqual(obj.a3, nan, 'RelTol', 0.01);
            this.verifyEqual(obj.a4, nan, 'RelTol', 0.01);
        end
        
        function test_cbfWholebrain(this)
            obj = this.testObj.buildCbfWholebrain;
            obj.product.view;
        end
        function test_cbvWholebrain(this)
            obj = this.testObj.buildCbvWholebrain;
            obj.product.view;
        end
        function test_oefWholebrain(this)
            obj = this.testObj.buildOefWholebrain;
            obj.product.view;
        end
        
        function test_cbfMap(this)
            obj = this.testObj.buildCbfMap;
            obj.product.view;
        end
        function test_cbvMap(this)
            obj = this.testObj.buildCbvMap;
            obj.product.view;
        end
        function test_oefMap(this)
            obj = this.testObj.buildOefMap;
            obj.product.view;
        end
	end

 	methods (TestClassSetup)
		function setupHerscovitch1985(this)
 			import mlpet.* mlderdeyn.*;
            studyd = StudyDataSingleton.instance;
            sessp = fullfile(studyd.subjectsDir, 'mm01-007_p7267_2008jun16', '');
            this.sessionData = SessionData('studyData', studyd, 'sessionPath', sessp, 'tracer', '');
 			this.testObj_ = Herscovitch1985('sessionData', this.sessionData);
 		end
	end

 	methods (TestMethodSetup)
		function setupHerscovitch1985Test(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
        function obj = configTracer(this, obj, tr)
            switch (tr)
                case 'HO'
                    obj.tracer = 'HO';
                    obj.rhoAShift = this.dcvShiftHO;
                    obj.rhoObsShift = this.ecatShiftHO;
                case 'OO'
                    obj.tracer = 'OO';
                    obj.rhoAShift = this.dcvShiftOO;
                    obj.rhoObsShift = this.ecatShiftOO;
                case 'OC'
                    obj.tracer = 'OC';
                otherwise
                    error('mlpet:unsupportedSwitchCase', 'Test_Herscovitch1985.configTracer');
            end
        end
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

