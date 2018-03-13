classdef Test_DecayCorrection < matlab.unittest.TestCase
	%% TEST_DECAYCORRECTION 

	%  Usage:  >> results = run(mlpet_unittest.Test_DecayCorrection)
 	%          >> result  = run(mlpet_unittest.Test_DecayCorrection, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 20-Jul-2017 15:54:00 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
        client
        crv
        dcv
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
        function test_correctedCounts(this)            
            %figure; plot(this.client.times, this.client.counts);
            %title('this.client.times, this.client.counts');
            
            %% expect Heaviside from tzero, max from client at tzero
            
            cc = this.testObj.correctedActivities(this.client.counts, 22);
            %figure; plot(cc);
            %title('this.testObj.correctedActivities(this.client.counts, 22)');
            this.verifyEqual(cc(1:22),  zeros(1,22), 'RelTol', 1e-6);
            this.verifyEqual(cc(23:end), 1*ones(1,100), 'RelTol', 1e-6);
            
            cc = this.testObj.correctedActivities(this.client.counts, 100);
            %figure; plot(cc);
            %title('this.testObj.correctedActivities(this.client.counts, 100)');
            this.verifyEqual(cc(1:22),  zeros(1,22), 'RelTol', 1e-6);
            this.verifyEqual(cc(23:end), 2^(-78/122.2416)*ones(1,100), 'RelTol', 1e-6);
        end
        function test_uncorrectedCounts(this)
            nodecay = this.client.counts.*2.^((this.client.times - 22)/122.2416);
            figure; plot(this.client.times, this.client.counts, ...
                         this.client.times, nodecay);
            title('this.client.times, this.client.counts, this.client.times, no-decay counts');
            legend('this.client', 'no-decay counts');
            
            %% expect power decay from tzero, counts(tzero) \approx 1, counts(t < tzero) > 1
            
            decay = this.testObj.uncorrectedActivities(nodecay, 22);
            figure; plot(decay);
            title('this.testObj.uncorrectedActivities(nodecay, 22)');
            this.verifyEqual(decay(1:22),  zeros(1,22), 'RelTol', 1e-6);
            this.verifyEqual(decay(23:end), 2.^(-(0:99)/122.2416), 'RelTol', 1e-6);
            
            decay = this.testObj.uncorrectedActivities(nodecay, 100);
            figure; plot(decay);
            title('this.testObj.uncorrectedActivities(nodecay, 100)');
            this.verifyEqual(decay(1:22),  zeros(1,22), 'RelTol', 1e-6);
            this.verifyEqual(decay(23:100), 2.^((78:-1:1)/122.2416), 'RelTol', 1e-6);
            this.verifyEqual(decay(101:end), 2.^(-(0:21)/122.2416), 'RelTol', 1e-6);
        end
	end

 	methods (TestClassSetup)
		function setupDecayCorrection(this)
 			import mlpet.*;
            cnts = zeros(1,122);
            cnts(23:122) = 2.^(-(0:99)/122.2416);
            this.client_ = struct( ...
                'isotope', '15O', ...
                'datetime0', datetime('1-Jul-2017 09:00:00'), ...
                'doseAdminDatetime', datetime('1-Jul-2017 09:00:00'), ...
                'times', 0:121, 'time0', 0, 'timeF', 121, ...
                'counts', cnts, ...
                'isDecayCorrected', false);
 			this.testObj_ = DecayCorrection.factoryFor(this.client_);
            pth = fullfile(getenv('HOME'), 'MATLAB-Drive/mlpet/data');
            this.crv_ = mlpet.CRV.load(fullfile(pth, 'AMAtest5.crv'));
            this.dcv_ = mlpet.DCV.load(fullfile(pth, 'AMAtest5.dcv'));
 		end
	end

 	methods (TestMethodSetup)
		function setupDecayCorrectionTest(this)
 			this.client  = this.client_;
 			this.testObj = this.testObj_;
 			this.crv     = this.crv_;
 			this.dcv     = this.dcv_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
        crv_
        dcv_
        client_
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

