classdef Test_O15Director < matlab.unittest.TestCase
	%% TEST_O15DIRECTOR 

	%  Usage:  >> results = run(mlpet_unittest.Test_O15Director)
 	%          >> result  = run(mlpet_unittest.Test_O15Director, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 16-Oct-2015 09:36:10
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties
 		registry
        ocObj
 	end

	methods (Test)
        function test_vFrac(this)
            this.assertEqual(this.ocObj.vFrac, 0.0845101543763304, 'RelTol', 1e-4);
        end
 		function test_loadOC(this)
 			import mlpet.*;
            this.assertTrue(isa(this.ocObj, 'mlpet.O15Director'));
 		end
 	end

 	methods (TestClassSetup)
 		function setupO15Director(this)
 		end
 	end

 	methods (TestClassTeardown)
    end
    
    methods 
        function this = Test_O15Director(varargin)
            this = this@matlab.unittest.TestCase(varargin{:});
 			this.registry = mlarbelaez.UnittestRegistry.instance;
            this.ocObj = mlpet.O15Director.load( ...
                this.registry.ocFqfilename, ...
                'Hdrinfo', this.registry.ocHdrinfoFqfilename, ...
                'Mask', this.registry.ocMaskFqfilename);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

