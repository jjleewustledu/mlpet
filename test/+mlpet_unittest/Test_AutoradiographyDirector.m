classdef Test_AutoradiographyDirector < matlab.unittest.TestCase 
	%% TEST_AUTORADIOGRAPHYDIRECTOR  

	%  Usage:  >> results = run(mlpet_unittest.Test_AutoradiographyDirector)
 	%          >> result  = run(mlpet_unittest.Test_AutoradiographyDirector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 

	properties 
        testObj
        testObj2
        testObj3
        
        workPath  = '/Volumes/SeagateBP4/cvl/np755/mm01-007_p7267_2008jun16/bayesian_pet'
        pie       = 5.2038;
        dcvShift  = -16 %-18
        dscShift  = -16 %-18
        ecatShift = 0 %-6
        
        % whole-brain CBF = 56.417 mL/100g/min on vidi, 40% uthresh
        %                 = 0.00987298 1/s        
        %              af = 2.035279E-06 from metcalc
        %              bf = 2.096733E-02 
        % estimated    A0 = 0.290615
    end 
    
    properties (Dependent)
        dscMaskFn
        dscFn
        aifFn
        maskFn
        ecatFn
        recFn
        recFn0
    end
    
    methods % GET
        function fn = get.dscMaskFn(this)
            fn = fullfile(this.workPath, 'ep2d_mask.nii.gz');
        end
        function fn = get.dscFn(this)
            fn = fullfile(this.workPath, 'ep2d_default_mcf.nii.gz');
        end
        function fn = get.aifFn(this)
            fn = fullfile(this.workPath, 'p7267ho1.dcv');
        end
        function fn = get.maskFn(this)
            fn = fullfile(this.workPath, 'aparc_a2009s+aseg_mask_on_p7267tr1.nii.gz');
        end
        function fn = get.ecatFn(this)
            fn = fullfile(this.workPath, 'p7267ho1_161616fwhh_masked.nii.gz');
        end
        function fn = get.recFn(this)
            fn = fullfile(this.workPath, 'p7267ho1_161616fwhh_masked.img.rec');
        end
        function fn = get.recFn0(this)
            fn = fullfile(this.workPath, 'p7267ho1.img.rec');
        end
    end

	methods (Test) 
 		function test_plotInitialData(this)
            this.testObj.plotInitialData;
 		end 
 		function test_plotInitialData2(this)
            this.testObj2.plotInitialData;
 		end 
 		function test_plotParVars(this)
            this.testObj.plotParVars('A0', [0.05 0.06 0.07 0.08 0.09 0.1 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.2]);
            this.testObj.plotParVars('PS', [0.01 0.02 0.03 0.04 0.05]);
            this.testObj.plotParVars('f',  [0.002 0.004 0.005 0.006 0.007 0.008 0.009 0.01 0.015 0.02]);
            this.testObj.plotParVars('t0', [0 1 2 4 8 16 32]);
        end 
        function test_plotParVars2(this)
            this.testObj2.plotParVars('A0', [0.05 0.06 0.07 0.08 0.09 0.1 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.2]);
            this.testObj2.plotParVars('PS', [0.0001 0.001 0.01 0.02 0.03 0.04 0.05]);
            this.testObj2.plotParVars('a',  [0.0001 0.001 0.01 0.05 0.1 0.5 1 2 4 8 16]);
            this.testObj2.plotParVars('d',  [0.01 0.05 0.1 0.2 0.4 0.8 0.9 1 1.1 1.2 1.4 1.6 1.8 2 3 4 8]);
            this.testObj2.plotParVars('f',  [0.002 0.004 0.005 0.006 0.007 0.008 0.009 0.01 0.015 0.02]);
            this.testObj2.plotParVars('p',  [0.25 0.5 0.9 0.95 1 1.05 1.1 1.15 1.2 1.3 1.4 1.5 2 3 4]);
            this.testObj2.plotParVars('q0', [1.25 2.5 5 10]*1e6);
            this.testObj2.plotParVars('t0', [0 1 2 4 8 16 32]);
        end
        function test_simulateItsMcmc(this)
            this.testObj.simulateItsMcmc;
        end
        function test_simulateItsMcmc2(this)
            this.testObj2.simulateItsMcmc;
        end
        function test_simulateItsMcmc3(this)
            this.testObj3.simulateItsMcmc;
        end
        function test_runItsAutoradiography(this)
            this.testObj = this.testObj.runItsAutoradiography;
        end
        function test_runItsAutoradiography2(this)
            this.testObj2 = this.testObj2.runItsAutoradiography;
        end
        function test_estimateAll3(this)
            this.testObj3 = this.testObj3.estimateAll;
        end
 	end 

    methods 
        function this = Test_AutoradiographyDirector
            this = this@matlab.unittest.TestCase;
            
            pushd(this.workPath);
            if (~lexist(this.recFn, 'file'))
                mlbash(sprintf('cp %s %s', this.recFn0, this.recFn)); end
            
%  			this.testObj  = mlpet.AutoradiographyDirector.loadPET( ...
%                             this.maskFn, this.aifFn, this.ecatFn, this.dcvShift, this.ecatShift);
%  			this.testObj2 = mlpet.AutoradiographyDirector.loadDSC( ...
%                             this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn, this.dscShift, this.ecatShift);
 			this.testObj3 = mlpet.AutoradiographyDirector.loadVideen( ...
                            this.maskFn, this.aifFn, this.ecatFn, this.dcvShift, this.ecatShift);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

