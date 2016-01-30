classdef Test_PetRegistrationBuilder < matlab.unittest.TestCase
	%% TEST_PETREGISTRATIONBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_PetRegistrationBuilder)
 	%          >> result  = run(mlpet_unittest.Test_PetRegistrationBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 27-Jan-2016 00:59:46
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties
 		registry
        studyData
        sessionData
 		prb
        
        view = true
 	end

	methods (Test)
        function test_motionCorrect(this)
            mcho = this.prb.motionCorrect(this.prb.ho);
            if (this.view)
                mcho.freeview(this.prb.ho);
            end
        end
        function test_registerBijective(this)
        end
        function test_information(this)
        end
        
        function test_alignSequentially(this)
            collec = { this.hocntxt this.trcntxt this.t1cntxt };
            prds = this.prb.alignSequentially(collec);
            prds = prds.composite;
            for p = 1:length(prds)
                this.assertEntropies(this.E_sequen{p}, prds.get(p).fqfilename);
            end
        end
        function test_alignIndependently(this)
            collec = {this.trcntxt this.hocntxt};
            prds = this.prb.alignIndependently(collec, this.t1cntxt);
            prds = prds.composite;
            for p = 1:length(prds)
                this.assertEntropies(this.E_indep{p}, prds.get(p).fqfilename);
            end
        end
 		function test_alignPair(this)
            prd = this.prb.alignPair(this.trcntxt, this.t1cntxt);
            this.assertEntropies(this.E_tront1, prd.fqfilename);
 		end 
	end

 	methods (TestClassSetup)
		function setupPetRegistrationBuilder(this)
 			import mlpet.*;
            this.registry = PETRegistry;
            this.studyData = mlpipeline.StudyDataSingletons.instance('derdeyn');
            iter = this.studyData.createIteratorForSessionData;
            this.sessionData = iter.next;
 			this.prb_ = PetRegistrationBuilder(this.sessionData);
 		end
	end

 	methods (TestMethodSetup)
		function setupPetRegistrationBuilderTest(this)
 			this.prb = this.prb_;
 		end
	end

	properties (Access = 'private')
 		prb_
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

