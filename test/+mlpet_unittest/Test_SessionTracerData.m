classdef Test_SessionTracerData < matlab.unittest.TestCase
	%% TEST_SESSIONTRACERDATA 

	%  Usage:  >> results = run(mlpet_unittest.Test_SessionTracerData)
 	%          >> result  = run(mlpet_unittest.Test_SessionTracerData, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 26-May-2018 15:14:56 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		registry
 		testObj
 	end

	methods (Test)
        function test_absScatterCorrected(this)
            this.testObj.tracer = 'HO';
            this.verifyFalse(this.testObj.absScatterCorrected);
            this.testObj.tracer = 'OO';
            this.verifyTrue(this.testObj.absScatterCorrected);
        end
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_agi(this)
        end
        function test_arterialSamplerCalCrv(this)
        end
        function test_arterialSamplerCrv(this)
        end
        function test_attenuationTag(this)
        end
        function test_convertedTag(this)
        end
        function test_doseAdminDatetimeTag(this)
        end
        function test_frameTag(this)
        end
        function test_tauIndices(this)
        end
        function test_taus(this)
        end
        function test_times(this)
        end
        function test_timeMidpoints(this)
        end
        function test_cbf(this)
        end
        function test_cbv(this)
        end
        function test_CCIRRadMeasurements(this)
        end
        function test_cmrglc(this)
        end
        function test_cmro2(this)
        end
        function test_ct(this)
        end
        function test_ctMask(this)
            % legacy use by mlpet.PETConstrolsDirector
        end
        function test_ctMasked(this)
        end
        function test_ctRescaled(this)
        end
        function test_fdg(this)
        end
        function test_gluc(this)
        end
        function test_ho(this)
        end
        function test_isotope(this)            
            this.testObj.tracer = 'OC';
            this.verifyEqual(this.testObj.isotope, '15O');
            this.testObj.tracer = 'FDG';
            this.verifyEqual(this.testObj.isotope, '18F');
        end
        function test_oc(this)
        end
        function test_oef(this)
        end
        function test_ogi(this)
        end
        function test_oo(this)
        end
        function test_petObject(this)
        end
        function test_petPointSpread(this)
        end
        function test_snumber(this)
            this.testObj.tracer = 'OC';
            this.verifyEqual(this.testObj.snumber, 1);
            this.testObj.tracer = 'FDG';
            this.verifyEqual(this.testObj.snumber, 1);            
        end
        function test_strategy(this)
            this.verifyEqual(this.testObj.tracer, 'FDG');
            this.verifyEqual(this.testObj.tracerRevision, '');
            this.testObj.tracer = 'HO';
            this.verifyEqual(this.testObj.tracerRevision, '');
            this.testObj.tracer = 'OO';
            this.verifyEqual(this.testObj.tracerRevision, '');
            this.testObj.tracer = 'OC';
            this.verifyEqual(this.testObj.tracerRevision, '');
        end
        function test_tracerBlurArg(this)
        end
        function test_tracerConvertedLocation(this)
        end
        function test_tracerListmodeFrameV(this)
        end
        function test_tracerListmodeLocation(this)
        end
        function test_tracerListmodeMhdr(this)
        end
        function test_tracerListmodeSif(this)
        end
        function test_tracerListmodeUmap(this)
        end
        function test_tracerLocation(this)
            this.verifyEqual(this.testObj.tracerLocation, fullfile(this.sessd.sessionLocation, 'FDG_V1-AC', ''));
        end
        function test_tracerPristine(this)
        end
        function test_tracerRawdataLocation(this)
        end
        function test_tracerResolved(this)
        end
        function test_tracerResolvedFinal(this)
        end
        function test_tracerRevision(this)
        end
        function test_tracerSif(this)
        end
        function test_tracerSuvr(this)
        end
        function test_tracerSuvrAveraged(this)
        end
        function test_tracerSuvrNamed(this)
        end
        function test_umap(this)
            % legacy support
        end
        function test_umapSynth(this)
        end
        function test_umapBlurArg(this)
        end
	end

 	methods (TestClassSetup)
		function setupSessionTracerData(this)
 			import mlpet.*;
 			this.testObj_ = SessionTracerData;
 		end
	end

 	methods (TestMethodSetup)
		function setupSessionTracerDataTest(this)
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

