classdef Test_TracerResolveBuilder < matlab.unittest.TestCase
	%% TEST_TRACERRESOLVEBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_TracerResolveBuilder)
 	%          >> result  = run(mlpet_unittest.Test_TracerResolveBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 18-Aug-2017 13:57:22 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
        ac = true
        fast = false
        hyglyNN = 'HYGLY09'
        pwd0
 		registry
        sessd
        sessp
        studyd
 		testObj
        tic0
        view = false
 	end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end        
        function test_locallyStageTracer(this)
            %  @return verify principal expected files from locallyStageTracer,
            %  combining expected files from prepareTracerLocation, prepaerListmodeMhdr & prepareMprToAtlasT4.
            
            this.testObj = this.testObj.locallyStageTracer;
            
            sd = this.testObj.sessionData;
            bv = this.testObj.buildVisitor;
            this.verifyTrue(isdir(sd.tracerLocation)); % prepareTracerLocation
            this.verifyTrue(lexist(sd.tracerListmodeMhdr)); % prepareListmodeMhdr
            this.verifyTrue(bv.lexist_4dfp(sd.tracerListmodeSif('typ','fqfp'))); 
            this.verifyTrue(bv.lexist_4dfp(sd.tracerListmodeMhdr('typ','fqfp')));
            this.verifyTrue(bv.lexist_4dfp(sd.tracerSif('typ','fqfp')));
            this.verifyTrue(bv.lexist_4dfp(sd.tracerRevision('typ','fqfp')));
            this.verifyTrue(lexist( ...
                fullfile(sd.sessionPath, ...
                sprintf('%s_to_%s_t4', sd.mprage('typ','fp'), sd.atlas('typ','fp'))))); % prepareMprToAtlasT4
            if (this.view)
                this.testObj.product.view;
            end 
        end
        function test_partitionMonolith(this)
            this.testObj = this.testObj.partitionMonolith;
            fprintf('test_partitionMonolith.s(4):\t');
            for idx = 1:length(this.testObj)
                this.verifyEqual(this.testObj(idx).sessionData.epoch, idx);
                p = this.testObj(idx).product;
                f = p.fourdfp;
                if (f.rank > 3)
                    s = f.size;
                    fprintf('%i\t', s(4));
                    this.verifyTrue(s(4) <= this.testObj(idx).MAX_LENGTH_EPOCH);
                else
                    fprintf('[]\t');
                end
                if (this.view)
                    p.view;
                end
            end
            fprintf('\n');
        end
        function test_motionCorrectEpochs(this)
            this.testObj             = this.testObj.partitionMonolith;            
            [this.testObj(8),summed] = this.testObj(8).motionCorrectEpochs;            
            this.testObj(9)          = this.testObj(9).motionCorrectEpochs;
                         
            this.verifyEqual(this.testObj(8).product.fqfileprefix, ...
                sprintf('%s/NAC/E8/fdge8r2_op_fdge8r1_frame8', this.pwd0));  
            
            this.verifyEqual(summed.product.fqfileprefix, ...
                sprintf('%s/FDG-NAC/E8/fdge8r2_op_fdge8r1_frame8_sumt', this.pwd0));  
            
            this.verifyEqual(this.testObj(9).product.fqfileprefix, ...
                sprintf('%s/FDG-NAC/E9/fdge9r1', this.pwd0));                  
        end
        function test_motionCorrectFrames(this)
            this.testObj = this.testObj.partitionMonolith;
            [this.testObj,multiEpochOfSummed,reconstitutedSummed] = this.testObj.motionCorrectFrames;   
            
            this.verifyEqual(this.testObj(7).product.fqfileprefix, ...
                sprintf('%s/FDG-NAC/E7/fdge7r2_op_fdge7r1_frame8', this.pwd0));
            
            this.verifyEqual(multiEpochOfSummed(7).product.fqfileprefix, ...
                sprintf('%s/FDG-NAC/E7/fdge7r2_op_fdge7r1_frame8_sumt', this.pwd0));
            
            this.verifyEqual(reconstitutedSummed.product.fqfileprefix, ...
                sprintf('%s/FDG-NAC/E1to9/fdge1to9r2_op_fdge1to9r1_frame9_sumt', this.pwd0));
        end
        function test_motionCorrectModalities(this)
            this.testObj = this.testObj.partitionMonolith;
            [this.testObj,~,reconstitutedSummed] = this.testObj.motionCorrectFrames;  
            reconstitutedSummed = reconstitutedSummed.motionCorrectCTAndUmap;  
            
            this.verifyEqual(reconstitutedSummed.product.fqfileprefix, ...
                sprintf('%s/FDG-NAC/E1to9/umapSynth_op_fdge1to9r1_frame9', this.pwd0));
        end
        function test_motionUncorrectToEpochs(this)
            this.testObj = this.testObj.partitionMonolith;
            [this.testObj,multiEpochOfSummed,reconstitutedSummed] = this.testObj.motionCorrectFrames;  
            reconstitutedSummed = reconstitutedSummed.motionCorrectCTAndUmap;  
            umapOnFrame9 = reconstitutedSummed.product;             
            
            reconstitutedSummed = reconstitutedSummed.setNeverTouch(true);  
            for c = 1:length(multiEpochOfSummed)
                multiEpochOfSummed(c) = multiEpochOfSummed(c).setNeverTouch(true);
            end
            uncorrected = reconstitutedSummed.motionUncorrectEpoch1ToN(umapOnFrame9, multiEpochOfSummed);
            this.verifyEqual( ...
                uncorrected(1).product.fqfilename, ...
                fullfile(this.pwd0, 'V1', 'FDG_V1-NAC', 'E1to9', 'umapSynth_op_fdge1to9r1_frame1.4dfp.hdr'));
        end
        function test_motionUncorrectToFrames(this)
            this.testObj = this.testObj.partitionMonolith;
            [this.testObj,multiEpochOfSummed,reconstitutedSummed] = this.testObj.motionCorrectFrames;  
            reconstitutedSummed = reconstitutedSummed.motionCorrectCTAndUmap;  
            umapOnFrame9 =reconstitutedSummed.product;       
               
            reconstitutedSummed = reconstitutedSummed.setNeverTouch(true);
            for c = 1:length(multiEpochOfSummed)
                multiEpochOfSummed(c) = multiEpochOfSummed(c).setNeverTouch(true);
            end            
            uncorrected = reconstitutedSummed.motionUncorrectToFrames(umapOnFrame9, multiEpochOfSummed);
            this.verifyEqual(uncorrected(1).product.fileprefix, 'umapSynth_op_fdge1to9r1_frame1');
            this.verifyEqual(uncorrected(8).product.fileprefix, 'umapSynth_op_fdge1to9r1_frame8');
        end
        function test_motionUncorrectUmap(this)
            this.testObj = this.testObj.partitionMonolith;
            [this.testObj,multiEpochOfSummed,reconstitutedSummed] = this.testObj.motionCorrectFrames;  
            reconstitutedSummed = reconstitutedSummed.motionCorrectCTAndUmap;             
            reconstitutedSummed.motionUncorrectUmap(multiEpochOfSummed);
            
        end        
        function test_resolveModalitiesToProduct(this)
            modalitiesRB = this.testObj.resolveModalitiesToProduct;
            this.verifyClass(modalitiesRB, 'mlpet.TracerResolveBuilder');
            for m = 1:length(modalitiesRB)                
                this.verifyClass(modalitiesRB(m).product, 'mlfourd.ImagingContext');
                modalitiesRB(m).product.view;
            end
        end
        function test_RoisToTracerSumt(this)
            roisRB = this.testObj.roisToTracerSumt;
            this.verifyClass(roisRB, 'mlpet.TracerResolveBuilder');
            for m = 1:length(roisRB)                
                this.verifyClass(roisRB(m).product, 'mlfourd.ImagingContext');
                roisRB(m).product.view;
            end
        end
        function test_reconstituteFramesAC2(this)
            
            mlraichle.TracerDirector.prepareFreesurferData('sessionData', this.sessd);  
            
            this.testObj = this.testObj.reconstituteFramesAC;
            this.testObj.sessionData.frame = nan;
            this.testObj.sessionData.frame = nan;
            this.testObj = this.testObj.partitionMonolith;
            this.testObj = this.testObj.motionCorrectFrames;            
            this.testObj = this.testObj.reconstituteFramesAC2;
            this.testObj.product.view;
            ic = this.testObj.sessionData.tracerResolvedFinal('typ', 'mlfourd.ImagingContext');
            ic.view;
        end
	end

 	methods (TestClassSetup)
		function setupTracerResolveBuilder(this)
 			import mlraichle.*;
            this.studyd = StudyData;
            this.sessp  = fullfile(this.studyd.subjectsDir, this.hyglyNN, '');
            this.pwd0 = pushd(this.sessp);
            this.sessd  = SessionData('studyData', this.studyd, 'sessionPath', this.sessp, 'ac', this.ac);
 			this.testObj_ = mlpet.TracerResolveBuilder('sessionData', this.sessd, 'NRevisions', 2);
            
 			this.addTeardown(@this.cleanClassFiles);
 		end
	end

 	methods (TestMethodSetup)
		function setupTracerResolveBuilderTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanMethodFiles);
            this.tic0 = tic;
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanClassFiles(this)
            cd(this.pwd0);
            datestr(now)
 		end
		function cleanMethodFiles(this)
            toc(this.tic0);
 		end
        function verifyTestObjProduct(this)
            this.verifyClass(this.testObj.product, 'mlfourd.ImagingContext');
            if (this.view)
                this.testObj.product.view;
            end
        end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

