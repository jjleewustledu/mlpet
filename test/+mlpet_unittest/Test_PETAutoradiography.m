classdef Test_PETAutoradiography < matlab.unittest.TestCase 
	%% TEST_PETAUTORADIOGRAPHY  

	%  Usage:  >> results = run(mlpet_unittest.Test_PETAutoradiography)
 	%          >> result  = run(mlpet_unittest.Test_PETAutoradiography, 'test_dt')
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
        dcvFilename  = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/ECAT_EXACT/pet/p7267ho1.dcv'
        ecatFilename = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/bayesian_pet/p7267ho1_mcf_revf1to7_masked.nii.gz'
        maskFilename = '/Volumes/InnominateHD2/Local/test/np755/mm01-007_p7267_2008jun16/bayesian_pet/aparc_a2009s+aseg_mask_on_p7267tr1.nii.gz'
        test_plots   = false
        test_mcmc    = true
        DCV_SHIFT    = 13
        DCECAT_SHIFT = 2
        A_FLOW       = 5/60 % cc/sec
    end 
    
    properties (Dependent)
        A0
        PS
        f
        t0
        times
        concentration_a
        concentration_obs
    end
    
    methods %% GET
        function x = get.A0(this)
            x = this.testObj.A0;
        end
        function x = get.PS(this)
            x = this.testObj.PS;
        end
        function x = get.f(this)
            x = this.testObj.f;
        end
        function x = get.t0(this)
            x = this.testObj.t0;
        end
        function t = get.times(this)
            t = this.times_;
        end
        function t = get.concentration_a(this)
            t = this.concentration_a_;
        end
        function t = get.concentration_obs(this)
            t = this.concentration_obs_;
        end
    end

	methods (Test) 
        
        %% TESTS WITH PLOTTING
        
 		function test_plotA0s(this)
            if (~this.test_plots); return; end
            figure
            hold on
            A0_ = [500 600 700 800 900 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000];
            for idx = 1:length(A0_)
                semilogy(this.times, ...
                     mlpet.PETAutoradiography.concentration_obs( ...
                         A0_(idx), this.PS, this.f, this.t0, this.times, this.concentration_a));
            end
            title(sprintf('A0 VAR, PS%g, f %g, t0 %g', this.PS, this.f, this.t0));
            legend(cellfun(@(x) sprintf('A0 = %g', x), num2cell(A0_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('concentration_obs/well-counts');
        end 
 		function test_plotPSs(this)
            if (~this.test_plots); return; end
            figure
            hold on
            PS_ = [0.01 0.02 0.03 0.04 0.05];
            for idx = 1:length(PS_)
                semilogy(this.times, ...
                     mlpet.PETAutoradiography.concentration_obs( ...
                         this.A0, PS_(idx), this.f, this.t0, this.times, this.concentration_a));
            end
            title(sprintf('A0 %g, PS VAR, f %g, t0 %g', this.A0, this.f, this.t0));
            legend(cellfun(@(x) sprintf('PS = %g', x), num2cell(PS_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('concentration_obs/well-counts');
        end 
 		function test_plotFs(this)
            if (~this.test_plots); return; end
            figure
            hold on
            f_ = [0.002 0.004 0.005 0.006 0.007 0.008 0.009 0.01 0.015 0.02];
            for idx = 1:length(f_)
                semilogy(this.times, ...
                     mlpet.PETAutoradiography.concentration_obs( ...
                         this.A0, this.PS, f_(idx), this.t0, this.times, this.concentration_a));
            end
            title(sprintf('A0 %g, PS %g, f VAR, t0 %g', this.A0, this.PS, this.t0));
            legend(cellfun(@(x) sprintf('f = %g', x), num2cell(f_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('concentration_obs/well-counts');
        end
 		function test_plotT0s(this)
            if (~this.test_plots); return; end
            figure
            hold on
            t0_ = [0 1 2 4 8 16 32];
            for idx = 1:length(t0_)
                plot(this.times, ...
                     mlpet.PETAutoradiography.concentration_obs( ...
                         this.A0, this.PS, this.f, t0_(idx), this.times, this.concentration_a));
            end
            title(sprintf('A0 %g, PS %g, f %g, t0 VAR', this.A0, this.PS, this.f));
            legend(cellfun(@(x) sprintf('t0 = %g', x), num2cell(t0_), 'UniformOutput', false));
            xlabel('time/s');
            ylabel('concentration_obs/well-counts');
        end 
        
        %% MCMC TESTS
        
        function test_simulateMcmc(this)
            %% TEST_SIMULATEMCMC constructs for mlperfusion.Laif0 a parameter map, the corresponding test-case magnetization, 
            %  then runs Laif0's MCMC to fit the test-case magnetization.  This is a test of Laif0's ability to fit 
            %  a synthetic magnetization created directly from it's own magnetization model.   
            
            if (~this.test_mcmc); return; end
            import mlpet.*;
            aMap = containers.Map;
            fL = 0.5; fH = 2;
            aMap('A0') = struct('fixed', 0, 'min', fL*this.A0, 'mean', this.A0, 'max', fH*this.A0);
            aMap('PS') = struct('fixed', 0, 'min', fL*this.PS, 'mean', this.PS, 'max', fH*this.PS);
            aMap('f')  = struct('fixed', 0, 'min', fL*this.f,  'mean', this.f,  'max', fH*this.f);
            aMap('t0') = struct('fixed', 0, 'min', fL*this.t0, 'mean', this.t0, 'max', fH*this.t0);
            
            o = PETAutoradiography.simulateMcmc(this.A0, this.PS, this.f, this.t0, this.times, this.concentration_a, aMap);
            this.assertEqual(o.bestFitParams(1:end-1), o.expectedBestFitParams(1:end-1), 'RelTol', 0.1);
        end
        function test_runAutoradiography(this)
            %% TEST_RUNAUTORADIOGRAPHY invokes runAutoradiography on experimental data from this.dscFilenme; best-fit parameters
            %  must match expected values to relative tolerance of 0.1.
            
            if (~this.test_mcmc); return; end
            this.testObj = mlpet.PETAutoradiography.runAutoradiography(this.concentration_a, this.times, this.concentration_obs);
            o = this.testObj;
            
            figure;
            plot(o.independentData, o.estimateData, this.times, this.concentration_obs, 'o');
            legend('Bayesian estimate', 'simulated data');
            title(sprintf('test_runAutoradiography:  A0 %g, PS %g, f %g, t0 %g', o.A0, o.PS, o.f, o.t0), 'Interpreter', 'none');
            xlabel('time/s');
            ylabel('concentration_obs/well-counts');
            
            this.assertEqual(o.bestFitParams(1:end-1), o.expectedBestFitParams(1:end-1), 'RelTol', 0.1);
        end
        function test_initial(this) %#ok<MANU>
        end
 	end 

 	methods (TestClassSetup) 
 		function setupPETAutoradiography(~) 
 		end 
 	end 

 	methods (TestClassTeardown) 
    end 
    
    methods 
        function this = Test_PETAutoradiography
            this = this@matlab.unittest.TestCase; 
            import mlpet.* mlfourd.*;
            this.dcv = UncorrectedDCV(this.dcvFilename);
            this.mask = NIfTId.load(this.maskFilename);
            this.ecat = EcatExactHRPlus.load(this.ecatFilename);         
            this = this.interpolateData;
            
            semilogy(this.times, this.concentration_a, ...
                     this.times, this.concentration_obs);
            title('Test_PETAutoradiography:  p7267 uc-dcv, ecat', 'Interpreter', 'none');
            legend('uc-dcv', 'ecat');
            xlabel('time/s');
            ylabel('concentration/well-counts');
            this.testObj = PETAutoradiography(this.concentration_a, this.times, this.concentration_obs);
        end
    end

    %% PRIVATE
    
    properties (Access = 'private')
        dcv
        mask
        ecat
        
        times_
        concentration_a_
        concentration_obs_
    end
    
    methods (Access = 'private')
        function this = interpolateData(this)           
            
            this.ecat = this.ecat.masked(this.mask);
            this.ecat = this.ecat.volumeSummed;              
            import mlpet.*;
            [t_a,c_a] = AutoradiographyBuilder.shiftDataLeft(this.dcv.times,  this.dcv.wellCounts,                    this.DCV_SHIFT);
            [t_i,c_i] = AutoradiographyBuilder.shiftDataLeft(this.ecat.times, this.ecat.wellCounts/this.ecat.nPixels, this.DCECAT_SHIFT);            
            c_a = c_a - min(c_a);
            c_i = c_i - min(c_i);
            
            this.times_ = min(t_a(1), t_i(1)):this.dt:max(t_a(end), t_i(end));
            this.concentration_a_ = pchip(t_a, c_a, this.times_);
            this.concentration_obs_ = pchip(t_i, c_i, this.times_);
        end
        function t = dt(this)
            t = min(min(this.dcv.taus), min(this.ecat.taus));
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

