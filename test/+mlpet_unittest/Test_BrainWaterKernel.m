classdef Test_BrainWaterKernel < matlab.unittest.TestCase 
	%% TEST_BRAINWATERKERNEL  

	%  Usage:  >> results = run(mlpet_unittest.Test_BrainWaterKernel)
 	%          >> result  = run(mlpet_unittest.Test_BrainWaterKernel, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 

	properties 
        testDcv
 		testObj        
        a  = 8.5
        d  = 5.4
        p  = 1.1
        q0 = 1
        t0 = 0
        testFolder   = '/Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest'
        dscFilename  = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/perfusion_4dfp/ep2d_default_mcf.nii.gz'
        maskFilename = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/perfusion_4dfp/perfMask.nii.gz'
        dcvFilename  = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/ECAT_EXACT/pet/p7267ho1.dcv'
        
 	end 

    properties (Dependent)
        expectedBestFitParams
        times
        inputFunction
    end
    
    methods %% GET/SET
        function e = get.expectedBestFitParams(this)
            e = [this.a this.d this.p this.q0 this.t0]';
        end
        function t = get.times(this)
            t = this.wbDsc.timeInterpolants;
        end
        function f = get.inputFunction(this)
            f = this.wbDsc.concInterpolants;
        end
    end
    
	methods (Test) 
 		function test_plotAs(this)
            figure
            hold on
            a_ = [1 2 4 8 16 32];
            for idx = 1:length(a_)
                plot(this.times, ...
                     mlpet.BrainWaterKernel.simulateDcv(this.inputFunction, a_(idx), this.d, this.p, this.q0, this.t0, this.times));
            end
            title(sprintf('a->var, d->%g, p->%g, q0->%g, t0->%g',                    this.d, this.p, this.q0, this.t0));
            legend(cellfun(@(x) sprintf('a = %g', x), num2cell(a_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('arbitrary');
 		end 
 		function test_plotDs(this)
            figure
            hold on            
            d_ = [1 2 3 4 5 6 7 8 9];
            for idx = 1:length(d_)
                plot(this.times, ...
                     mlpet.BrainWaterKernel.simulateDcv(this.inputFunction,  this.a, d_(idx), this.p, this.q0, this.t0, this.times));
            end
            title(sprintf('a->%g, d->var, p->%g, q0->%g, t0->%g',            this.a,          this.p, this.q0, this.t0));
            legend(cellfun(@(x) sprintf('d = %g', x), num2cell(d_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('arbitrary');
 		end 
 		function test_plotPs(this)
            figure
            hold on            
            p_ = [0.5 0.75 0.9 1 1.1 1.5 2 3];
            for idx = 1:length(p_)
                plot(this.times, ...
                     mlpet.BrainWaterKernel.simulateDcv(this.inputFunction,  this.a, this.d, p_(idx), this.q0, this.t0, this.times));
            end
            title(sprintf('a->%g, d->%g, p->var, q0->%g, t0->%g',            this.a, this.d,          this.q0, this.t0));
            legend(cellfun(@(x) sprintf('p = %g', x), num2cell(p_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('arbitrary');
 		end 
        function test_simulateMcmc(this)
            this.testObj = mlpet.BrainWaterKernel.simulateMcmc(this.inputFunction, this.a, this.d, this.p, this.q0, this.t0, this.times);
            this.assertEqual(this.testObj.bestFitParams, this.expectedBestFitParams, 'RelTol', 0.05);
            brainWaterKernel = this.testObj; %#ok<NASGU>
            save(fullfile(this.testFolder, 'brainWaterKernel.mat'), 'brainWaterKernel');
        end
 	end 

 	methods (TestClassSetup) 
 		function setupBrainWaterKernel(this) 
            import mlpet.*;
            this.testDcv = BrainWaterKernel.simulateDcv(this.inputFunction, this.a, this.d, this.p, this.q0, this.t0, this.times);
 			this.testObj = BrainWaterKernel(this.wbDsc.concInterpolants, this.testDcv, this.dcv.timeInterpolants);
 		end 
 	end 

 	methods (TestClassTeardown) 
 	end 

 	methods 
 		function this = Test_BrainWaterKernel
            this = this@matlab.unittest.TestCase;
            this = this.buildDcv;
            this = this.buildDsc;
 		end 
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        dcv
        wbDsc
    end
    
    methods (Access = 'private')
        function this = buildDcv(this)
            this.dcv = mlpet.DCV(this.dcvFilename);
        end
        function this = buildDsc(this)            
            import mlfourd.*;
            this.wbDsc = mlperfusion.WholeBrainDSC( ...
                       this.dscFilename, ...
                       this.maskFilename, ...
                       this.dcv.timeInterpolants);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

