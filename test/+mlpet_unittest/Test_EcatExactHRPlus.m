classdef Test_EcatExactHRPlus < matlab.unittest.TestCase 
	%% TEST_ECATEXACTHRPLUS  

	%  Usage:  >> results = run(mlpet_unittest.Test_EcatExactHRPlus)
 	%          >> result  = run(mlpet_unittest.Test_EcatExactHRPlus, 'test_dt')
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
        pie = 5.2038
 	end 

	methods (Test) 
        function test_ctor(this)
            this.assertEqual(this.testObj.fqfilename, fullfile(this.unittest_home, 'p7267ho1.nii.gz'));
            this.assertEqual(this.testObj.scanIndex, 1);
            this.assertEqual(this.testObj.length, 60);
            this.assertEqual(this.testObj.scanDuration, 1.593330000000000e+02);
        end
        function test_times(this)
            this.assertEqual(this.testObj.times(4), 47.332999999999998);
            this.assertEqual(this.testObj.times(60), 1.593330000000000e+02);
        end
        function test_timeInterpolants(this)
            this.assertEqual(this.testObj.timeInterpolants(119), 1.593330000000000e+02);
        end
        function test_counts(this)
            this.assertEqual(this.testObj.counts(64,64,30,4), 63);
            this.assertEqual(this.testObj.counts(64,64,30,60), 125);
        end
        function test_countInterpolants(this)
            obj = this.testObj;
            obj.counts = obj.counts(64,64,30,:);
            this.assertEqual(obj.countInterpolants(4), 36.5287927350427, 'RelTol', 1e-5);
        end
        function test_wellCounts(this)
            this.assertEqual(this.testObj.wellCounts(64,64,30,4), 655.6788);
            this.assertEqual(this.testObj.wellCounts(64,64,30,60), 1300.95);
        end
        function test_wellCountInterpolants(this)
            obj = this.testObj;
            obj.counts = obj.counts(64,64,30,:);
            this.assertEqual(obj.wellCountInterpolants(4), 380.177063269231, 'RelTol', 1e-5);
        end
        function test_header(this)
            this.assertEqual(this.testObj.header.injectionTime, 41.333);
            this.assertEqual(this.testObj.header.numberOfFrames, 61);
            this.assertEqual(this.testObj.header.string(1:23), 'rec p7267ho1_frames.img');
            this.assertEqual(this.testObj.header.frame(4), 5);
            this.assertEqual(this.testObj.header.start(4), 6);
            this.assertEqual(this.testObj.header.duration(4), 2);
        end
 	end 

 	methods (TestClassSetup) 
 		function setupCRV(this) 
 		end 
 	end 

 	methods (TestClassTeardown) 
    end 
    
    methods 
        function this = Test_EcatExactHRPlus
            this = this@matlab.unittest.TestCase;
            cd(this.unittest_home);
 			this.testObj = mlpet.EcatExactHRPlus(this.pie, mlfourd.NIfTId.load('p7267ho1')); 
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

