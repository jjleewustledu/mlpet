classdef Test_CCIRCalibrationBuilder < matlab.unittest.TestCase
	%% TEST_CCIRCALIBRATIONBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_CCIRCalibrationBuilder)
 	%          >> result  = run(mlpet_unittest.Test_CCIRCalibrationBuilder, 'test_ctor')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 21-Dec-2018 18:40:51 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		registry
 		testObj
 	end

	methods (Test)
        function test_ctor(this)
        end
        function test_ApertureCalibration(this)
        end
        function test_SensitivityCalibration(this)
        end
        function test_RefSourceCalibration(this)
        end
        function test_readMeasurements(this)
            this.testObj.readMeasurements;
        end
        function test_selectCalHierarchy(this)
        end
        function test_propagateEfficiencies(this)
        end
	end

 	methods (TestClassSetup)
		function setupCCIRCalibrationBuilder(this)
 		end
	end

 	methods (TestMethodSetup)
		function setupCCIRCalibrationBuilderTest(this)
 			import mlpet.*;
 			this.testObj = CCIRCalibrationBuilder('sessionData', ...
                mlraichle.SessionData('studyData', mlraichle.StudyData, 'sessionFolder', 'HYGLY28'));
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

