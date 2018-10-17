classdef Test_Decay < matlab.unittest.TestCase
	%% TEST_DECAY 

	%  Usage:  >> results = run(mlpet_unittest.Test_Decay)
 	%          >> result  = run(mlpet_unittest.Test_Decay, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 14-Oct-2018 19:12:22 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		registry
        verbose = false
 		testObj
    end
    
    properties (Dependent)
        hlife
    end
    
    methods %% GET
        function g = get.hlife(this)
            g = this.testObj.halflife;
        end
    end

	methods (Test)
		function test_afun(this)
 			import mlpet.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
        end
        
        %% isotopes/tracers
        
        function test_tracer11CGlc(this)
            obj = mlpet.Decay('tracer', '1-D-[11C]-glucose');
            this.verifyEqual(obj.tracer, '1-D-[11C]-glucose');
            this.verifyEqual(obj.isotope, '11C');
        end
        function test_tracer18FDG(this)
            obj = mlpet.Decay('tracer', '[18F]-deoxyglucose');
            this.verifyEqual(obj.tracer, '[18F]-deoxyglucose');
            this.verifyEqual(obj.isotope, '18F');
        end
        function test_tracerHO(this)
            obj = mlpet.Decay('tracer', 'ho');
            this.verifyEqual(obj.tracer, 'ho');
            this.verifyEqual(obj.isotope, '15O');
        end
        function test_isotope68Ge(this)
            obj = mlpet.Decay('isotope', '[68Ge]');
            this.verifyEqual(obj.tracer, '');
            this.verifyEqual(obj.isotope, '68Ge');
        end
        function test_isotope22Na(this)
            obj = mlpet.Decay('isotope', '[22Na]');
            this.verifyEqual(obj.tracer, '');
            this.verifyEqual(obj.isotope, '22Na');
        end
        
        %% corrections & adjustments
        
        function test_isdecaying(this)
            this.verifyTrue(this.testObj.isdecaying);
            this.verifyError(@set_isdecaying, 'MATLAB:class:noSetMethod');
            
            function set_isdecaying
                this.testObj.isdecaying = false;
            end
        end
        function test_decayActivities(this)
            obj = mlpet.Decay('isotope', '15O', 'isdecaying', false);
            u = ones(1, 123);
            d = 2.^(-(0:122)/this.hlife);
            
            this.verifyEqual(obj.decayActivities(u, 0:122), d, 'RelTol', sqrt(eps));
            if (this.verbose)
                figure;
                plot(0:122, u, 0:122, d); ylim([0 2]); 
                legend('1', 'decay'); 
                title('Test_Decay.test_decayActivities', 'Interpreter', 'none');
            end                
        end
        function test_decayActivities_twice(this)
            obj = mlpet.Decay('isotope', '15O', 'isdecaying', false);
            u = ones(1, 123);
            d = 2.^(-(0:122)/this.hlife);
            
            this.verifyEqual(obj.decayActivities(obj.decayActivities(u, 0:122), 0:122), d, 'RelTol', sqrt(eps));               
        end
        function test_decayActivities_zerotime(this)            
            obj = mlpet.Decay('isotope', '15O', 'zerotime', this.hlife, 'isdecaying', false);
            u = ones(1, 123);
            d2 = 2.^(-((-this.hlife):(122-this.hlife))/this.hlife);
            
            this.verifyEqual(obj.decayActivities(u, 0:122), d2, 'RelTol', sqrt(eps));
            if (this.verbose)
                figure;
                plot(0:122, u, 0:122, d2); ylim([0 2]); 
                legend('1', sprintf('decay(zerotime = %g)', this.hlife)); 
                title('Test_Decay.test_decayActivities_zerotime', 'Interpreter', 'none');
            end    
        end
        function test_undecayActivities(this)
            obj = mlpet.Decay('isotope', '15O', 'isdecaying', true);
            d = 2.^(-(0:122)/this.hlife);
            u = ones(1, 123);
            
            this.verifyEqual(obj.undecayActivities(d, 0:122), u, 'RelTol', sqrt(eps));
            if (this.verbose)
                figure;
                plot(0:122, d, 0:122, u); ylim([0 2]); 
                legend('decay', '1'); 
                title('Test_Decay.test_undecayActivities', 'Interpreter', 'none');
            end    
        end
        function test_undecayActivities_twice(this)
            obj = mlpet.Decay('isotope', '15O', 'isdecaying', true);
            d = 2.^(-(0:122)/this.hlife);
            u = ones(1, 123);
            
            this.verifyEqual(obj.undecayActivities(obj.undecayActivities(d, 0:122), 0:122), u, 'RelTol', sqrt(eps));   
        end
        function test_undecayActivities_zerotime(this)            
            obj = mlpet.Decay('isotope', '15O', 'zerotime', this.hlife, 'isdecaying', true);
            d = 2.^(-(0:122)/this.hlife);
            u2 = ones(1, 123)/2;
            
            this.verifyEqual(obj.undecayActivities(d, 0:122), u2, 'RelTol', sqrt(eps));
            if (this.verbose)
                figure;
                plot(0:122, d, 0:122, u2); ylim([0 2]); 
                legend('decay', sprintf('0.5 (zerotime = %g)', this.hlife)); 
                title('Test_Decay.test_undecayActivities_zerotime', 'Interpreter', 'none');
            end   
        end
        function test_halflife(this)
            this.verifyEqual(this.testObj.halflife, this.hlife);
        end
        function test_predictDose(this)
            obj = this.testObj;
            hl_ = this.hlife; % [15O] halflife
            
            this.verifyEqual(obj.predictDose(-hl_),  60);
            this.verifyEqual(obj.predictDose(0),     30);
            this.verifyEqual(obj.predictDose(hl_),   15);
            this.verifyEqual(obj.predictDose(2*hl_), 7.5);
        end
        function test_shiftWorldline(this)
            t  = 0:3*round(this.hlife);
            t_ = 0:2*round(this.hlife);
            a  = [zeros(1,round(this.hlife)) 2.^(-t_/this.hlife)];
            [a1,t1] = this.testObj.shiftWorldline(a, t, 'shift', this.hlife);
            [a2,t2] = this.testObj.shiftWorldline(a, t, 'shift', -this.hlife);
            [a3,t3] = this.testObj.shiftWorldline(a, t, 'shift', -2*this.hlife);
            
            this.verifyEqual(a1, a/2);
            this.verifyEqual(t1, t + this.hlife)
            this.verifyEqual(a2, 2*a);
            this.verifyEqual(t2, t - this.hlife)
            this.verifyEqual(a3, 4*a);
            this.verifyEqual(t3, t - 2*this.hlife)
            if (this.verbose)
                figure; hold on
                plot(t,  a);
                plot(t1, a1);
                plot(t2, a2);
                plot(t3, a3);
                legend('activity', ...
                    sprintf('activity1(shift = %g)', this.hlife), ...
                    sprintf('activity2(shift = %g)', -this.hlife), ...
                    sprintf('activity3(shift = %g)', -2*this.hlife));
                title('Test_Decay.test_ShiftWorldline', 'Interpreter', 'none');
                hold off
            end
        end
        function test_shiftWorldline_gauss(this)
            t  = 0:3*round(this.hlife);
            a_ = exp(-(t - this.hlife).^2/(this.hlife/2)^2);
            a  = a_.*2.^(-(t - this.hlife)/this.hlife);
            [a1,t1] = this.testObj.shiftWorldline(a, t, 'shift', this.hlife);
            [a2,t2] = this.testObj.shiftWorldline(a, t, 'shift', -this.hlife);
            [a3,t3] = this.testObj.shiftWorldline(a, t, 'shift', -2*this.hlife);
            
            this.verifyEqual(a1, a/2);
            this.verifyEqual(t1, t + this.hlife)
            this.verifyEqual(a2, 2*a);
            this.verifyEqual(t2, t - this.hlife)
            this.verifyEqual(a3, 4*a);
            this.verifyEqual(t3, t - 2*this.hlife)
            if (this.verbose)
                figure; hold on
                plot(t,  a);
                plot(t1, a1);
                plot(t2, a2);
                plot(t3, a3);
                legend('activity', ...
                    sprintf('activity1(shift = %g)', this.hlife), ...
                    sprintf('activity2(shift = %g)', -this.hlife), ...
                    sprintf('activity3(shift = %g)', -2*this.hlife));
                title('Test_Decay.test_ShiftWorldline', 'Interpreter', 'none');
                hold off
            end
        end
        function test_zerodose(this)
            this.verifyEqual(this.testObj.zerodose, 30);
        end
        function test_zerotime(this)
            obj = this.testObj;
            hl_ = this.hlife; % [15O] halflife
            
            % zerodose changes concommitantly
            obj.zerotime = hl_;
            this.verifyEqual(obj.zerodose,           15);
            this.verifyEqual(obj.predictDose(0),     30); 
            this.verifyEqual(obj.predictDose(hl_),   15);
            this.verifyEqual(obj.predictDose(2*hl_), 7.5);
            this.verifyEqual(obj.zerodatetime, this.zerodatetime_ + seconds(hl_));
            
            obj.zerotime = 0;
            this.verifyEqual(obj.zerodose,           30);
            this.verifyEqual(obj.predictDose(0),     30);  
            this.verifyEqual(obj.predictDose(hl_),   15);
            this.verifyEqual(obj.predictDose(2*hl_), 7.5);
            this.verifyEqual(obj.zerodatetime, this.zerodatetime_);
            
            obj.zerotime = -hl_;
            this.verifyEqual(obj.zerodose,           60);
            this.verifyEqual(obj.predictDose(0),     30);
            this.verifyEqual(obj.predictDose(hl_),   15);
            this.verifyEqual(obj.predictDose(2*hl_), 7.5);  
            this.verifyEqual(obj.zerodatetime, this.zerodatetime_ - seconds(hl_));          
        end
        function test_zerodatetime(this)
            this.verifyEqual(this.testObj.zerodatetime, this.zerodatetime_);
        end
	end

 	methods (TestClassSetup)
		function setupDecay(this)
            this.zerodatetime_ = datetime(datestr(now));
 		end
	end

 	methods (TestMethodSetup)
		function setupDecayTest(this)
 			import mlpet.*;
 			this.testObj = Decay('isotope', '15O', 'zerodose', 30, 'zerotime', 0, 'zerodatetime', this.zerodatetime_);
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
        zerodatetime_
 	end

	methods (Access = private)
		function cleanTestMethod(this) %#ok<MANU>
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

