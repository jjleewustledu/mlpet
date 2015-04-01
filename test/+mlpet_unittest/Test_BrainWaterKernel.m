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
        testFolder   = '/Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest'
        dscFilename  = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/perfusion_4dfp/ep2d_default_mcf.nii.gz'
        maskFilename = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/perfusion_4dfp/perfMask.nii.gz'
        dcvFilename  = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/ECAT_EXACT/pet/p7267ho1.dcv'        
 	end 

    properties (Dependent)      
        a
        d
        p
        q0
        t0
        times
        inputFunction
    end
    
    methods %% GET
        function x = get.a(this)
            x = this.testObj.a;
        end
        function x = get.d(this)
            x = this.testObj.d;
        end
        function x = get.p(this)
            x = this.testObj.p;
        end
        function x = get.q0(this)
            x = this.testObj.q0;
        end
        function x = get.t0(this)
            x = this.testObj.t0;
        end
        function t = get.times(this)
            t = this.wbDsc.timeInterpolants;
        end
        function f = get.inputFunction(this)
            f = this.inputFunction_;
        end
    end
    
	methods (Test) 
 		function test_plotAs(this)
            figure
            hold on
            a_ = [1 2 4 8 16 32];
            for idx = 1:length(a_)
                plot(this.times, ...
                     mlpet.BrainWaterKernel.countsDcv(this.inputFunction, a_(idx), this.d, this.p, this.q0, this.t0, this.times));
            end
            title(sprintf('a->var, d->%g, p->%g, q0->%g, t0->%g',                  this.d, this.p, this.q0, this.t0));
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
                     mlpet.BrainWaterKernel.countsDcv(this.inputFunction, this.a, d_(idx), this.p, this.q0, this.t0, this.times));
            end
            title(sprintf('a->%g, d->var, p->%g, q0->%g, t0->%g',         this.a,          this.p, this.q0, this.t0));
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
                     mlpet.BrainWaterKernel.countsDcv(this.inputFunction, this.a, this.d, p_(idx), this.q0, this.t0, this.times));
            end
            title(sprintf('a->%g, d->%g, p->var, q0->%g, t0->%g',         this.a, this.d,          this.q0, this.t0));
            legend(cellfun(@(x) sprintf('p = %g', x), num2cell(p_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('arbitrary');
        end 
 		function test_plotQ0s(this)
            figure
            hold on            
            q0_ = [1 10 100 1000 1e4 1e5 1e6];
            for idx = 1:length(q0_)
                plot(this.times, ...
                     log10(mlpet.BrainWaterKernel.countsDcv(this.inputFunction, this.a, this.d, this.p, q0_(idx), this.t0, this.times)));
            end
            title(sprintf('a->%g, d->%g, p->%g, q0->var, t0->%g',               this.a, this.d, this.p,           this.t0));
            legend(cellfun(@(x) sprintf('q0 = %g', x), num2cell(q0_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('log_10(well-counts)');
        end 
        
        function test_simulateMcmc(this)  
            import mlpet.*;
            this.testObj = BrainWaterKernel(this.inputFunction);
            aMap = containers.Map;
            tf = this.times(end);
            aMap('a')   = struct('fixed', 0, 'min',   2,    'mean', this.a,  'max', 16);
            aMap('d')   = struct('fixed', 0, 'min',   0,    'mean', this.d,  'max',  8);
            aMap('p')   = struct('fixed', 0, 'min',   0.5,  'mean', this.p,  'max',  1.5); 
            aMap('q0')  = struct('fixed', 1, 'min',   1/tf, 'mean', this.q0, 'max',  2e7);
            aMap('t0')  = struct('fixed', 1, 'min',   0,    'mean', this.t0, 'max', tf/2); 
            
            o = BrainWaterKernel.simulateMcmc(this.inputFunction, this.a, this.d, this.p, this.q0, this.t0, this.times, aMap);
            this.assertEqual(o.bestFitParams, o.expectedBestFitParams, 'RelTol', 0.05);
        end        
        function test_laif2dcv(this)
            this.testObj = mlpet.BrainWaterKernel.runKernel(this.inputFunction, this.dcv.timeInterpolants, this.dcv.countInterpolants);
            o = this.testObj;            
            
            % \Pi \equiv \frac{wellcnts/mL/sec}{EcatCounts/pixel-mL/min}
            % wellcnts/mL = \Pi \frac{EcatCounts}{pixel-mL} \frac{sec}{min}
            % cf. man pie
            
            wellFactor = 11.3141;
            pie = 5.5;
            brightestEcatCounts = 9348.23; % EcatCounts/voxel
            voxelVol = 0.200331*0.200331*0.2425; % mL
            suckerRate = 5; % mL/min
            suckerTau = 2; % min
            
            P = pie * brightestEcatCounts / voxelVol; % wellcnts*sec/mL from ECAT, bright voxel            
            W = wellFactor * sum(this.dcv.countInterpolants) * (1/suckerRate/suckerTau ); % wellcnts*sec/mL blood-sucker
            fprintf('N.B.:  P ~ %g, W ~ %g\n', P, W);
            
            figure;
            scale = P *suckerRate * suckerTau / (wellFactor * sum(this.laif2.itsKConcentration));
            plot(this.laif2.times, scale * this.laif2.itsKConcentration, ...
                 o.times,          scale * o.itsKernel, ...
                 o.times,          scale * o.estimateData, ...
                 this.dcv.times,   this.dcv.counts, 'o');
            legend('laif2.itsKConcentration', 'Bayesian kernel', 'Bayesian DCV', 'DCV');
            title('Test_BrainWaterKernel.test_laif2dcv');
            xlabel('time/s');
            ylabel(sprintf('laif2, kernel scaled by %g', scale));
            
            this.assertEqual(o.bestFitParams, o.expectedBestFitParams, 'RelTol', 0.05);
        end
 	end 

 	methods (TestClassSetup) 
 		function setupBrainWaterKernel(this) 
            import mlpet.*;
 			this.testObj = BrainWaterKernel(this.inputFunction, this.dcv.timeInterpolants, this.dcv.countInterpolants);
            this.testDcv = BrainWaterKernel.countsDcv(this.inputFunction, this.a, this.d, this.p, this.q0, this.t0, this.times);
 		end 
 	end 

 	methods (TestClassTeardown) 
 	end 

 	methods 
 		function this = Test_BrainWaterKernel
            this = this@matlab.unittest.TestCase;
            this = this.buildDcv;
            this = this.buildDsc;
            this = this.buildLaif2;
            this.inputFunction_ = pchip(this.laif2.times, this.laif2.itsKConcentration, this.dcv.times);
 		end 
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        dcv
        wbDsc
        laif2
        inputFunction_
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
        function this = buildLaif2(this)
            matfile = fullfile(this.testFolder, 'buildLaif2.laif2_.mat');
            if (~lexist(matfile))
                laif2_ = mlperfusion.Laif2.runLaif(this.wbDsc.times, this.wbDsc.itsMagnetization); 
                save(matfile, 'laif2_');
                this.laif2 = laif2_;
                return
            end
            load(matfile);
            this.laif2 = laif2_;  %#ok<NODEF>
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

