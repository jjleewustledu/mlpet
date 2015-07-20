classdef Test_TSC < matlab.unittest.TestCase 
	%% TEST_TSC  

	%  Usage:  >> results = run(mlpet_unittest.Test_TSC)
 	%          >> result  = run(mlpet_unittest.Test_TSC, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties  
        unittest_home = '/Volumes/InnominateHD2/Local/test/Arbelaez/GluT/p8047_JJL/jjl_proc'		 
        pnumPath 
        scanPath
        procPath
        tscFqfilename 
        dtaFqfilename
        ecatFqfilename
        testObj
 	end 

	methods (Test) 
        function test_import(this)
        end
        function test_loadGluT(this)
            newObj = mlpet.TSC.loadGluT(this.pnumPath, 1);
            this.assertEqual(double(this.testObj.counts), double(newObj.counts), 'RelTol', 0.02);
        end
        function test_load(this)
            this.assertEqual(this.testObj.pnumberPath, '/Volumes/InnominateHD2/Local/test/Arbelaez/GluT/p8047_JJL');
            this.assertEqual(this.testObj.pnumber,     'p8047');
            this.assertEqual(this.testObj.fslPath,     '/Volumes/InnominateHD2/Local/test/Arbelaez/GluT/p8047_JJL/fsl');
            this.assertEqual(this.testObj.petPath,     '/Volumes/InnominateHD2/Local/test/Arbelaez/GluT/p8047_JJL/PET');
            this.assertEqual(this.testObj.scanPath,    '/Volumes/InnominateHD2/Local/test/Arbelaez/GluT/p8047_JJL/PET/scan1');
            this.assertEqual(this.testObj.procPath,    '/Volumes/InnominateHD2/Local/test/Arbelaez/GluT/p8047_JJL/jjl_proc');
        end
        function test_save(this)            
            ca = mlio.TextIO.textfileToCell(this.tscFqfilename);
            this.assertTrue(strcmp('p8047g1.dta,  aparc_a2009s+aseg_mask_on_p8047gluc1_mcf.nii.gz, p8047gluc1_mcf_decayCorrect_masked.nii.gz, pie = 4.880000', strtrim(ca{1})));
            this.assertTrue(strcmp('43,    3', strtrim(ca{2})));
            this.assertTrue(strcmp('3258.9        180.0      867655.00', strtrim(ca{45})));
        end
        function test_makeMask(this)
            msk = this.testObj.makeMask;
            this.assertTrue(strcmp('aparc_a2009s+aseg_mask_on_p8047gluc1_mcf', msk.fileprefix));
        end
        function test_times(this)
            this.assertEqual(this.testObj.times(4),  108.933,  'RelTol', 1e-6);
            this.assertEqual(this.testObj.times(43), 3258.933, 'RelTol', 1e-6);
        end
        function test_taus(this)
            this.assertEqual(this.testObj.taus(4), 30);
            this.assertEqual(this.testObj.taus(43), 180);
        end
        function test_scanDuration(this)
            this.assertEqual(this.testObj.scanDuration, 3.438933000000000e+03);
        end
        function test_counts(this)
            this.assertEqual(this.testObj.counts(4),   66352.83, 'RelTol', 1e-6);
            this.assertEqual(this.testObj.counts(43), 860142.44, 'RelTol', 1e-6);
        end
        function test_header(this)
            this.assertEqual(this.testObj.header.injectionTime, 18.9330);
            this.assertEqual(this.testObj.header.string(1:14), 'rec p8047gluc1');
            this.assertEqual(this.testObj.header.start(43), 3240);
            this.assertEqual(this.testObj.header.duration(43), 180);
        end
    end

 	methods (TestClassSetup) 
 		function setupDTA(this) 
 		end 
    end

 	methods 		  
 		function this = Test_TSC(varargin) 
 			this = this@matlab.unittest.TestCase(varargin{:}); 
            
            this.pnumPath = '/Volumes/InnominateHD2/Local/test/Arbelaez/GluT/p8047_JJL';
            this.scanPath = fullfile(this.pnumPath, 'PET', 'scan1', '');
            this.procPath = fullfile(this.pnumPath, 'jjl_proc', '');
            this.tscFqfilename = fullfile(this.procPath, 'p8047wb1.tsc');
            this.dtaFqfilename = fullfile(this.procPath, 'p8047g1.dta');
            this.ecatFqfilename = fullfile(this.scanPath, 'p8047gluc1.nii.gz');
            cd(this.unittest_home);
 			this.testObj = mlpet.TSC.load( ...
                this.tscFqfilename, this.ecatFqfilename, this.dtaFqfilename, 4.88); 
 		end 
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

