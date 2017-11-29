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
        fast = false
        hyglyNN = 'HYGLY34'
        pwd0
 		registry
 		testObj
        tic0
        view = false
        vnumber = 1
 	end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        
        function test_resolveModalitiesToTracer(this)
            modalitiesRB = this.testObj.resolveModalitiesToTracer;
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
        
        function test_locallyStageTracer(this)
            %  @return verify principal expected files from locallyStageTracer,
            %  combining expected files from prepareTracerLocation, prepaerListmodeMhdr & prepareMprToAtlasT4.
            
            this.testObj = this.testObj.locallyStageTracer;
            
            sessd = this.testObj.sessionData;
            bv    = this.testObj.buildVisitor;
            this.verifyTrue(isdir(sessd.tracerLocation)); % prepareTracerLocation
            this.verifyTrue(lexist(sessd.tracerListmodeMhdr)); % prepareListmodeMhdr
            this.verifyTrue(bv.lexist_4dfp(sessd.tracerListmodeSif('typ','fqfp'))); 
            this.verifyTrue(bv.lexist_4dfp(sessd.tracerListmodeMhdr('typ','fqfp')));
            this.verifyTrue(bv.lexist_4dfp(sessd.tracerSif('typ','fqfp')));
            this.verifyTrue(bv.lexist_4dfp(sessd.tracerRevision('typ','fqfp')));
            this.verifyTrue(lexist( ...
                fullfile(sessd.vLocation, ...
                sprintf('%s_to_%s_t4', sessd.mprage('typ','fp'), sessd.atlas('typ','fp'))))); % prepareMprToAtlasT4
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
                sprintf('%s/V%i/FDG_V%i-NAC/E8/fdgv%ie8r2_op_fdgv%ie8r1_frame8', ...
                this.pwd0, this.vnumber, this.vnumber, this.vnumber, this.vnumber));  
            
            this.verifyEqual(summed.product.fqfileprefix, ...
                sprintf('%s/V%i/FDG_V%i-NAC/E8/fdgv%ie8r2_op_fdgv%ie8r1_frame8_sumt', ...
                this.pwd0, this.vnumber, this.vnumber, this.vnumber, this.vnumber));  
            
            this.verifyEqual(this.testObj(9).product.fqfileprefix, ...
                sprintf('%s/V%i/FDG_V%i-NAC/E9/fdgv%ie9r1', ...
                this.pwd0, this.vnumber, this.vnumber, this.vnumber));                  
        end
        function test_motionCorrectFrames(this)
            this.testObj = this.testObj.partitionMonolith;
            [this.testObj,multiEpochOfSummed,reconstitutedSummed] = this.testObj.motionCorrectFrames;   
            
            this.verifyEqual(this.testObj(7).product.fqfileprefix, ...
                sprintf('%s/V%i/FDG_V%i-NAC/E7/fdgv%ie7r2_op_fdgv%ie7r1_frame8', ...
                this.pwd0, this.vnumber, this.vnumber, this.vnumber, this.vnumber));
            
            this.verifyEqual(multiEpochOfSummed(7).product.fqfileprefix, ...
                sprintf('%s/V%i/FDG_V%i-NAC/E7/fdgv%ie7r2_op_fdgv%ie7r1_frame8_sumt', ...
                this.pwd0, this.vnumber, this.vnumber, this.vnumber, this.vnumber));
            
            this.verifyEqual(reconstitutedSummed.product.fqfileprefix, ...
                sprintf('%s/V%i/FDG_V%i-NAC/E1to9/fdgv%ie1to9r2_op_fdgv%ie1to9r1_frame9_sumt', ...
                this.pwd0, this.vnumber, this.vnumber, this.vnumber, this.vnumber));
        end
        function test_motionCorrectModalities(this)
            this.testObj = this.testObj.partitionMonolith;
            [this.testObj,~,reconstitutedSummed] = this.testObj.motionCorrectFrames;  
            reconstitutedSummed = reconstitutedSummed.motionCorrectCTAndUmap;  
            
            this.verifyEqual(reconstitutedSummed.product.fqfileprefix, ...
                sprintf('%s/V%i/FDG_V%i-NAC/E1to9/umapSynth_op_fdgv%ie1to9r1_frame9', ...
                this.pwd0, this.vnumber, this.vnumber, this.vnumber));
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
            uncorrected = reconstitutedSummed.motionUncorrectToEpochs(umapOnFrame9, multiEpochOfSummed);
            this.verifyEqual( ...
                uncorrected(1).product.fqfilename, ...
                fullfile(this.pwd0, 'V1', 'FDG_V1-NAC', 'E1to9', ...
                sprintf('umapSynth_op_fdgv%ie1to9r1_frame1.4dfp.ifh', this.vnumber)));
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
            this.verifyEqual(uncorrected(1).product.fileprefix, ...
                sprintf('umapSynth_op_fdgv%ie1to9r1_frame1', this.vnumber));
            this.verifyEqual(uncorrected(8).product.fileprefix, ...
                sprintf('umapSynth_op_fdgv%ie1to9r1_frame8', this.vnumber));
        end
        function test_motionUncorrectUmapToEpochs(this)
            this.testObj   = this.testObj.partitionMonolith;
            this.testObj   = this.testObj.motionCorrectFrames;  
            this.testObj   = this.testObj.motionCorrectCTAndUmap;   
            prod = this.testObj.product;             
            
            this.testObj = this.testObj.setNeverTouch(true); 
            assert(~isempty(this.testObj.resolveBuilder), ...
                'ensure motionCorrectFrames has completed successfully');
            this.testObj.sessionData = this.testObj.resolveBuilder.sessionData;
            this.testObj             = this.testObj.motionUncorrectUmapToEpochs(prod);
            this.verifyEqual(this.testObj(8).product.fqfilename, ...
                fullfile(this.pwd0, 'V1', 'FDG_V1-NAC', 'E1to9', 'umapSynth_op_fdgv1e1to9r1_frame8.4dfp.ifh'));
        end
        function test_motionUncorrectUmapToFrames(this)
            this.testObj   = this.testObj.partitionMonolith;
            this.testObj   = this.testObj.motionCorrectFrames;  
            this.testObj   = this.testObj.motionCorrectCTAndUmap; 
            
            this.testObj = this.testObj.setNeverTouch(true);
            this.verifyEqual(this.testObj.product.fileprefix,    'umapSynth_op_fdgv1e1to9r1_frame9');
            this.testObj   = this.testObj.motionUncorrectUmapToFrames(this.testObj.product);
            this.verifyEqual(this.testObj(1).product.fileprefix, 'umapSynth_op_fdgv1e1to9r1_frame1');
            this.verifyEqual(this.testObj(8).product.fileprefix, 'umapSynth_op_fdgv1e1to9r1_frame8');
        end
        function test_motionUncorrectUmap(this)
            this.testObj = this.testObj.partitionMonolith;
            [this.testObj,multiEpochOfSummed,reconstitutedSummed] = this.testObj.motionCorrectFrames;  
            reconstitutedSummed = reconstitutedSummed.motionCorrectCTAndUmap;             
            reconstitutedSummed.motionUncorrectUmap(multiEpochOfSummed);
            
        end
	end

 	methods (TestClassSetup)
		function setupTracerResolveBuilder(this)
 			import mlraichle.*;
            studyd = StudyData;
            sessp  = fullfile(studyd.subjectsDir, this.hyglyNN, '');
            sessd  = SessionData('studyData', studyd, 'sessionPath', sessp, 'vnumber', this.vnumber);
 			this.testObj_ = mlpet.TracerResolveBuilder('sessionData', sessd, 'NRevisions', 2);
            this.pwd0 = pushd(sessp);
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

