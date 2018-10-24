classdef Test_BloodSucker < matlab.unittest.TestCase
	%% TEST_BLOODSUCKER 

	%  Usage:  >> results = run(mlpet_unittest.Test_BloodSucker)
 	%          >> result  = run(mlpet_unittest.Test_BloodSucker, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 31-Jan-2017 20:03:38
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        deltaTimeDcv = -16
 		registry
        sessd
        sessp = '/data/cvl/np755/mm01-007_p7267_2008jun16'
 		testObj
 	end

	methods (Test)
        function test_ctor(this)
            this.verifyEqual(this.testObj.fqfilename, this.sessd.dcv);
%            this.verifyEqual(this.testObj.sessionData.snumber, 1);
%            this.verifyEqual(this.testObj.length, 117);
            this.verifyEqual(this.testObj.timeDuration, 127);
        end
        function test_times(this)
            this.verifyEqual(this.testObj.times(4), 4);
            this.verifyEqual(this.testObj.times(116), 116);
            this.verifyEqual(this.testObj.times(117), 128);
        end
        function test_timeInterpolants(this)
            this.verifyEqual(this.testObj.timeInterpolants(255), 128);
        end
        
        function test_counts(this)
            this.verifyEqual(this.testObj.counts(4),   1332.6916670044,  'RelTol', 1e-3);
            this.verifyEqual(this.testObj.counts(116), 15497.5795405739, 'RelTol', 1e-3);
            this.verifyEqual(this.testObj.counts(117), 15774.4105765911, 'RelTol', 1e-3);
        end
        function test_wellCounts(this)
            this.verifyEqual(max(this.testObj.wellCounts), 181400.6, 'RelTol', 1e-3);
            this.verifyEqual(min(this.testObj.wellCounts), 982.6, 'RelTol', 1e-2);
        end
        function test_countInterpolants(this)
            this.verifyEqual(this.testObj.countInterpolants(255), 15774.4105765911, 'RelTol', 1e-3);
        end
        function test_header(this)
            this.verifyEqual(this.testObj.bloodSuckerDcv.header.samples, uint8(121));
            this.verifyEqual(this.testObj.bloodSuckerDcv.header.n1, 0);
            this.verifyEqual(this.testObj.bloodSuckerDcv.header.n2, 34);
            this.verifyEqual(this.testObj.bloodSuckerDcv.header.wellf, 11.3142);
            this.verifyEqual(this.testObj.bloodSuckerDcv.header.t0, 3.46);
            this.verifyEqual(this.testObj.bloodSuckerDcv.header.e, 0.078);
            this.verifyEqual(this.testObj.bloodSuckerDcv.header.nsmo, uint8(2));
            this.verifyEqual(this.testObj.bloodSuckerDcv.header.string, ...
                '12:55      121  0.0000  34.0  WELLF= 11.3142 T0= 3.46 K1= 0.300 E=.078 NSMO= 2  p7267ho1.crv');
        end
	end

 	methods (TestClassSetup)
		function setupBloodSucker(this)
            studyd = mlderdeyn.StudyDataSingleton.instance;
            this.sessd = mlderdeyn.SessionData('studyData', studyd, 'sessionPath', this.sessp, 'subjectsDir', '/data/cvl/np755');
            this.sessd.tracer = 'HO';
            cd(fullfile(this.sessp, 'ECAT_EXACT', 'pet', ''));
 			import mlpet.*;
 			this.testObj_ = BloodSucker( ...
                'scannerData', mlsiemens.EcatExactHRPlus.loadSession(this.sessd, this.sessd.ho('typ', 'nii.gz')), ...
                'aifTimeShift', 0, ...
                'isotope', '15O');
            this.testObj_.dt = 0.5;
 		end
	end

 	methods (TestMethodSetup)
		function setupBloodSuckerTest(this)
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

