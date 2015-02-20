classdef Test_DecayCorrectedEcat < matlab.unittest.TestCase 
	%% TEST_DECAYCORRECTEDECAT  

	%  Usage:  >> results = run(mlpet_unittest.Test_DecayCorrectedEcat)
 	%          >> result  = run(mlpet_unittest.Test_DecayCorrectedEcat, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 

	properties 
        unittest_home = '/Volumes/InnominateHD2/Local/test/Arbelaez/GluT/p8047_JJL/PET/scan1'
 		testObj 
 	end 

	methods (Test) 
        function test_load(this)
            newObj = mlpet.DecayCorrectedEcat.load('p8047gluc1', 4.88);
            this.assertEqual(this.testObj.counts, newObj.counts);
        end
        function test_ctor(this)
            this.assertEqual(this.testObj.fqfilename, fullfile(this.unittest_home, 'p8047gluc1_decayCorrect.nii.gz'));
            this.assertEqual(this.testObj.scanIndex, 1);
            this.assertEqual(this.testObj.tracer, 'gluc');
            this.assertEqual(this.testObj.length, 44);
            this.assertEqual(this.testObj.scanDuration, 3420);
        end
        function test_times(this)
            this.assertEqual(this.testObj.times(4), 90);
            this.assertEqual(this.testObj.times(44), 3420);
        end
        function test_taus(this)
            this.assertEqual(this.testObj.taus(4), 30);
            this.assertEqual(this.testObj.taus(44), 180);
        end
        function test_injectionTime(this)
            this.assertEqual(this.testObj.injectionTime, 18.9330);
        end
        function test_counts(this)
            this.assertEqual(this.testObj.counts(64,64,32,4), single(1.6424975e+05));
            this.assertEqual(this.testObj.counts(64,64,32,44), single(1.2486928e+06));
        end
        function test_header(this)
            this.assertEqual(this.testObj.header.injectionTime, 18.933);
            this.assertEqual(this.testObj.header.numberOfFrames, 45);
            this.assertEqual(this.testObj.header.string(1:25), 'rec p8047gluc1_frames.img');
            this.assertEqual(this.testObj.header.frame(4), 5);
            this.assertEqual(this.testObj.header.start(4), 90);
            this.assertEqual(this.testObj.header.duration(4), 30);
        end  
        function test_isotope(this)
            this.assertEqual(this.testObj.isotope, '11C');
        end
        function test_halfLife(this)
            this.assertEqual(this.testObj.halfLife, 20.334*60);
        end
        function test_pie(this)            
            this.assertEqual(this.testObj.pie, 4.88);
        end 
        function test_wellFactor(this)            
            this.assertEqual(this.testObj.wellFactor, 20.585);
        end
 	end 

 	methods (TestClassSetup) 
 		function setupDecayCorrectedEcat(this) 
 		end 
 	end 

 	methods (TestClassTeardown) 
    end 

    methods 
        function this = Test_DecayCorrectedEcat
            this = this@matlab.unittest.TestCase;
            cd(this.unittest_home);
            import mlpet.*;
 			this.testObj = DecayCorrectedEcat(EcatExactHRPlus('p8047gluc1'), 4.88); 
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

