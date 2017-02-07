classdef Test_DecayCorrectedCRV < matlab.unittest.TestCase 
	%% TEST_DECAYCORRECTEDCRV  

	%  Usage:  >> results = run(mlpet_unittest.Test_DecayCorrectedCRV)
 	%          >> result  = run(mlpet_unittest.Test_DecayCorrectedCRV, 'test_dt')
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
        unittest_home = fullfile(getenv('UNITTESTS'), 'cvl/np755/mm01-007_p7267_2008jun16/ECAT_EXACT/pet', '')
 	end 

	methods (Test) 
        function test_load(this)
            newObj = mlpet.DecayCorrectedCRV.load('p7267ho1');
            this.verifyEqual(this.testObj.counts, newObj.counts);
        end
        function test_ctor(this)
            this.verifyEqual(this.testObj.fqfilename, fullfile(this.unittest_home, 'p7267ho1.crv'));
            this.verifyEqual(this.testObj.scanIndex, 1);
            this.verifyEqual(this.testObj.tracer, 'ho');
            this.verifyEqual(this.testObj.length, 120);
            this.verifyEqual(this.testObj.scanDuration, 120);
        end
        function test_times(this)
            this.verifyEqual(this.testObj.times(4), 4);
            this.verifyEqual(this.testObj.times(120), 120);
        end
        function test_timeInterpolants(this)
            this.verifyEqual(this.testObj.timeInterpolants(120), 120);
        end
        function test_counts(this)
            this.verifyEqual(this.testObj.counts(4),   41.941659412967688, 'RelTol', 1e-10);
            this.verifyEqual(this.testObj.counts(120), 3978.28919721223, 'RelTol', 1e-10);
        end
        function test_countInterpolants(this)
            this.verifyEqual(this.testObj.countInterpolants(120), 3978.28919721223, 'RelTol', 1e-10);
        end
        function test_wellCounts(this)
            this.verifyEqual(this.testObj.wellCounts(4),   4.745363229301990e+02, 'RelTol', 1e-10);
            this.verifyEqual(this.testObj.wellCounts(120), 4.501115963509861e+04, 'RelTol', 1e-10);
        end
        function test_wellCountInterpolants(this)
            this.verifyEqual(this.testObj.wellCountInterpolants(120), 4.501115963509861e+04, 'RelTol', 1e-10);
        end
        function test_header(this)
            this.verifyEqual(this.testObj.header.fqfilename, 'C:\data\p7267ho1.crv');
            this.verifyEqual(this.testObj.header.date, 'Mon, Jun 16, 2008 12:55 PM');
            this.verifyEqual(this.testObj.header.binwidth, 1);
            this.verifyEqual(this.testObj.header.rows, 120);
            this.verifyEqual(this.testObj.header.cols, 3);
            this.verifyEqual(this.testObj.header.string(1:7), 'C:\data');
        end  
        function test_isotope(this)
            this.verifyEqual(this.testObj.isotope, '15O');
        end
        function test_wellFactor(this)            
            this.verifyEqual(this.testObj.wellFactor, 11.3142);
        end
 	end 

 	methods (TestClassSetup) 
 		function setupDecayCorrectedCRV(this) 
            cd(this.unittest_home);
            import mlpet.*;
 			this.testObj = DecayCorrectedCRV(CRV('p7267ho1')); 
 		end 
 	end 

 	methods (TestClassTeardown) 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

