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
        function prods = trainPET
            diary(sprintf('AutoradiographyTrainer.trainPET_%s.log', datestr(now, 30)));
            import mlpet.*;
            this = AutoradiographyTrainer;            
            
            pwd0 = this.WORK_DIR;
            for c = 3:3 % length(this.MM_CASES)
                cd(fullfile(pwd0, this.casePaths{c}));  
                this.director_ = ...
                    AutoradiographyDirector.loadPET( ...
                        this.maskFn, this.aifFn, this.ecatFn, this.DCV_SHIFTS(c));
                tmp = this.director_.product;
                tmp.f = this.VIDEEN_FLOWS(c);
                tmp.t0 = this.PET_T0S(c);
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product; 
            end
            cd(pwd0);
            
            save(sprintf('AutoradiographyTrainer.trainPET.prods_%s.mat', datestr(now,30)), 'prods');
            diary off
        end
        function prods = trainPETHersc
            import mlpet.*;
            this = AutoradiographyTrainer;            
            
            pwd0 = this.WORK_DIR;
            cd(pwd0);
            diary(sprintf('AutoradiographyTrainer.trainPETHersc_%s.log', datestr(now, 30)));
            for c = 3:3 % length(this.MM_CASES)
                cd(fullfile(pwd0, this.casePaths{c}));                
                this.director_ = ...
                    AutoradiographyDirector.loadPETHersc( ...
                        this.maskFn, this.aifFn, this.ecatFn, this.DCV_SHIFTS(c));
                tmp = this.director_.product;
                tmp.f = this.VIDEEN_FLOWS(c);
                tmp.t0 = this.PET_T0S(c);
                this.director_.product = tmp;                
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product;
            end
            cd(pwd0);
            
            save(sprintf('AutoradiographyTrainer.trainPETHersc.prods_%s.mat', datestr(now,30)), 'prods');
            diary off
        end
        function prods = trainDSC
            import mlpet.*;
            this = AutoradiographyTrainer;
            
            pwd0 = this.WORK_DIR;
            cd(pwd0);            
            diary(sprintf('AutoradiographyTrainer.trainDSC_%s.log', datestr(now, 30)));
            for c = 3:3 % 1:length(this.MM_CASES)
                cd(fullfile(pwd0, this.casePaths{c})); 
                fprintf('AutoradiographyTrainer.trainDSC is working in %s\n', pwd);
                this.director_ = ...
                    AutoradiographyDirector.loadDSC( ...
                        this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn);
                tmp = this.director_.product;
                tmp.f = this.VIDEEN_FLOWS(c);
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product;
            end
            cd(pwd0);
            
            save(sprintf('AutoradiographyTrainer.trainDSC.prods_%s.mat', datestr(now,30)), 'prods');
            diary off
        end
        function prods  = trainDSCHersc
            import mlpet.*;
            this = AutoradiographyTrainer;              
            
            pwd0 = this.WORK_DIR;
            cd(pwd0);
            diary(sprintf('AutoradiographyTrainer.trainDSCHersc_%s.log', datestr(now, 30)));
            for c = 1:length(this.MM_CASES)
                cd(fullfile(pwd0, this.casePaths{c}));  
                fprintf('AutoradiographyTrainer.trainDSCHersc is working in %s\n', pwd);               
                this.director_ = ...
                    AutoradiographyDirector.loadDSCHersc( ...
                        this.maskFn, this.dscMaskFn, this.dscFn, this.ecatFn);
                tmp = this.director_.product;
                tmp.f = this.VIDEEN_FLOWS(c);
                this.director_.product = tmp;
                this.director_ = this.director_.estimateAll;
                prods{c} = this.director_.product;
            end
            cd(pwd0);
            
            save(sprintf('AutoradiographyTrainer.trainDSCHersc.prods_%s.mat', datestr(now,30)), 'prods');
            diary off
        end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

