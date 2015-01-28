classdef Test_PETAlignmentDirector < MyTestCase 
	%% TEST_PETALIGNMENTDIRECTOR  

	%  Usage:  >> runtests tests_dir  
	%          >> runtests mlpet.Test_PETAlignmentDirector % in . or the matlab path 
	%          >> runtests mlpet.Test_PETAlignmentDirector:test_nameoffunc 
	%          >> runtests(mlpet.Test_PETAlignmentDirector, Test_Class2, Test_Class3, ...) 
	%  See also:  package xunit 

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.1.0.604 (R2013a) 
 	%  $Id$ 
 	 
    properties
        pad
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

	methods 
 		% N.B. (Static, Abstract, Access='', Hidden, Sealed) 

        function test_alignSequentially(this)
            collec = { this.hocntxt this.trcntxt this.t1cntxt };
            collec = imcast(collec,'mlfourd.ImagingComposite');
            assertTrue( isa(collec, 'mlfourd.ImagingComposite'));
            prds = this.pad.alignSequentially(collec);
            assertTrue(isa(prds, 'mlfourd.ImagingContext'));
            prds = prds.imcomponent;
            for p = 1:length(prds)
                this.assertEntropies(this.E_sequen{p}, prds.get(p).fqfilename);
            end
        end
        function test_alignIndependently(this)
            collec = {this.trcntxt this.hocntxt};
            collec = imcast(collec,'mlfourd.ImagingComposite');
            assertTrue( isa(collec, 'mlfourd.ImagingComposite'));
            prds = this.pad.alignIndependently(collec, this.t1cntxt);
            assertTrue(isa(prds, 'mlfourd.ImagingContext'));
            prds = prds.imcomponent;
            for p = 1:length(prds)
                this.assertEntropies(this.E_indep{p}, prds.get(p).fqfilename);
            end
        end
 		function test_alignPair(this)
            prd = this.pad.alignPair(this.trcntxt, this.t1cntxt);
            assertTrue(isa(prd, 'mlfourd.ImagingContext'));
            this.assertEntropies(this.E_tront1, prd.fqfilename);
 		end 
 		function this = Test_PETAlignmentDirector(varargin) 
 			this = this@MyTestCase(varargin{:}); 
            this.pad = mlpet.PETAlignmentDirector( ...
                       mlfsl.AlignmentDirector( ...
                       mlpet.PETAlignmentBuilder));
        end 
        
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

