classdef Test_PetObsBuilder < matlab.unittest.TestCase
	%% TEST_PETOBSBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_PetObsBuilder)
 	%          >> result  = run(mlpet_unittest.Test_PetObsBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 06-Jan-2017 16:02:46
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
 		registry
        sessd
        studyd
 		testObj
 	end

	methods (Test)
		function test_buildPetObsMap(this)
            this.testObj = this.testObj.buildPetObsMap;
            petObs = this.testObj.product;
            this.verifyClass(petObs, 'mlpet.PETImagingContext');
            petObsSum = petObs.volumeSummed;
            petObs.fslview;
            petObsSum.fslview;
            plot(petObs.volumeSummed);
        end
	end

 	methods (TestClassSetup)
		function setupPetObsBuilder(this)
 			import mlpet.*;
            this.studyd = mlraichle.SynthStudyData;
            this.sessd = mlraichle.SynthSessionData( ...
                'studyData', this.studyd, ...
                'sessionPath', fullfile(getenv('PPG'), 'jjleeSynth', 'HYGLY00', ''));
 			this.testObj_ = PetObsBuilder('sessionData', this.sessd);
 		end
	end

 	methods (TestMethodSetup)
		function setupPetObsBuilderTest(this)
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

