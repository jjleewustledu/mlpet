classdef Test_Rois < matlab.unittest.TestCase
	%% TEST_ROIS 

	%  Usage:  >> results = run(mlpet_unittest.Test_Rois)
 	%          >> result  = run(mlpet_unittest.Test_Rois, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 08-Apr-2020 19:17:35 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.7.0.1319299 (R2019b) Update 5 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		registry
        sesd
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_constructBrainSet(this)
            [set,ifc] = this.testObj.constructBrainSet();
            this.verifyEqual(set{1}.fourdfp.img, ifc.img)
        end
        function test_constructDesikanSet(this)
            [set,ifc] = this.testObj.constructDesikanSet();
            img = set{1}.fourdfp.img;
            for s = 2:length(set)
                img = img + set{s}.fourdfp.img;
            end
            this.verifyEqual(dipsum(img > 0), dipsum(ifc.img > 0))
        end
        function test_constructDestrieuxSet(this)
            [set,ifc] = this.testObj.constructDestrieuxSet();
            img = set{1}.fourdfp.img;
            for s = 2:length(set)
                img = img + set{s}.fourdfp.img;
            end
            this.verifyEqual(dipsum(img > 0), dipsum(ifc.img > 0))
        end
        function test_constructWmSet(this)
            [set,ifc] = this.testObj.constructWmSet();
            img = set{1}.fourdfp.img;
            for s = 2:length(set)
                img = img + set{s}.fourdfp.img;
            end
            this.verifyEqual(dipsum(img > 0), dipsum(ifc.img > 0))
        end
	end

 	methods (TestClassSetup)
		function setupRois(this)
 			import mlpet.*;
            this.sesd = mlraichle.SessionData.create( ...
                'CCIR_00559/ses-E03056/FDG_DT20190523132832.000000-Converted-AC');
 			this.testObj_ = Rois.createFromSession(this.sesd);
 		end
	end

 	methods (TestMethodSetup)
		function setupRoisTest(this)
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

