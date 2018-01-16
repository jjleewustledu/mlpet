classdef Test_CRV < matlab.unittest.TestCase 
	%% TEST_CRV  

	%  Usage:  >> results = run(mlpet_unittest.Test_CRV)
 	%          >> result  = run(mlpet_unittest.Test_CRV, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 

	properties 
 		testObj 
        unittest_home = '/data/cvl/np755/mm01-007_p7267_2008jun16/ECAT_EXACT/pet'
 	end 

	methods (Test) 
        function test_ctor(this)
            this.assertEqual(this.testObj.fqfilename, fullfile(this.unittest_home, 'p7267ho1.crv'));
            this.assertEqual(this.testObj.scanIndex, 1);
            this.assertEqual(this.testObj.length, 120);
            this.assertEqual(this.testObj.scanDuration, 120);
        end
        function test_times(this)
            this.assertEqual(this.testObj.times(4), 4);
            this.assertEqual(this.testObj.times(120), 120);
        end
        function test_timeInterpolants(this)
            this.assertEqual(this.testObj.timeInterpolants(120), 120);
        end
        function test_counts(this)
            this.assertEqual(this.testObj.counts(4), 41);
            this.assertEqual(this.testObj.counts(120), 2013);
        end
        function test_countInterpolants(this)
            this.assertEqual(this.testObj.countInterpolants(120), 2013);
        end
        function test_header(this)
            this.assertEqual(this.testObj.header.fqfilename, 'C:\data\p7267ho1.crv');
            this.assertEqual(this.testObj.header.date, 'Mon, Jun 16, 2008 12:55 PM');
            this.assertEqual(this.testObj.header.binwidth, 1);
            this.assertEqual(this.testObj.header.rows, 120);
            this.assertEqual(this.testObj.header.cols, 3);
            this.assertEqual(this.testObj.header.string(1:7), 'C:\data');
        end
 	end 

 	methods (TestClassSetup) 
 		function setupCRV(this) 
            cd(this.unittest_home);
 			this.testObj = mlpet.CRV('p7267ho1'); 
 		end 
 	end 

 	methods (TestClassTeardown) 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

