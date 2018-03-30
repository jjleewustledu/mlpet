classdef Test_MultiBolusData < matlab.unittest.TestCase
	%% TEST_TWILITETIMINGDATA 

	%  Usage:  >> results = run(mlpet_unittest.Test_MultiBolusData)
 	%          >> result  = run(mlpet_unittest.Test_MultiBolusData, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 03-Feb-2018 15:41:45 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		registry
 		testObj
 	end

	methods (Test)
        function test_times(this)
            this.verifyEqual(this.testObj.times, 100:199);
        end
        function test_time0(this)
            this.verifyEqual(this.testObj.time0, 100);
            this.testObj.index0 = 2;
            this.verifyEqual(this.testObj.time0, 101);
        end
        function test_timeF(this)
            this.verifyEqual(this.testObj.timeF, 199);
            this.testObj.indexF = 2;
            this.verifyEqual(this.testObj.timeF, 101);
        end
		function test_timeDuration(this)
            this.verifyEqual(this.testObj.timeDuration, 99);         
        end
        function test_datetime(this)
            this.verifyEqual(length(this.testObj.datetime), length(this.testObj.times));
            dt_ = this.testObj.datetime;
            this.verifyEqual(dt_(1),   this.testObj.datetime0);
            this.verifyEqual(dt_(end), this.testObj.datetimeF);
        end
        function test_datetime0(this)
            this.verifyTrue(this.testObj.datetime0 == ...
                datetime('1-Jan-2017 09:00:00', 'TimeZone', 'America/Chicago'));
        end
        function test_datetimeF(this)
            this.verifyTrue(this.testObj.datetimeF == ...
                datetime('1-Jan-2017 09:00:00', 'TimeZone', 'America/Chicago') + seconds(99));
        end
        
        function test_baseline(this)
            this.verifyEqual(this.testObj.baseline, 0.139183120188254, 'AbsTol', 1e-6);
        end
        function test_baselineTimeForward(this)
            this.verifyEqual(this.testObj.baselineTimeForward, 1);
        end
        function test_baselineTimeReversed(this)
            this.verifyEqual(this.testObj.baselineTimeReversed, 0.139183120188254, 'AbsTol', 1e-6);
        end
        function test_plot(this)
            this.testObj.plot;
        end
	end

 	methods (TestClassSetup)
		function setupMultiBolusData(this)
 			import mlpet.*;
 			this.testObj_ = MultiBolusData( ...
                'activity', exp(-(0:99)/33), ...
                'times', 100:199, ...
                'dt', 0.5, ...
                'datetime0', datetime('1-Jan-2017 09:00:00', 'TimeZone', 'America/Chicago'), ...
                'expectedBaseline', 0.139183120188254);
 		end
	end

 	methods (TestMethodSetup)
		function setupMultiBolusDataTest(this)
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

