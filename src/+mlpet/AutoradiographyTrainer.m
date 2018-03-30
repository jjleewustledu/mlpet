classdef AutoradiographyTrainer < mlpet.AbstractAutoradiographyTrainer 
	%% AUTORADIOGRAPHYTRAINER   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
    
	methods	(Static)
        function prod  = trainVideen(dcvSh, ecatSh)
            diary(sprintf('AutoradiographyTrainer.trainVideen_%s.log', datestr(now, 30)));
            import mlpet.*;
            this = AutoradiographyTrainer;
            this.dcvShift_ = dcvSh;
            this.ecatShift_ = ecatSh;
            
            [cbf,aflow,bflow] = AutoradiographyDirector.getVideenCbf;
            this.director_ = ...
                AutoradiographyDirector.loadVideen( ...
                    this.maskFn, this.aifFn, this.ecatFn, this.dcvShift, this.ecatShift);
            prod = this.product;    
            prod.f = cbf/6000/1.05;
            prod.af = aflow;
            prod.bf = bflow;
            this.director_.product = prod;
            this.director_ = this.director_.estimateAll;   
            prod = this.director_.product; 
            save('AutoradiographyTrainer.trainVideen.prod.mat', 'prod');
            diary off
        end
        function trainCRVDCVAutoradiography(varargin)
            import mlpet.*;
            this = AutoradiographyTrainer;     
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @isdir);
            parse(p, varargin{:});         
            
            pwd0 = pwd;
            cd(this.logPath);
            logFn = fullfile(this.logPath, sprintf('AutoradiographyTrainer.trainCRVDCVAutoradiography_%s.log', datestr(now, 30)));
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.logPath, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainCRVDCVAutoradiography is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadCRVDCVAutoradiography( ...
                        this.maskFn, this.aifFn, this.ecatFn, this.DCV_SHIFTS(c), this.ECAT_SHIFTS(c));    
                tmp = this.director_.product;
                tmp.f = this.VIDEEN_FLOWS(c);
                this.director_.product = tmp;              
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product; %#ok<NASGU>
            end
            cd(this.logPath);            
            save(sprintf('AutoradiographyTrainer.trainCRVDCVAutoradiography.prods_%s.mat', datestr(now,30)), 'prods');            
            db = AutoradiographyDB.loadCRVAutoradiography(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end
        function trainDCVByGammas(varargin)
            import mlpet.*;
            this = AutoradiographyTrainer;            
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @isdir);
            parse(p, varargin{:});            
            
            pwd0 = pwd;
            cd(this.logPath);
            logFn = fullfile(this.logPath, sprintf('AutoradiographyTrainer.trainDCVByGammas_%s.log', datestr(now, 30)));
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.logPath, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainDCVByGammas is working in %s\n', pwd);
                dcvG = DCVByGammas.loadDCV(this.dcvFn);
                dcvG = dcvG.estimateAll;
                dcvG.plotProduct;
                prods{c} = dcvG; %#ok<NASGU>
            end            
            cd(this.logPath);            
            save(sprintf('AutoradiographyTrainer.trainDCVByGammas.prods_%s.mat', datestr(now,30)), 'prods');
            db = AutoradiographyDB.loadDCVByGammas(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end
        function trainCRVDeconv(varargin)
            import mlpet.*;
            this = AutoradiographyTrainer;            
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @isdir);
            parse(p, varargin{:});            
            
            pwd0 = pwd;
            cd(this.logPath);
            logFn = fullfile(this.logPath, sprintf('AutoradiographyTrainer.trainCRVDeconv_%s.log', datestr(now, 30)));
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.logPath, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainCRVDeconv is working in %s\n', pwd);
                crvd = ...
                    CRVDeconvolution.loadCRV(this.crvFn);
                crvd = crvd.estimateAll;
                crvd.plotProduct;
                prods{c} = crvd; %#ok<NASGU>
            end            
            cd(this.logPath);            
            save(sprintf('AutoradiographyTrainer.trainCRVDeconv.prods_%s.mat', datestr(now,30)), 'prods');
            db = AutoradiographyDB.loadCRVDeconv(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end
        function trainPET(varargin)
            import mlpet.*;
            this = AutoradiographyTrainer;            
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @isdir);
            parse(p, varargin{:});            
            
            pwd0 = pwd;
            cd(this.logPath);
            logFn = fullfile(this.logPath, sprintf('AutoradiographyTrainer.trainPET_%s.log', datestr(now, 30)));
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.logPath, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainPET is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadPET( ...
                        this.maskFn, this.aifFn, this.ecatFn, this.DCV_SHIFTS(c), this.ECAT_SHIFTS(c));
                tmp = this.director_.product;
                tmp.f = this.VIDEEN_FLOWS(c);
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product;  %#ok<NASGU>
            end            
            cd(this.logPath);            
            save(sprintf('AutoradiographyTrainer.trainPET.prods_%s.mat', datestr(now,30)), 'prods');
            db = AutoradiographyDB.loadPET(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end
        function trainPETHersc(varargin)
            import mlpet.*;
            this = AutoradiographyTrainer;     
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @isdir);
            parse(p, varargin{:});         
            
            pwd0 = pwd;
            cd(this.logPath);
            logFn = fullfile(this.logPath, sprintf('AutoradiographyTrainer.trainPETHersc_%s.log', datestr(now, 30)));
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.logPath, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainPETHersc is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadPETHersc( ...
                        this.maskFn, this.aifFn, this.ecatFn, this.DCV_SHIFTS(c), this.ECAT_SHIFTS(c));
                tmp = this.director_.product;
                tmp.f = this.PET_FLOWS(c);
                this.director_.product = tmp;                
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product; %#ok<NASGU>
            end
            cd(this.logPath);            
            save(sprintf('AutoradiographyTrainer.trainPETHersc.prods_%s.mat', datestr(now,30)), 'prods');            
            db = AutoradiographyDB.loadPETHersc(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end
        function trainDSC(varargin)
            import mlpet.*;
            this = AutoradiographyTrainer;
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @isdir);
            parse(p, varargin{:});            
            
            pwd0 = pwd;
            cd(this.logPath);  
            logFn = fullfile(this.logPath, sprintf('AutoradiographyTrainer.trainDSC_%s.log', datestr(now, 30)));          
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.logPath, this.casePaths{c})); 
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainDSC is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadDSC( ...
                        this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn, this.DCV_SHIFTS(c), this.ECAT_SHIFTS2(c));
                tmp = this.director_.product;
                tmp.f = this.PETHERSC_FLOWS(c);
                tmp.A0 = this.A0(c);
                tmp.Ew = this.Ew(c);
                tmp.a  = this.A(c);
                tmp.d  = this.D(c);
                tmp.p  = this.P(c);
                tmp.t0 = this.T0_DSC(c);
                tmp.q0 = this.Q0_DSC(c);
                tmp.mttObsOverA0 = this.MTT_RATIO(c);
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product; %#ok<NASGU>
            end                        
            cd(this.logPath); 
            save(sprintf('AutoradiographyTrainer.trainDSC.prods_%s.mat', datestr(now,30)), 'prods');
            db = AutoradiographyDB.loadDSC(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end
        function trainDSCHersc(varargin)
            import mlpet.*;
            this = AutoradiographyTrainer;   
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @isdir);
            parse(p, varargin{:});             
            
            pwd0 = pwd;
            cd(this.logPath);
            logFn = fullfile(this.logPath, sprintf('AutoradiographyTrainer.trainDSCHersc_%s.log', datestr(now, 30))); 
            diary(logFn);
            for c = 1:length(this.moyamoyaCases)
                cd(fullfile(this.logPath, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainDSCHersc is working in %s\n', pwd);      
                this.director_ = ...
                    AutoradiographyDirector.loadDSCHersc( ...
                        this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn, this.DCV_SHIFTS(c), this.ECAT_SHIFTS2(c));
                tmp = this.director_.product;
                tmp.f = this.PETHERSC_FLOWS(c);
                tmp.A0 = this.A0(c);
                tmp.PS = this.PS(c);
                tmp.a  = this.A(c);
                tmp.d  = this.D(c);
                tmp.p  = this.P(c);
                tmp.t0 = this.T0_DSCHERSC(c);
                tmp.q0 = this.Q0_DSCHERSC(c);
                tmp.mttObsOverA0 = this.MTT_RATIO(c);
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product; %#ok<NASGU>
            end
            cd(this.logPath);             
            save(sprintf('AutoradiographyTrainer.trainDSCHersc.prods_%s.mat', datestr(now,30)), 'prods');            
            db = AutoradiographyDB.loadDSCHersc(logFn);
            db.getSummaryPlot;
            db.getSummaryPlot2;
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end        
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

