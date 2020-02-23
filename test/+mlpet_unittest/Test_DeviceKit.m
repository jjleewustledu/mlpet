classdef Test_DeviceKit < matlab.unittest.TestCase
	%% TEST_INSTRUMENTKIT 

	%  Usage:  >> results = run(mlpet_unittest.Test_DeviceKit)
 	%          >> result  = run(mlpet_unittest.Test_DeviceKit, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 18-Oct-2018 14:18:16 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		registry
        scan
        session
 	end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_prepareCapracDevice(this)
            caprac = mlpet.DeviceKit.prepareCapracDevice('session', this.session);
            d = caprac.makeMeasurements(this.scan);
            this.verifyClass(d, 'mlcapintec.CapracData');
            %this.verifyEqual(d, );
        end
        function test_prepareTwiliteDevice(this)
            twilite = mlpet.DeviceKit.prepareTwiliteDevice('session', this.session);
            d = twilite.makeMeasurements(this.scan);
            this.verifyClass(d, 'mlswisstrace.TwiliteData');
            %this.verifyEqual(d, );
        end
        function test_prepareBiographMMRDevice(this)
            mmr = mlpet.DeviceKit.prepareBiographMMRDevice('session', this.session);
            d = mmr.makeMeasurements(this.scan);
            this.verifyClass(d, 'mlsiemens.BiographMMRData');
            %this.verifyEqual(d, );
        end
	end

 	methods (TestClassSetup)
		function setupDeviceKit(this)            
 		end
	end

 	methods (TestMethodSetup)
		function setupDeviceKitTest(this)
 			import mlraichle.*;
            this.session = MockSession( ...
                'project', 'CCIR_00559', 'subject', 'NP995-24', 'session', 'NP995-24_V1');
            this.scan = MockScan( ...
                'project', 'CCIR_00559', 'subject', 'NP995-24', 'session', this.session, ...
                'assessor', '', ...
                'resource', 'RawData', ...
                'tags', {'Head_MRAC_PET_5min'});
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

