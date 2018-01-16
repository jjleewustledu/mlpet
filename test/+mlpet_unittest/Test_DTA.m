classdef Test_DTA < matlab.unittest.TestCase 
	%% TEST_DTA  

	%  Usage:  >> results = run(mlpet_unittest.Test_DTA)
 	%          >> result  = run(mlpet_unittest.Test_DTA, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 

	properties 
        unittest_home = '/data/nil-bluearc/arbelaez/jjlee/GluT/p8047_JJL/wjp_proc'
 		testObj 
 	end 

	methods (Test) 
        function test_ctor(this)
            this.verifyEqual(this.testObj.fqfilename, fullfile(this.unittest_home, 'p8047g1.dta'));
            this.verifyEqual(this.testObj.scanIndex, 1);
            this.verifyEqual(this.testObj.length, 26);
            this.verifyEqual(this.testObj.scanDuration, 3600);
        end
        function test_times(this)
            this.verifyEqual(this.testObj.times(4), 24);
            this.verifyEqual(this.testObj.times(26), 3600);
        end
        function test_timeInterpolants(this)
            this.verifyEqual(this.testObj.timeInterpolants(3600), 3600);
        end        
        function test_counts(this)
            this.verifyEqual(this.testObj.counts(4), 7.887853193); 
            this.verifyEqual(this.testObj.counts(26), 941.4260025); 
        end
        function test_countInterpolants(this)
            this.verifyEqual(this.testObj.countInterpolants(3600), 941.4260025);
        end
        function test_otherData(this) 
            this.verifyEqual(this.testObj.syringeWeightDry(4), 3.9597);
            this.verifyEqual(this.testObj.syringeWeightWet(4), 5.081);
            this.verifyEqual(this.testObj.sampleTimesDrawn(4), 24.24);
            this.verifyEqual(this.testObj.sampleTimesCounted(4), 26.18);
            this.verifyEqual(this.testObj.measuredCounts(4), 46);
            this.verifyEqual(this.testObj.countPeriod(4), 12);
        end
        function test_header(this) 
            this.verifyEqual(this.testObj.header.pnumber, 'p8047');
            this.verifyEqual(this.testObj.header.dateScan, '6-20-12');
            this.verifyEqual(this.testObj.header.studyCode, 'cg');
            this.verifyEqual(this.testObj.header.petIndex, 1);
            this.verifyEqual(this.testObj.header.dateProcessing, '04/12/2013');
            this.verifyEqual(this.testObj.header.author, 'jad');
            this.verifyEqual(this.testObj.header.string, ...
                '@01@ p8047 6-20-12 cg1 04/12/2013 jad'); 
            this.verifyEqual(this.testObj.header.length, int32(26));
        end
 	end 

 	methods (TestClassSetup) 
 		function setupDTA(this) 
            cd(this.unittest_home);
 			this.testObj = mlpet.DTA.load('p8047g1', true); 
 		end 
 	end 

 	methods (TestClassTeardown) 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

