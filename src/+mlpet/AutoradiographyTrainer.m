classdef AutoradiographyTrainer < mlpet.AbstractTrainer 
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
        function trainPET(varargin)
            import mlpet.*;
            this = AutoradiographyTrainer;            
            
            p = inputParser;
            addOptional(p, 'figFolder', this.WORK_DIR, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});            
            
            pwd0 = pwd;
            cd(this.WORK_DIR);
            diary(sprintf('AutoradiographyTrainer.trainPET_%s.log', datestr(now, 30)));
            for c = 4:4 %1:length(this.MM_CASES)
                cd(fullfile(this.WORK_DIR, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainPET is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadPET( ...
                        this.maskFn, this.aifFn, this.ecatFn, this.DCV_SHIFTS(c), this.ECAT_SHIFTS(c));
                tmp = this.director_.product;
                tmp.f = this.PETAUTO_FLOWS(c);
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product;  %#ok<NASGU>
            end            
            cd(this.WORK_DIR);            
            save(sprintf('AutoradiographyTrainer.trainPET.prods_%s.mat', datestr(now,30)), 'prods');
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end
        function trainPETHersc(varargin)
            import mlpet.*;
            this = AutoradiographyTrainer;     
            
            p = inputParser;
            addOptional(p, 'figFolder', this.WORK_DIR, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});         
            
            pwd0 = pwd;
            cd(this.WORK_DIR);
            diary(sprintf('AutoradiographyTrainer.trainPETHersc_%s.log', datestr(now, 30)));
            for c = 1:length(this.MM_CASES)
                cd(fullfile(this.WORK_DIR, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainPETHersc is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadPETHersc( ...
                        this.maskFn, this.aifFn, this.ecatFn, this.DCV_SHIFTS(c), this.ECAT_SHIFTS(c));
                tmp = this.director_.product;
                tmp.f = this.PETAUTO_FLOWS(c);
                this.director_.product = tmp;                
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product; %#ok<NASGU>
            end
            cd(this.WORK_DIR);            
            save(sprintf('AutoradiographyTrainer.trainPETHersc.prods_%s.mat', datestr(now,30)), 'prods');            
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end
        function trainDSC(varargin)
            import mlpet.*;
            this = AutoradiographyTrainer;
            
            p = inputParser;
            addOptional(p, 'figFolder', this.WORK_DIR, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});            
            
            pwd0 = pwd;
            cd(this.WORK_DIR);            
            diary(sprintf('AutoradiographyTrainer.trainDSC_%s.log', datestr(now, 30)));
            for c = 4:4 % 1:length(this.MM_CASES)
                cd(fullfile(this.WORK_DIR, this.casePaths{c})); 
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainDSC is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadDSC( ...
                        this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn);
                tmp = this.director_.product;
                tmp.f = this.PETAUTO_FLOWS(c);
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product; %#ok<NASGU>
            end                        
            cd(this.WORK_DIR); 
            save(sprintf('AutoradiographyTrainer.trainDSC.prods_%s.mat', datestr(now,30)), 'prods');
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end
        function trainDSCHersc(varargin)
            import mlpet.*;
            this = AutoradiographyTrainer;   
            
            p = inputParser;
            addOptional(p, 'figFolder', this.WORK_DIR, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});             
            
            pwd0 = pwd;
            cd(this.WORK_DIR);
            diary(sprintf('AutoradiographyTrainer.trainDSCHersc_%s.log', datestr(now, 30)));
            for c = 1:length(this.MM_CASES)
                cd(fullfile(this.WORK_DIR, this.casePaths{c}));  
                fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                fprintf('AutoradiographyTrainer.trainDSCHersc is working in %s\n', pwd);      
                this.director_ = ...
                    AutoradiographyDirector.loadDSCHersc( ...
                        this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn, 0, this.ECAT_SHIFTS(c));
                tmp = this.director_.product;
                tmp.f = this.PETAUTO_FLOWS(c);
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product; %#ok<NASGU>
            end
            cd(this.WORK_DIR);             
            save(sprintf('AutoradiographyTrainer.trainDSCHersc.prods_%s.mat', datestr(now,30)), 'prods');            
            cd(p.Results.figFolder);
            AutoradiographyTrainer.saveFigs;
            cd(pwd0);
            diary off
        end        
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

