classdef Test_SessionResolveBuilder < matlab.unittest.TestCase
	%% TEST_SESSIONRESOLVEBUILDER 

	%  Usage:  >> results = run(mlpet_unittest.Test_SessionResolveBuilder)
 	%          >> result  = run(mlpet_unittest.Test_SessionResolveBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 07-May-2019 01:36:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.5.0.1067069 (R2018b) Update 4 for MACI64.  Copyright 2019 John Joowon Lee.
 	
	properties
        sesData
        sesFolder = 'ses-E182863' % HYGLY26
        studyData
        subData
        subFolder = 'sub-S40037'
 		testObj
        fast = false
 	end

	methods (Test)
        function test_alignCommonModal_ho(this)
            this.testObj = this.testObj.alignCommonModal('HO');
            this.testObj.view;
        end
        function test_alignCommonModal_oo(this)
            if (this.fast); return; end
            this.testObj = this.testObj.alignCommonModal('OO');
            this.testObj.view;
        end
        function test_alignCommonModal_oc(this)
            if (this.fast); return; end
            this.testObj = this.testObj.alignCommonModal('OC');
            this.testObj.view;
        end
        function test_alignCrossModal(this)
            this.assertTrue(strcmpi(this.testObj.referenceTracer, 'FDG'));
            this.testObj = this.testObj.alignCrossModal;
            this.testObj.view;
            cellfun(@(p) p.view, this.testObj.product, 'UniformOutput', false);
        end
        function test_alignCrossModalSubset(this)
            this.testObj = this.testObj.alignCrossModalSubset;
            this.testObj.view;         
        end
        function test_alignDynamicImages(this)
            this.testObj = this.testObj.alignCrossModalSubset;      
            this.testObj = this.testObj.alignDynamicImages;
            this.testObj.view;
        end
        function test_alignFrameGroups(this)
            this.testObj.alignFrameGroups('FDG', 1:8, 9:73);
            disp(this.testObj.compositeRB.t4_resolve_err); % [NaN 0.140159562550168;0.140159562550168 NaN]
        end
        function test_alignOpT1001(this)
            return
            imgsSumt = reshape(this.testObj.sourceImages('FDG', true), 1, []);
            this.testObj.product = imgsSumt;
            this.testObj = this.testObj.alignOpT1001;
            this.testObj.view;
        end  
        
        
        
        
        function test_constructFramesSubset(this) % effective tests resolve
            this.testObj = this.testObj.constructFramesSubset('FDG', 1:8);
            this.testObj.view;
        end
        function test_productAverage(this)
            this.testObj = this.testObj.alignCommonModal('FDG'); % this.testObj contains necessary tracer information
            this.testObj = this.testObj.productAverage;
            this.testObj.view;
        end
        function test_sourceImages(this)
            imgs = this.testObj.sourceImages('FDG', true);
            this.verifyEqual(imgs{1}, fullfile(this.sesData.vallLocation,'fdgv1r1_sumt'));
            this.verifyEqual(imgs{2}, fullfile(this.sesData.vallLocation,'fdgv2r1_sumt'));
            %disp(imgs)
            
            imgs = this.testObj.sourceImages('FDG');
            this.verifyEqual(imgs{1}, fullfile(this.sesData.vallLocation, 'fdgv1r1'));
            this.verifyEqual(imgs{2}, fullfile(this.sesData.vallLocation, 'fdgv2r1'));
            %disp(imgs)
        end 
        
        
        
        
	end

 	methods (TestClassSetup)
		function setupSessionResolveBuilder(this)
 			import mlraichle.*;
            setenv('PROJECTS_DIR', '/scratch/jjlee/Singularity');
            setenv('SUBJECTS_DIR', '/scratch/jjlee/Singularity/subjects');
            this.studyData = StudyData();
            this.subData = SubjectData('subjectFolder', this.subFolder);
            this.sesData = SessionData( ...
                'studyData', this.studyData, ...
                'subjectData', this.subData, ...
                'sessionFolder', this.sesFolder, ...
                'tracer', 'FDG', 'ac', true); % referenceTracer
 			this.testObj_ = mlpet.SessionResolveBuilder('sessionData', this.sesData);
 			this.addTeardown(@this.cleanFolders);
 		end
	end

 	methods (TestMethodSetup)
		function setupSessionResolveBuilderTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
            cd(fullfile(this.subData.subjectPath, this.sesData.sessionFolder));
 		end
	end

    %% PRIVATE
    
	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
        function cleanTestMethod(this)
        end
		function cleanFiles(this)
 		end
		function cleanFolders(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end
