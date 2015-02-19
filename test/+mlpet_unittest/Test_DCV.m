classdef Test_DCV < matlab.unittest.TestCase 
	%% TEST_DCV  

	%  Usage:  >> results = run(mlpet_unittest.Test_DCV)
 	%          >> result  = run(mlpet_unittest.Test_DCV, 'test_dt')
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
        unittest_home = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/ECAT_EXACT/pet'
 	end 

	methods (Test) 
        function test_ctor(this)
            this.assertEqual(this.testObj.fqfilename, fullfile(this.unittest_home, 'p7267ho1.dcv'));
            this.assertEqual(this.testObj.scanIndex, 1);
            this.assertEqual(this.testObj.length, 121);
            this.assertEqual(this.testObj.scanDuration, 128);
        end
        function test_times(this)
            this.assertEqual(this.testObj.times(4), 4);
            this.assertEqual(this.testObj.times(116), 116);
            this.assertEqual(this.testObj.times(121), 128);
        end
        function test_timeInterpolants(this)
            this.assertEqual(this.testObj.timeInterpolants(128), 128);
        end
        function test_counts(this)
            this.assertEqual(this.testObj.counts(4), 1363.3);
            this.assertEqual(this.testObj.counts(116), 29940.2);
            this.assertEqual(this.testObj.counts(121), 32623.4);
        end
        function test_countInterpolants(this)
            this.assertEqual(this.testObj.countInterpolants(128), 32623.4);
        end
        function test_header(this)
            this.assertEqual(this.testObj.header.samples, uint8(121));
            this.assertEqual(this.testObj.header.n1, 0);
            this.assertEqual(this.testObj.header.n2, 34);
            this.assertEqual(this.testObj.header.wellf, 11.3142);
            this.assertEqual(this.testObj.header.t0, 3.46);
            this.assertEqual(this.testObj.header.e, 0.078);
            this.assertEqual(this.testObj.header.nsmo, uint8(2));
            this.assertEqual(this.testObj.header.string, ...
                '12:55      121  0.0000  34.0  WELLF= 11.3142 T0= 3.46 K1= 0.300 E=.078 NSMO= 2  p7267ho1.crv');
        end
 	end 

 	methods (TestClassSetup) 
 		function setupDCV(this)  
            cd(this.unittest_home);
 			this.testObj = mlpet.DCV('p7267ho1'); 
 		end 
 	end 

 	methods (TestClassTeardown) 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

