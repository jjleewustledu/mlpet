classdef AutoradiographyTester < mlpet.AbstractAutoradiographyClient  
	%% AUTORADIOGRAPHYTESTER   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$  	 

    properties (Constant)
        LOG_PATH = '/Volumes/SeagateBP3/cvl/np755'
        dcvShifts = [-17 -24 -16 -17 -20 -28 -24 -11 -21 -22 -19 -16 -16 -25 -15 -26]
        mttObsOverA0s = [ ...
            2.76928121788615 2.76932294479159 2.76529928862592 3.03109031406097 3.04421743172775 ...
            2.44433313726932 2.5092943982541  2.58918304683156 2.40705030816187 2.68834208892262 ...
            2.790703409822   2.94548103082625 2.78869975518403 2.45541132228493 ...
            2.69826649121803 2.61119371727749]
    end
    
    properties (Dependent)
        subjectsDir
        moyamoyaCases
    end
    
    methods %% GET/SET
        function sd = get.subjectsDir(this)
            sd = this.subjectsDir_;
        end
        function sd = get.moyamoyaCases(this)
            sd = this.moyamoyaCases_;
        end
    end
    
	methods (Static) 	
        function prods = prepareLaif2(varargin)
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:}); 
            
            import mlperfusion.* mlpet.*;
            this = AutoradiographyTester(AutoradiographyTester.LOG_PATH); 
            
            pwd0 = pwd;
            cd(this.subjectsDir);
            logFn = fullfile(this.subjectsDir, sprintf('AutoradiographyTester.prepareLaif2_%s.log', datestr(now, 30)));
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.subjectsDir, this.casePaths{c})); 
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTester.prepareLaif2 is working in %s\n', pwd);                             
                this.director_ = ...
                    LaifDirector.loadLaif2(this.dscFn, this.dscMaskFn);
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product;
                laif2    = this.director_.product; %#ok<NASGU>
                save('LaifTrainer.trainLaif2.laif2.mat', 'laif2');
            end
            cd(this.subjectsDir);
            save(sprintf('AutoradiographyTester.prepareLaif2.prods_%s.mat', datestr(now,30)), 'prods');            
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end	
        function preparePET(varargin)
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});            
            
            import mlperfusion.* mlpet.*;
            pwd0 = pwd;
            this = AutoradiographyTester(AutoradiographyTester.LOG_PATH); 
            
            cd(this.subjectsDir);
            logFn = fullfile(this.subjectsDir, sprintf('AutoradiographyTester.preparePET_%s.log', datestr(now, 30)));
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.subjectsDir, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainPET is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadPET( ...
                        this.maskFn, this.aifFn, this.ecatFn, this.dcvShifts(c));
                tmp = this.director_.product;
                tmp.f = AutoradiographyDirector.getVideenCbf*1.05/6000;
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product;  %#ok<NASGU>
            end            
            cd(this.subjectsDir);            
            save(sprintf('AutoradiographyTester.preparePET.prods_%s.mat', datestr(now,30)), 'prods');
            db = AutoradiographyDB.loadPET(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end  
        function preparePETHersc(varargin)
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});            
            
            import mlperfusion.* mlpet.*;
            pwd0 = pwd;
            this = AutoradiographyTester(AutoradiographyTester.LOG_PATH); 
            
            cd(this.subjectsDir);
            logFn = fullfile(this.subjectsDir, sprintf('AutoradiographyTester.preparePETHersc_%s.log', datestr(now, 30)));
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.subjectsDir, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainPETHersc is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadPETHersc( ...
                        this.maskFn, this.aifFn, this.ecatFn, this.dcvShifts(c));
                tmp = this.director_.product;
                tmp.f = AutoradiographyDirector.getVideenCbf*1.05/6000;
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product;  %#ok<NASGU>
            end            
            cd(this.subjectsDir);            
            save(sprintf('AutoradiographyTester.preparePETHersc.prods_%s.mat', datestr(now,30)), 'prods');
            db = AutoradiographyDB.loadPETHersc(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end  
        function prepareDSC(varargin)
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});            
            
            import mlperfusion.* mlpet.*;
            pwd0 = pwd;
            this = AutoradiographyTester(AutoradiographyTester.LOG_PATH); 
            
            cd(this.subjectsDir);
            logFn = fullfile(this.subjectsDir, sprintf('AutoradiographyTester.prepareDSC_%s.log', datestr(now, 30)));
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.subjectsDir, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.prepareDSC is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadDSC( ...
                        this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn, this.dcvShifts(c));
                tmp = this.director_.product;
                tmp.mttObsOverA0 = this.mttObsOverA0s(c);
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product;  %#ok<NASGU>
            end            
            cd(this.subjectsDir);            
            save(sprintf('AutoradiographyTester.prepareDSC.prods_%s.mat', datestr(now,30)), 'prods');
            db = AutoradiographyDB.loadDSCTest(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end  
        function prepareDSCHersc(varargin)
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});            
            
            import mlperfusion.* mlpet.*;
            pwd0 = pwd;
            this = AutoradiographyTester(AutoradiographyTester.LOG_PATH); 
            
            cd(this.subjectsDir);
            logFn = fullfile(this.subjectsDir, sprintf('AutoradiographyTester.prepareDSCHersc_%s.log', datestr(now, 30)));
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.subjectsDir, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.prepareDSCHersc is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadDSCHersc( ...
                        this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn, this.dcvShifts(c));
                tmp = this.director_.product;
                tmp.mttObsOverA0 = this.mttObsOverA0s(c);
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product;  %#ok<NASGU>
            end            
            cd(this.subjectsDir);            
            save(sprintf('AutoradiographyTester.prepareDSCHersc.prods_%s.mat', datestr(now,30)), 'prods');
            db = AutoradiographyDB.loadDSCHerscTest(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end       
    end 
    
    methods 
        function this = AutoradiographyTester(pth)
            this.subjectsDir_ = pth;
            cd(pth);
            dt = mlsystem.DirTools('mm0*');
            assert(dt.length > 0);
            this.moyamoyaCases_ = dt.dns;
        end
    end
    
    properties (Access = 'private')
        subjectsDir_
        moyamoyaCases_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

