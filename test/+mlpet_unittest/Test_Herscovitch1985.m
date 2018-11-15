classdef Test_Herscovitch1985 < matlab.unittest.TestCase
	%% TEST_HERSCOVITCH1985 

	%  Usage:  >> results = run(mlpet_unittest.Test_Herscovitch1985)
 	%          >> result  = run(mlpet_unittest.Test_Herscovitch1985, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 28-Jan-2017 12:53:41
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlpet/test/+mlpet_unittest.
 	%% It was developed on Matlab 9.1.0.441655 (R2016b) for MACI64.
 	

	properties
        % from '/Volumes/SeagateBP4/cvl/np755/mm01-007_p7267_2008jun16/bayesian_pet'
        % whole-brain CBF = 56.417 mL/100g/min on vidi, 40% uthresh
        %                 = 0.00987298 1/s        
        %              af = 2.035279E-06 from metcalc
        %              bf = 2.096733E-02 
        % estimated    A0 = 0.290615
        
        a1 = 1.9819e-06
        a2 = 0.021906
        b1 = -0.415287610631909
        b2 = 281.397582270965
        b3 = -33.2866801445654
        b4 = 15880.6096474159
        aifShiftHO  = -18
        scannerShiftHO = -6
        aifShiftOO  = -20
        scannerShiftOO = -10
        fracHOMetab = 0.42
        ooFracTime  = 115
        ooPeakTime  = 19 - 10
        sessionData      
        
        aif
        scanner
        mask
 		testObj
 	end

	methods (Test)
        function test_ctor(this)
            this = this.configTracer('HO');
            this.verifyClass(this.aif, 'mlpet.BloodSucker');
            this.verifyClass(this.scanner, 'mlpet.EcatExactHRPlus');
            this.verifyClass(this.testObj, 'mlpet.Herscovitch1985');
        end
        function test_plotAif(this)
            this = this.configTracer('OO');
            this.testObj.plotAif;
            if (strcmp(this.sessionData.tracer, 'OO'))
                this.testObj.plotAifHOMetab;
                this.testObj.plotAifOO;
            end
        end
        function test_plotScanner(this)
            this = this.configTracer('OO');
            this.testObj.plotScanner;
        end
        
        function test_buildA1A2(this)
            this = this.configTracer('HO');
            obj = this.testObj.buildA1A2;
            this.verifyEqual(obj.product(1), this.a1, 'RelTol', 0.01);
            this.verifyEqual(obj.product(2), this.a2, 'RelTol', 0.01);
        end
        function test_buildB1B2(this)
            this = this.configTracer('OO');
            obj = this.testObj;
            obj = obj.buildB1B2;
            this.verifyEqual(obj.product(1), this.b1, 'RelTol', 0.01);
            this.verifyEqual(obj.product(2), this.b2, 'RelTol', 0.01);
        end
        function test_buildB3B4(this)
            this = this.configTracer('OO');
            obj = this.testObj;
            obj = obj.buildB3B4;
            this.verifyEqual(obj.product(1), this.b3, 'RelTol', 0.01);
            this.verifyEqual(obj.product(2), this.b4, 'RelTol', 0.01);
        end
        
        function test_buildCbfWholebrain(this)
            this = this.configTracer('HO');
            obj = this.testObj;
            obj.a1 = this.a1;
            obj.a2 = this.a2;
            obj = obj.buildCbfWholebrain;
            this.verifyEqual(obj.product, 54.6647121712165, 'RelTol', 0.0001);
        end
        function test_buildCbvWholebrain(this)
            this = this.configTracer('OC');
            obj = this.testObj.buildCbvWholebrain;            
            this.verifyEqual(obj.product, 2.174532514791524, 'RelTol', 0.0001);
        end
        function test_buildOefWholebrain(this)
            this = this.configTracer('OO');
            obj = this.testObj;            
            obj.b1 = this.b1;
            obj.b2 = this.b2;
            obj.b3 = this.b3;
            obj.b4 = this.b4;
            obj.cbf = obj.sessionData.cbf('typ','mlpet.PETImagingContext');
            obj.cbv = obj.sessionData.cbv('typ','mlpet.PETImagingContext');
            obj = obj.buildOefWholebrain;
            this.verifyEqual(obj.product, nan, 'RelTol', 0.0001);
        end
        
        function test_buildCbfMap(this)
            this = this.configTracer('HO');
            obj    = this.testObj;
            obj.a1 = this.a1;
            obj.a2 = this.a2;
            obj    = obj.buildCbfMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            %obj.product.saveas(this.sessionData.cbf('typ','fqfn'));
        end
        function test_buildCbvMap(this)
            this = this.configTracer('OC');
            obj  = this.testObj.buildCbvMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            %obj.product.saveas(this.sessionData.cbv('typ','fqfn'));
        end
        function test_buildOefMap(this)
            this = this.configTracer('OO');
            obj = this.testObj;
            obj.b1 = this.b1;
            obj.b2 = this.b2;
            obj.b3 = this.b3;
            obj.b4 = this.b4;
            obj.cbf = obj.sessionData.cbf('typ','mlpet.PETImagingContext');
            obj.cbv = obj.sessionData.cbv('typ','mlpet.PETImagingContext');
            obj = obj.buildOefMap;
            this.verifyTrue(isa(obj.product, 'mlpet.PETImagingContext'));
            obj.product.view;
            %obj.product.saveas(this.sessionData.oef('typ','fqfn'));
        end
	end

 	methods (TestClassSetup)
		function setupHerscovitch1985(this)
            studyd = mlderdeyn.StudyDataSingleton.instance;
            sessp = '/data/cvl/np755/mm01-007_p7267_2008jun16';
            this.sessionData = mlderdeyn.SessionData('studyData', studyd, 'sessionPath', sessp, 'tracer', '');
            setenv(upper('Test_Herscovitch1985'), '1');
            this.mask = mlfourd.ImagingContext('/data/cvl/np755/mm01-007_p7267_2008jun16/fsl/bt1_default_mask_on_ho_meanvol_default.nii.gz');
            this.addTeardown(@this.teardownHerscovitch1985);
 		end
	end

 	methods (TestMethodSetup)
		function setupHerscovitch1985Test(this)
 			%this.testObj = this.testObj_;
 			%this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		%testObj_
 	end

	methods (Access = private)
        function this = configTracer(this, tr)
            import mlpet.* mlfourd.*;
            switch (tr)
                case 'HO'
                    pic = this.sessionData.ho('typ', 'mlpet.PETImagingContext');
                    this.sessionData.tracer = 'HO';
                    this.scanner = mlpet.EcatExactHRPlus(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'scannerTimeShift', this.scannerShiftHO, ...
                        'dt', 1);                    
                    this.aif = BloodSucker('scannerData', this.scanner, 'aifTimeShift', this.aifShiftHO, 'sessionData', this.sessionData);
                case 'OO'
                    pic = this.sessionData.oo('typ', 'mlpet.PETImagingContext');
                    this.sessionData.tracer = 'OO';
                    this.scanner = mlpet.EcatExactHRPlus(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'scannerTimeShift', this.scannerShiftOO, ...
                        'dt', 1);                    
                    this.aif = BloodSucker('scannerData', this.scanner, 'aifTimeShift', this.aifShiftOO, 'sessionData', this.sessionData);
                case 'OC'
                    pic = this.sessionData.oc('typ', 'mlpet.PETImagingContext');
                    this.sessionData.tracer = 'OC';
                    this.scanner = mlpet.EcatExactHRPlus(pic.niftid, ...
                        'sessionData', this.sessionData, ...
                        'dt', 1);                    
                    this.aif = BloodSucker('scannerData', this.scanner, 'aifTimeShift', -15, 'sessionData', this.sessionData);
                otherwise
                    error('mlpet:unsupportedSwitchCase', 'Test_Herscovitch1985.configTracer');
            end
            if (strcmp(tr, 'OC'))
                timeDur = 0;
            else
                timeDur = 40;
            end
 			this.testObj = Herscovitch1985( ...
                'sessionData', this.sessionData, ...
                'scanner', this.scanner, ...
                'mask', this.mask, ...
                'aif', this.aif, ...
                'timeWindow', timeDur);
            this.testObj.ooPeakTime  = this.ooPeakTime;
            this.testObj.ooFracTime  = this.ooFracTime;
            this.testObj.fracHOMetab = this.fracHOMetab;
        end
        function teardownHerscovitch1985(this)
            setenv(upper('Test_Herscovitch1985'), '0');
        end
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

