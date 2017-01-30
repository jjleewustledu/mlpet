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
        session_home  = fullfile(getenv('UNITTESTS'), 'Arbelaez/GluT/p8047_JJL', '')
        unittest_home = fullfile(getenv('UNITTESTS'), 'Arbelaez/GluT/p8047_JJL/jjl_proc', '') 
        pnumPath 
        scanPath
        procPath
        tscFqfilename 
        dtaFqfilename
        ecatFqfilename
        testObj
    end 
    
    properties (Dependent)
        maskFqfilename
    end
    
    methods %% GET
        function fqfn = get.maskFqfilename(this)
            fqfn = fullfile(this.unittest_home, 'aparc_a2009s+aseg_mask_on_p8047gluc1_mcf.nii.gz');
        end
    end

	methods (Test) 
        function test_import(this)
        end
        function test_load(this)
            this.verifyEqual(this.testObj.pnumberPath, this.session_home);
            this.verifyEqual(this.testObj.pnumber,     'p8047');
            this.verifyEqual(this.testObj.fslPath,     fullfile( this.session_home, 'fsl', ''));
            this.verifyEqual(this.testObj.petPath,     fullfile( this.session_home, 'PET', ''));
            this.verifyEqual(this.testObj.scanPath,    fullfile( this.session_home, 'PET/scan1', ''));
            this.verifyEqual(this.testObj.procPath,    fullfile( this.session_home, 'jjl_proc', ''));
        end
        function test_save(this)            
            ca = mlio.TextIO.textfileToCell(this.tscFqfilename);
            this.verifyTrue(strcmp( ...
                'p8047g1.dta,  aparc_a2009s+aseg_mask_on_p8047gluc1_mcf.nii.gz, p8047gluc1_decayCorrect_masked.nii.gz, pie = 4.880000', ...
                strtrim(ca{1})));
            this.verifyTrue(strcmp('42,    3', strtrim(ca{2})));
            this.verifyTrue(strcmp('3258.9        180.0      972907.18', strtrim(ca{44})));
        end
        function test_makeMask(this)
            msk = this.testObj.makeMask(this.maskFqfilename);
            this.verifyTrue(strcmp('aparc_a2009s+aseg_mask_on_p8047gluc1_mcf', msk.fileprefix));
        end
        function test_times(this)
            this.verifyEqual(this.testObj.times(4),  138.933,  'RelTol', 1e-6);
            this.verifyEqual(this.testObj.times(43), 3438.933, 'RelTol', 1e-6);
        end
        function test_taus(this)
            this.verifyEqual(this.testObj.taus(4), 30);
            this.verifyEqual(this.testObj.taus(43), 180);
        end
        function test_scanDuration(this)
            this.verifyEqual(this.testObj.scanDuration, 3618.933);
        end
        function test_counts(this)
            this.verifyEqual(this.testObj.counts(4),   67523.585139833, 'RelTol', 1e-6);
            this.verifyEqual(this.testObj.counts(43), 955681.423487817, 'RelTol', 1e-6);
        end
        function test_header(this)
            this.verifyEqual(this.testObj.header.doseAdminTime, 18.9330);
            this.verifyEqual(this.testObj.header.string(1:14), 'rec p8047gluc1');
            this.verifyEqual(this.testObj.header.start(43), 3420);
            this.verifyEqual(this.testObj.header.duration(43), 180);
        end
    end

 	methods (TestClassSetup) 
 		function setupDTA(this) 
 		end 
    end

 	methods 		  
 		function this = Test_TSC(varargin) 
 			this = this@matlab.unittest.TestCase(varargin{:}); 
            
            this.pnumPath = fullfile(getenv('UNITTESTS'), 'Arbelaez/GluT/p8047_JJL', '');
            this.scanPath = fullfile(this.pnumPath, 'PET', 'scan1', '');
            this.procPath = fullfile(this.pnumPath, 'jjl_proc', '');
            this.tscFqfilename = fullfile(this.procPath, 'p8047wb1.tsc');
            this.dtaFqfilename = fullfile(this.procPath, 'p8047g1.dta');
            this.ecatFqfilename = fullfile(this.scanPath, 'p8047gluc1.nii.gz');
            cd(this.unittest_home);
 			this.testObj = mlpet.TSC.load( ...
                this.tscFqfilename, this.ecatFqfilename, this.dtaFqfilename, this.maskFqfilename, true); 
 		end 
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

