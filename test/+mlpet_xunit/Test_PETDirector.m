classdef Test_PETDirector < mlfsl_xunit.Test_mlfsl
	%% TEST_PETDIRECTOR 
	%  Usage:  >> runtests tests_dir  
 	%          >> runtests Test_PETDirector % in . or the matlab path 
 	%          >> runtests Test_PETDirector:test_nameoffunc 
 	%          >> runtests(Test_PETDirector, Test_Class2, Test_Class3, ...) 
 	%  See also:  package xunit	%  Version $Revision: 2471 $ was created $Date: 2013-08-10 21:36:24 -0500 (Sat, 10 Aug 2013) $ by $Author: jjlee $,  
 	%  last modified $LastChangedDate: 2013-08-10 21:36:24 -0500 (Sat, 10 Aug 2013) $ and checked into svn repository $URL: file:///Users/jjlee/Library/SVNRepository_2012sep1/mpackages/mlfsl/test/+mlfsl_xunit/trunk/Test_PETDirector.m $ 
 	%  Developed on Matlab 7.13.0.564 (R2011b) 
 	%  $Id: Test_PETDirector.m 2471 2013-08-11 02:36:24Z jjlee $ 
 	%  N.B. classdef (Sealed, Hidden, InferiorClasses = {?class1,?class2}, ConstructOnLoad) 

    properties (Constant)
        TEST_FILENAME      = 'testingPETDirector.tst';
        WORKSPACE_FILENAME = 'testingPETDirector.mat';
    end

    properties (Dependent)
        testFilename
        workspaceFilename
    end
    
	methods %% GET
        function fn = get.testFilename(this)
            fn = fullfile(this.fslPath, this.TEST_FILENAME);
        end
        function fn = get.workspaceFilename(this)
            fn = fullfile(this.sessionPath, this.WORKSPACE_FILENAME);
        end
    end
    
    methods
        function test_visualizeIntermediates(this)
            s = this.director.petBash('');
            assert(0 == s);
        end
        function test_deconvolve(this)
        end
        function test_filter(this)
        end
        function test_unpack(this)
        end
        
        function test_coregister2Mr(this)
            this.director.coregister();            
            assertElementsAlmostEqual(this.expected_oc_on_t1.img,    this.director.products.c15o.img);
            assertElementsAlmostEqual(this.expected_oosum_on_t1.img, this.director.products.o15oMean.img);
            assertElementsAlmostEqual(this.expected_hosum_on_t1.img, this.director.products.h15oMean.img);
            assertElementsAlmostEqual(this.expected_tr_on_t1.img,    this.director.products.tr.img);
        end
        function test_coregister2Pet(this)
            this.director.coregister();
            assertElementsAlmostEqual(this.oc_on_tr.img,     this.director.products.c15o.img);
            assertElementsAlmostEqual(this.oosum_on_tr.img,  this.director.products.o15oMean.img);
            assertElementsAlmostEqual(this.hoosum_on_tr.img, this.director.products.h15oMean.img);
        end
        function test_ctor(this)
            assertTrue(isa(this.director, 'mlpet.PETDirector'));
            assertTrue(isa(this.builder,  'mlpet.PETBuilder'));
        end
        
 		function this = Test_PETDirector(varargin) 
 			this = this@mlfsl_xunit.Test_mlfsl(varargin{:});
            import mlfsl.* mlpet.*;
            this.builder     = PETBuilder.createFromModalityPath(this.petPath);
            this.director    = PETDirector.createFromBuilder(this.builder);
            load(this.workspaceFilename);
            this.expected_oc_on_tr    = oc_on_tr;
            this.expected_oosum_on_tr = oosum_on_tr;
            this.expected_hosum_on_tr = hosum_on_tr;
            this.expected_oc_on_t1    = oc_on_t1;
            this.expected_oosum_on_t1 = oosum_on_t1;
            this.expected_hosum_on_t1 = hosum_on_t1;
        end
    end
    
    %% PROTECTED
            
	properties (Access = 'protected')
        builder
        director
        expected_oc_on_tr
        expected_oo_on_hosum
        expected_oc_on_t1
        expected_oo_on_t1
        expected_ho_on_t1
        regions
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end
