classdef Test_PETAlignmentDirector < mlfourd_unittest.Test_mlfourd
	%% TEST_PETALIGNMENTDIRECTOR 

	%  Usage:  >> results = run(mlpet_unittest.Test_PETAlignmentDirector)
 	%          >> result  = run(mlpet_unittest.Test_PETAlignmentDirector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 20-Oct-2015 21:20:11
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    properties
 		registry
 		testObj
        E_tront1 =   6.694364224452558;
        E_indep  = { 6.694364224452558 5.709784314637426 };
        E_sequen = { 5.690692780630012 6.694364224452558 4.318537132583254 }
 	end

	properties (Dependent)
 		 t1cntxt
         t2cntxt
         trcntxt
         hocntxt
         oocntxt
         occntxt
    end 
    
    methods %% GET
        function ic = get.t1cntxt(this)
            ic = mlfourd.ImagingContext.load(this.t1_fqfn);
        end
        function ic = get.t2cntxt(this)
            ic = mlfourd.ImagingContext.load(this.t2_fqfn);
        end
        function ic = get.trcntxt(this)
            ic = mlfourd.ImagingContext.load(this.tr_fqfn);
        end
        function ic = get.hocntxt(this)
            ic = mlfourd.ImagingContext.load(this.ho_fqfn);
        end
        function ic = get.oocntxt(this)
            ic = mlfourd.ImagingContext.load(this.oo_fqfn);
        end
        function ic = get.occntxt(this)
            ic = mlfourd.ImagingContext.load(this.oc_fqfn);
        end
    end
    
	methods (Test) 		
        function test_alignSequentially(this)
            collec = { this.hocntxt this.trcntxt this.t1cntxt };
            collec = imcast(collec,'mlfourd.ImagingComposite');
            this.verifyClass(collec, 'mlfourd.ImagingComposite');
            prds = this.testObj.alignSequentially(collec);
            this.verifyClass(prds, 'mlfourd.ImagingContext');
            prds = prds.imcomponent;
            for p = 1:length(prds)
                this.assertEntropies(this.E_sequen{p}, prds.get(p).fqfilename);
            end
        end
        function test_alignIndependently(this)
            collec = {this.trcntxt this.hocntxt};
            collec = imcast(collec,'mlfourd.ImagingComposite');
            this.verifyClass(collec, 'mlfourd.ImagingComposite');
            prds = this.testObj.alignIndependently(collec, this.t1cntxt);
            this.verifyClass(prds, 'mlfourd.ImagingContext');
            prds = prds.imcomponent;
            for p = 1:length(prds)
                this.assertEntropies(this.E_indep{p}, prds.get(p).fqfilename);
            end
        end
 		function test_alignPair(this)
            prd = this.testObj.alignPair(this.trcntxt, this.t1cntxt);
            this.verifyClass(prd, 'mlfourd.ImagingContext');
            this.assertEntropies(this.E_tront1, prd.fqfilename);
 		end 
 	end

 	methods (TestClassSetup)
 		function setupPETAlignmentDirector(this)
 			import mlpet.*; 			
            this.testObj = mlpet.PETAlignmentDirector( ...
                           mlfsl.AlignmentDirector( ...
                           mlpet.PETAlignmentBuilder));
 		end
 	end

 	methods (TestMethodSetup)
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

