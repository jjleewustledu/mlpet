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
        pnumPath 
        procPath
        tscFqfilename 
        testObj
 	end 

	methods (Test) 
 		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        function test_ctor(this)
        end
        function test_injectionTime(this)
        end
        function test_petGluc_decayCorrect(this)
        end
        function test_gluTxlsx(this)
        end
        function test_mask(this)
        end
        function test_scanDuration(this)
        end
        function test_times(this)
        end
        function test_timeInterpolants(this)
        end
        function test_dtaDuration(this)
        end
        function test_fqFilenames(this)
        end
        function test_taus(this)
        end
        function test_counts(this)
        end
        function test_countInterpolants(this)
        end
        function test_header(this)
        end
        function test_headerString(this)
        end
        function test_length(this)
        end
        function test_printTsc(this)
            this.testObj.printTsc(this.tscFqfilename, 'Test_TSC.test_printTsc');   
            ca = mlio.TextIO.textfileToCell(this.tscFqfilename);
            this.assertTrue(strcmp('', ca{1}));
            this.assertTrue(strcmp('    43,    3', ca{2}));
            this.assertTrue(strcmp('      3258.9        180.0      727936.19', ca{45}));
        end
 	end 

 	methods (TestClassSetup) 
 		function setupDTA(this) 
            this.pnumPath = '/Volumes/InnominateHD2/Local/test/Arbelaez/GluT/p8047_JJL';
            this.procPath = fullfile(this.pnumPath, 'jjl_proc', '');
            this.tscFqfilename = fullfile(this.procPath, 'p8047wb1.tsc');
            cd(this.pnumPath);
 			this.testObj = mlpet.TSC('p8047wb1', this.pnumpath); 
 		end 
    end 
    
 	methods 		  
 		function this = Test_TSC(varargin) 
 			this = this@matlab.unittest.TestCase(varargin{:}); 
 		end 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

