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
        test_plots = true
        test_mcmc  = true 
        
        dcvShift  = 18
        dscShift  = 18
 	end 

    properties (Dependent)    
        testFolder
        dscFilename
        maskFilename
        dcvFilename
        
        a
        d
        p
        q0
        t0
        times
        inputFunction0
        inputFunction2
    end
    
    methods %% GET
        function f = get.testFolder(this)
            assert(lexist(this.testFolder_, 'dir'));
            f = this.testFolder_;
        end
        function f = get.dscFilename(this)
            f = fullfile(this.testFolder, this.dscFilename_);
            assert(lexist(f, 'file'));
        end
        function f = get.maskFilename(this)
            f = fullfile(this.testFolder, this.maskFilename_);
            assert(lexist(f, 'file'));
        end
        function f = get.dcvFilename(this)
            f = fullfile(this.testFolder, this.dcvFilename_);
            assert(lexist(f, 'file'));
        end
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
        function f = get.inputFunction0(this)
            f = this.inputFunction0_;
        end
        function f = get.inputFunction2(this)
            f = this.inputFunction2_;
        end
    end
    
	methods (Test) 
        %% TEST WITH PLOTTING
        
 		function test_plotAs(this)
            if (~this.test_plots); return; end
            figure
            hold on
            a_ = [1 2 4 8 16 32];
            for idx = 1:length(a_)
                plot(this.times, ...
                     mlpet.BrainWaterKernel.concentration_i(this.inputFunction0, a_(idx), this.d, this.p, this.q0, this.t0, this.times));
            end
            title(sprintf('a->var, d->%g, p->%g, q0->%g, t0->%g',                  this.d, this.p, this.q0, this.t0));
            legend(cellfun(@(x) sprintf('a = %g', x), num2cell(a_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('arbitrary');
 		end 
 		function test_plotDs(this)
            if (~this.test_plots); return; end
            figure
            hold on            
            d_ = [1 2 3 4 5 6 7 8 9];
            for idx = 1:length(d_)
                plot(this.times, ...
                     mlpet.BrainWaterKernel.concentration_i(this.inputFunction0, this.a, d_(idx), this.p, this.q0, this.t0, this.times));
            end
            title(sprintf('a->%g, d->var, p->%g, q0->%g, t0->%g',         this.a,          this.p, this.q0, this.t0));
            legend(cellfun(@(x) sprintf('d = %g', x), num2cell(d_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('arbitrary');
 		end 
 		function test_plotPs(this)
            if (~this.test_plots); return; end
            figure
            hold on            
            p_ = [0.5 0.75 0.9 1 1.1 1.5 2 3];
            for idx = 1:length(p_)
                plot(this.times, ...
                     mlpet.BrainWaterKernel.concentration_i(this.inputFunction0, this.a, this.d, p_(idx), this.q0, this.t0, this.times));
            end
            title(sprintf('a->%g, d->%g, p->var, q0->%g, t0->%g',         this.a, this.d,          this.q0, this.t0));
            legend(cellfun(@(x) sprintf('p = %g', x), num2cell(p_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('arbitrary');
        end 
 		function test_plotQ0s(this)
            if (~this.test_plots); return; end
            figure
            hold on           
            q0_ = [0.125 0.25 0.5 1 2];
            for idx = 1:length(q0_)
                plot(this.times, ...
                     mlpet.BrainWaterKernel.concentration_i(this.inputFunction0, this.a, this.d, this.p, q0_(idx), this.t0, this.times));
            end
            title(sprintf('a->%g, d->%g, p->%g, q0->var, t0->%g',         this.a, this.d, this.p,           this.t0));
            legend(cellfun(@(x) sprintf('q0 = %g', x), num2cell(q0_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('arbitrary');
            plot(this.times(1:length(this.inputFunction0)), this.inputFunction0, 'x');
        end 
        %% TEST MCMC
        
        function test_simulateMcmc(this) 
            %% TEST_SIMULATEMCMC constructs for mlpet.BrainWaterKernel a parameter map, the corresponding test-case kernel, 
            %  then runs BrainWaterKernel's MCMC to fit the test-case kernel.  This is a test of BrainWaterKernel's ability to fit 
            %  a synthetic kernel created directly from it's own kernel model.   
            
            if (~this.test_mcmc); return; end 
            import mlpet.* mlpet_unittest.*;
            this.testObj = BrainWaterKernel(this.inputFunction0, this.dcv.timeInterpolants, this.dcv.countInterpolants);
            
            o = BrainWaterKernel.simulateMcmc( ...
                this.inputFunction0, this.a, this.d, this.p, this.q0, this.t0, this.times, this.testObj.map);
            this.assertEqual(o.bestFitParams, o.expectedBestFitParams, 'RelTol', 0.05);
        end        
        function test_laif2dcv(this)
            %% TEST_LAIF2DCV invokes BrainWaterKernel.runKernel on experimental data from this.dcvFilenme; best-fit parameters
            %  must match expected values to relative tolerance of 0.05.
            
            if (~this.test_mcmc); return; end
            this.testObj = mlpet.BrainWaterKernel.runKernel(this.inputFunction2, this.dcv.timeInterpolants, this.dcv.countInterpolants);
            o = this.testObj;            
            
            % \Pi \equiv \frac{wellcnts/mL/sec}{EcatCounts/pixel-mL/min}
            % wellcnts/mL = \Pi \frac{EcatCounts}{pixel-mL} \frac{sec}{min}
            % cf. man pie
            
            wellFactor = 11.3141;
            pie = 5.2;
            brightestEcatCounts = 9348.23; % EcatCounts/voxel
            voxelVol = 0.200331*0.200331*0.2425; % mL
            suckerRate = 5; % mL/min
            suckerTau = 116/60; % min
            suckerVol = suckerRate*suckerTau;
            
            P = 60 * pie * brightestEcatCounts; % * voxelVol;                % wellcnts*sec from ECAT, bright voxel            
            W = wellFactor * sum(this.dcv.countInterpolants); % * suckerVol; % wellcnts*sec blood-sucker
            fprintf('N.B.:  P ~ %g, W ~ %g\n', P, W); 
            
            figure;
            plot(o.times,        o.estimateData, ...
                 this.dcv.times, this.dcv.counts, 'o');
            legend('Bayes. DCV', 'DCV');
            title('Test_BrainWaterKernel.test_laif2dcv', 'Interpreter', 'none');
            xlabel('time/s');
            ylabel('Bayes. DCV, DCV');
            
            this.assertEqual(o.bestFitParams, o.expectedBestFitParams, 'RelTol', 0.05);
        end
        function test_laif0dcv(this)
            %% TEST_LAIF0DCV invokes BrainWaterKernel.runKernel on experimental data from this.dcvFilenme; best-fit parameters
            %  must match expected values to relative tolerance of 0.05.
            
            if (~this.test_mcmc); return; end
            
            import mlpet.* mlpet_unittest.*;
            this.testObj = BrainWaterKernel.runKernel( ...
                this.inputFunction0, this.dcv.timeInterpolants, this.dcv.countInterpolants);
            o = this.testObj; 
            
            figure;
            plot(o.times, o.estimateData, this.dcv.timeInterpolants, this.dcv.countInterpolants, 'o');
            legend('Bayes. DCV', 'DCV');
            title('Test_BrainWaterKernel.test_laif0dcv', 'Interpreter', 'none');
            xlabel('time/s');
            ylabel('Bayes. DCV, DCV');
            
            this.assertEqual(o.bestFitParams, o.expectedBestFitParams, 'RelTol', 0.05);
        end
 	end 

 	methods (TestClassSetup) 
 		function setupBrainWaterKernel(this) 
            import mlpet.*;
 			this.testObj = BrainWaterKernel(this.inputFunction0, this.dcv.timeInterpolants, this.dcv.countInterpolants);
            this.testDcv = BrainWaterKernel.concentration_i(this.inputFunction0, this.a, this.d, this.p, this.q0, this.t0, this.times);
 		end 
 	end 

 	methods (TestClassTeardown) 
 	end 

 	methods 
 		function this = Test_BrainWaterKernel
            this = this@matlab.unittest.TestCase;
            this = this.buildDcv;
            this = this.buildDsc;
            this = this.buildLaif0;
            this = this.buildLaif2;
            this.inputFunction0_ = pchip(this.laif0.times, this.laif0.itsKAif, this.dcv.times);
            this.inputFunction2_ = pchip(this.laif2.times, this.laif2.itsKAif, this.dcv.times);
 		end 
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        testFolder_   = '/Volumes/SeagateBP3/cvl/np755/mm01-007_p7267_2008jun16/bayesian_pet'
        dscFilename_  = 'ep2d_default_mcf.nii.gz'
        maskFilename_ = 'ep2d_mask.nii.gz'
        dcvFilename_  = 'p7267ho1.dcv'
        
        dcv
        wbDsc
        laif0
        laif2
        inputFunction0_
        inputFunction2_
    end
    
    methods (Access = 'private')
        function this = buildDcv(this)
            this.dcv = mlpet.UncorrectedDCV(this.dcvFilename);
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
        function this = buildLaif0(this)
            matfile = fullfile(this.testFolder, 'buildLaif0.laif0_.mat');
            if (~lexist(matfile))
                laif0_ = mlperfusion.Laif0.runLaif(this.wbDsc.times, this.wbDsc.itsMagnetization); 
                save(matfile, 'laif0_');
                this.laif0 = laif0_;
                return
            end
            load(matfile);
            this.laif0 = laif0_;  %#ok<NODEF>
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

