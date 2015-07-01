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
        gluTCases = { ...
            'p7861_JJL'    'p7873_JJL'    'p7879_JJL'    'p7891_JJL'    'p7901_JJL'    'p7926_JJL' ...
            'p7935_JJL'    'p7954_JJL'    'p7956_JJL'    'p7979_JJL'    'p7991_JJL'    'p7996_JJL' ...
            'p8015_JJL'    'p8018_JJL'    'p8024_JJL'    'p8039_JJL'                   'p8047_JJL' };
        gluTShifts = [ ...
            -34 -43 -24 -35 -43 -36    -33 -30 -38 -25 -50 -43    -43 -42 -30 -44  -33; ...
            -38 -30 -19 -22 -38 -23    -25 -31 -30 -21 -45 -25    -33 -24 -26 -25  -18];
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
        function prepareGluT(varargin)
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});            
            
            import mlperfusion.* mlpet.*;
            pwd0 = pwd;
            subjectsPth = '/Volumes/InnominateHD2/Arbelaez/GluT';
            this = AutoradiographyTester(subjectsPth);
            
            cd(subjectsPth);
            logFn = fullfile(subjectsPth, sprintf('AutoradiographyTester.prepareGluT_%s.log', datestr(now, 30)));
            diary(logFn);            
            for c = 1:length(this.gluTCases)
                for si = 2:2
                    try
                        cd(fullfile(subjectsPth, this.gluTCases{c}, 'PET', sprintf('scan%i', si)));  
                        fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                        fprintf('AutoradiographyTester.prepareGluT is working in %s\n', pwd);
                        this.director_ = ...
                            AutoradiographyDirector.loadCRVAutoradiography( ...
                                this.maskFnGluT(si), this.aifFnGluT(si), this.ecatFnGluT(si), this.gluTShifts(si,c));
                        this.director_ = this.director_.estimateAll;
                        prods{c} = this.director_.product;  %#ok<NASGU>
                    catch ME
                        handwarning(ME);
                    end
                end
            end
            cd(subjectsPth);            
            save(sprintf('AutoradiographyTester.prepareGluT.prods_%s.mat', datestr(now,30)), 'prods');
            db = AutoradiographyDB.loadCRVAutoradiographyTest(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTester.saveFigs;
            cd(pwd0);
            diary off
        end
        function fn = maskFnGluT(idx)
            fn = sprintf('aparc_a2009s+aseg_mask_on_%sho%i_sumt.nii.gz', str2pnum(pwd), idx);
        end
        function fn = aifFnGluT(idx)
            fn = sprintf('%sho%i.crv', str2pnum(pwd), idx);
        end
        function fn = ecatFnGluT(idx)
            fn = sprintf('%sho%i_161616fwhh_masked.nii.gz', str2pnum(pwd), idx);
        end
        function prepareCRVAutoradiography(varargin)
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});            
            
            import mlperfusion.* mlpet.*;
            pwd0 = pwd;
            this = AutoradiographyTester(AutoradiographyTester.LOG_PATH); 
            
            cd(this.subjectsDir);
            logFn = fullfile(this.subjectsDir, sprintf('AutoradiographyTester.prepareCRVAutoradiography_%s.log', datestr(now, 30)));
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                try
                    cd(fullfile(this.subjectsDir, this.casePaths{c}));  
                    fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                    fprintf('AutoradiographyTester.prepareCRVAutoradiography is working in %s\n', pwd);
                    this.director_ = ...
                        AutoradiographyDirector.loadCRVAutoradiography( ...
                            this.maskFn, this.aifFn, this.ecatFn, this.dcvShifts(c));
                    this.director_ = this.director_.estimateAll;
                    prods{c} = this.director_.product;  %#ok<NASGU>
                catch ME
                    handwarning(ME);
                end
            end
            cd(this.subjectsDir);            
            save(sprintf('AutoradiographyTester.prepareCRVAutoradiography.prods_%s.mat', datestr(now,30)), 'prods');
            db = AutoradiographyDB.loadCRVAutoradiographyTest(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTester.saveFigs;
            cd(pwd0);
            diary off
        end  
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
            AutoradiographyTester.saveFigs;
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
                fprintf('AutoradiographyTester.trainPET is working in %s\n', pwd);
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
            AutoradiographyTester.saveFigs;
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
                fprintf('AutoradiographyTester.trainPETHersc is working in %s\n', pwd);
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
            AutoradiographyTester.saveFigs;
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
                fprintf('AutoradiographyTester.prepareDSC is working in %s\n', pwd);
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
            AutoradiographyTester.saveFigs;
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
                fprintf('AutoradiographyTester.prepareDSCHersc is working in %s\n', pwd);
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
            AutoradiographyTester.saveFigs;
            cd(pwd0);
            diary off
        end       
    end 
    
    methods 
        function this = AutoradiographyTester(pth)
            this.subjectsDir_ = pth;
            cd(pth);
%             dt = mlsystem.DirTools('mm0*');
%             assert(dt.length > 0);
%             this.moyamoyaCases_ = dt.dns;
        end
    end
    
    properties (Access = 'private')
        subjectsDir_
        moyamoyaCases_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

