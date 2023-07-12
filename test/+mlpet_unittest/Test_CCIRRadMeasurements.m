classdef Test_CCIRRadMeasurements < matlab.unittest.TestCase
	%% TEST_CCIRRADMEASUREMENTS 

	%  Usage:  >> results = run(mlpet_unittest.Test_CCIRRadMeasurements)
 	%          >> result  = run(mlpet_unittest.Test_CCIRRadMeasurements, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 21-Jan-2018 15:05:06 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        aDate
 		registry
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_loadDate(this)
            this.verifyClass(this.testObj, 'mlpet.CCIRRadMeasurements')
        end    
        function test_datetime(this)
            this.verifyEqualDatetime(datetime(this.testObj), ...
                                     datetime(2018,10,5,11,51,12, 'TimeZone', 'America/Chicago'));
        end    
        function test_wellCounterRefSrc(this)
            wcrs = this.testObj.wellCounterRefSrc;            
            this.verifyEqualDatetime(wcrs{1, 'TIMECOUNTED_Hh_mm_ss'}, ...
                                     datetime(2018,10,5,10,47,31, 'TimeZone', 'America/Chicago'));
            this.verifyEqual(wcrs{1, 'CF_Kdpm'},    33.34, 'RelTol', sqrt(eps));
            this.verifyEqual(wcrs{1, 'Ge_68_Kdpm'}, 19.17, 'RelTol', sqrt(eps));
        end
        function test_countsFdg(this)
            this.verifyEqualDatetime(this.testObj.countsFdg{'5', 'Time_Hh_mm_ss'}, ...
                                     datetime(2018,10,5,16,8,1, 'TimeZone', 'America/Chicago'));
            this.verifyEqualDatetime(this.testObj.countsFdg{'5', 'TIMEDRAWN_Hh_mm_ss'}, ...
                                     datetime(2018,10,5,14,26,50, 'TimeZone', 'America/Chicago'));
            this.verifyEqualDatetime(this.testObj.countsFdg{'5', 'TIMECOUNTED_Hh_mm_ss'}, ...
                                     datetime(2018,10,5,16,29,53, 'TimeZone', 'America/Chicago'));
        end
        function test_countsOcOo(this)
            this.verifyEqualDatetime(this.testObj.countsOcOo{'1', 'Time_Hh_mm_ss'}, ...
                                     datetime(2018,10,5,10,36,49, 'TimeZone', 'America/Chicago'));
            this.verifyEqualDatetime(this.testObj.countsOcOo{'1', 'TIMEDRAWN_Hh_mm_ss'}, ...
                                     datetime(2018,10,5,11,55,53, 'TimeZone', 'America/Chicago'));
            this.verifyEqualDatetime(this.testObj.countsOcOo{'1', 'TIMECOUNTED_Hh_mm_ss'}, ...
                                     datetime(2018,10,5,11,56,57, 'TimeZone', 'America/Chicago'));
        end
        function test_tracerAdmin(this)
            for it = 1:length(this.testObj.tracerAdmin.ADMINistrationTime_Hh_mm_ss)
                this.verifyEqualDatetime(this.testObj.tracerAdmin.ADMINistrationTime_Hh_mm_ss(it), ...
                                         this.testObj.tracerAdmin.TrueAdmin_Time_Hh_mm_ss(it));
            end
            this.verifyEqual(this.testObj.tracerAdmin.Properties.RowNames, ...
                             {'C[15O]' 'O[15O]' 'H2[15O]' 'C[15O]_1' 'O[15O]_1' 'H2[15O]_1' '[18F]DG'}');
        end
        function test_clocks(this)
            this.verifyEqual(this.testObj.clocks.TimeOffsetWrtNTS____s, ...
                             [-72 0 0 0 2 0]');
        end
        function test_doseCalibrator(this)
            this.verifyEqualDatetime(this.testObj.datetimeDoseCalibrator, ...
                                     datetime(2018,10,5,15,25,35, 'TimeZone', 'America/Chicago'));
        end
        function test_phantom(this)
            this.verifyEqual(this.testObj.phantom{1, 'DECAYCorrSpecificActivity_KBq_mL'}, ...
                73.9990112792118, 'RelTol', sqrt(eps));
        end
        function test_wellCounter(this)
            this.verifyEqualDatetime(this.testObj.wellCounter{'GE', 'TIMEDRAWN_Hh_mm_ss'}, ...
                                     datetime(2018,10,5,15,40,15, 'TimeZone', 'America/Chicago'));
            this.verifyEqualDatetime(this.testObj.wellCounter{'GE', 'TIMECOUNTED_Hh_mm_ss'}, ...
                                     datetime(2018,10,5,10,42,10, 'TimeZone', 'America/Chicago'));
            this.verifyEqual(this.testObj.wellCounter{'C1', 'DECAYCorrSpecificActivity_KBq_mL'}, ...
                60.8784699935024, 'RelTol', sqrt(eps));
        end
        function test_twilite(this)
            this.verifyEqualDatetime(this.testObj.twilite{'Braun ref V5424, 48 cm len, 0.642 mL priming vol', 'CathPlace_mentTime_Hh_mm_ss'}, ...
                                     datetime(2018,10,5,15,40,15, 'TimeZone', 'America/Chicago'));
            this.verifyEqual(this.testObj.twilite{'Braun ref V5424, 48 cm len, 0.642 mL priming vol', 'DECAYCORRSpecificActivity_KBq_mL'}, ...
                70.036073271028, 'RelTol', sqrt(eps));
        end
        function test_mMR(this)
            this.verifyEqualDatetime(this.testObj.mMR{'ROI1', 'scanStartTime_Hh_mm_ss'}, ...
                                     datetime(2018,10,5,15,39,03, 'TimeZone', 'America/Chicago'));
            this.verifyEqual(this.testObj.mMR{'ROI1', 'DECAYCorrSpecificActivity_KBq_mL'}, ...
                54.881, 'RelTol', sqrt(eps));
        end
        function test_pmod(this)
            this.verifyEqual(this.testObj.pmod{'Calibration Window', 'TwiliteSpecificActivity_CoincidentKcps_mL'}, ...
                70.036073271028,  'RelTol', sqrt(eps));
            this.verifyEqual(this.testObj.pmod{'Calibration Window', 'mMRSPECIFICActivity_KBq_mL'}, ...
                55.1810333333333, 'RelTol', sqrt(eps));
        end
	end

 	methods (TestClassSetup)
		function setupCCIRRadMeasurements(this)
 		end
	end

 	methods (TestMethodSetup)
		function setupCCIRRadMeasurementsTest(this)
 			import mlpet.*;
            this.aDate = datetime(2018,10,5);
            warning('off', 'mlpet:ValueWarning');   
 			this.testObj = mlpet.CCIRRadMeasurements.createFromDate(this.aDate);
            warning('on', 'mlpe:ValueWarning');   
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 	end

	methods (Access = private)
		function cleanFiles(this)
        end
        function verifyEqualDatetime(this, dt, dt1)
            this.verifyTrue(abs(dt1 - dt) < milliseconds(1000));
        end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

