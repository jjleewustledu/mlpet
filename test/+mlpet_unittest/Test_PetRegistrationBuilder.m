classdef Test_PetRegistrationBuilder < matlab.unittest.TestCase
	%% TEST_PETREGISTRATIONBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_PETRegistrationBuilder)
 	%          >> result  = run(mlpet_unittest.Test_PETRegistrationBuilder, 'test_dt')
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
        
        view = false
 	end

	methods (Test)
        function test_motionCorrect(this)
            this.prb.sourceImage = this.sessionData.ho_fqfn;
            this.prb             = this.prb.motionCorrect;
            prod                 = this.prb.product;
            this.verifyIC(prod, 0.999299145941652, 129.242584883662, 'p7686ho1_mcf')
            if (this.view)
                prod.view(this.prb.sourceImage);
            end
        end
        function test_register3D(this)
            this.prb.sourceImage    = this.sessionData.oc_fqfn;
            this.prb.referenceImage = this.sessionData.tr_fqfn;
            this.prb                = this.prb.register;
            prod                    = this.prb.product;
            this.verifyIC(prod, 311.750926696265, 311.750926696265, 'p7686oc1_03_on_p7686tr1_01_919110fwhh')
            if (this.view)
                prod.view(this.prb.referenceImage);
            end
        end
        function test_register4D(this)
            this.prb.sourceImage    = this.sessionData.ho_fqfn;
            this.prb.referenceImage = this.sessionData.oo_fqfn;
            this.prb                = this.prb.register;
            prod                    = this.prb.product;
            this.verifyIC(prod, 0.998408516526418, 115.459062565271, 'p7686ho1_on_p7686oo1_sumt_919110fwhh')
            if (this.view)
                prod.view(this.prb.referenceImage);
            end
        end
        function test_information(this)
        end
        
         function test_alignSequentially(this)
%             collec = { this.hocntxt this.trcntxt this.t1cntxt };
%             prds = this.prb.alignSequentially(collec);
%             prds = prds.composite;
%             for p = 1:length(prds)
%                 this.assertEntropies(this.E_sequen{p}, prds.get(p).fqfilename);
%             end
        end
	end

 	methods (TestClassSetup)
		function setupPetRegistrationBuilder(this)
 			import mlpet.*;
            this.registry = mlsiemens.ECATRegistry.instance('initialize');
            this.studyData = this.registry.testStudyData('test_derdeyn');
            this.sessionData = this.registry.testSessionData('test_derdeyn'); 
            disp(this.sessionData);
 			this.prb_ = PETRegistrationBuilder('sessionData', this.sessionData);
 		end
	end

 	methods (TestMethodSetup)
		function setupPetRegistrationBuilderTest(this)
 			this.prb = this.prb_;
            this.addTeardown(@this.cleanupFiles);
 		end
    end
    
    %% PRIVATE

	properties (Access = private)
 		prb_
    end
    
    methods (Access = private)
        function cleanupFiles(this)
            deleteExisting(this.prb.sourceWeight);
            deleteExisting(this.prb.referenceWeight);
            %deleteExisting(this.prb.sourceImage.ones);
            %deleteExisting(this.prb.referenceImage.ones);
            %deleteExisting(this.prb.sourceImage); % blurred, not orig
            %deleteExisting(this.prb.referenceImage); % blurred, not orig
        end
        function verifyIC(this, ic, e, m, fp)
            this.assumeInstanceOf(ic, 'mlfourd.ImagingContext');
            this.verifyEqual(ic.niftid.entropy, e, 'RelTol', 1e-6);
            this.verifyEqual(dipmad(ic.niftid.img), m, 'RelTol', 1e-4);
            this.verifyEqual(ic.fileprefix, fp); 
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

