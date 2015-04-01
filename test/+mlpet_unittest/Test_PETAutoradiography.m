classdef Test_PETAutoradiography < matlab.unittest.TestCase 
	%% TEST_PETAUTORADIOGRAPHY  

	%  Usage:  >> results = run(mlpet_unittest.Test_PETAutoradiography)
 	%          >> result  = run(mlpet_unittest.Test_PETAutoradiography, 'test_dt')
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
 	end 

	methods (Test) 
 		function test_afun(this) 
 			import mlpet.*; 
 			this.assumeEqual(1,1); 
 			this.verifyEqual(1,1); 
 			this.assertEqual(1,1); 
 		end 
 	end 

 	methods (TestClassSetup) 
 		function setupPETAutoradiography(this) 
 			this.testObj = mlpet.PETAutoradiography; 
 		end 
 	end 

 	methods (TestClassTeardown) 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

